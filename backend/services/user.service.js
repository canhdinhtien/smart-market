const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const { Op } = require('sequelize');
const User = require('../models/User');
const Jwt = require('../utils/jwtUtils');
const redisClient = require('../config/redis');
const { generateVerificationCode } = require('../utils/codeUtils');
const { sendVerificationEmail } = require('../utils/emailUtils');
const { deleteImage } = require('../utils/imageUtils');

dotenv.config();
const saltRounds = 10;

const registerUser = async ({ email, password, name, gender }) => {
  try {
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) throw new Error('User already exists');

    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const user = await User.create({
      email,
      password_hash: hashedPassword,
      name,
      gender,
    });

    const userJson = user.toJSON();
    delete userJson.password_hash;

    const accessToken = Jwt.generateAccessToken(user.id);
    const refreshToken = Jwt.generateRefreshToken(user.id);

    let verifyToken = null;
    try {
      const result = await sendVerificationCode(user.email);
      verifyToken = result.verificationToken;
    } catch (emailError) {
      console.error('Failed to send verification email:', emailError);
    }

    return { userJson, accessToken, refreshToken, verifyToken };
  } catch (err) {
    throw new Error(err.message || 'Failed to register user');
  }
};

const loginUser = async ({ identifier, password }) => {
  try {
    const user = await User.findOne({
      where: {
        [Op.or]: [{ email: identifier }],
      },
    });
    if (!user) throw new Error('User not found!');

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) throw new Error('Invalid credentials!');

    if (!user.is_verified) {
      throw new Error('User is not verified!');
    }

    const accessToken = Jwt.generateAccessToken(user.id);
    const refreshToken = Jwt.generateRefreshToken(user.id);

    const userJson = user.toJSON();
    delete userJson.password_hash;

    return { user: userJson, accessToken, refreshToken };
  } catch (err) {
    throw new Error(err.message || 'Failed to login');
  }
};

const refreshToken = async (refreshToken) => {
  try {
    const decoded = Jwt.verifyRefreshToken(refreshToken);
    const accessToken = Jwt.generateAccessToken(decoded.id);
    return accessToken;
  } catch (err) {
    throw new Error(err.message || 'Failed to refresh token');
  }
};

const sendVerificationCode = async (email) => {
  try {
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser && existingUser.is_verified) {
      const error = new Error('This email is already associated with a verified account.');
      error.statusCode = 409;
      throw error;
    }

    const code = generateVerificationCode();
    await redisClient.set(email, code, {
      EX: 15 * 60, // 15 minutes
    });

    sendVerificationEmail(code, email);

    const verificationToken = Jwt.generateEmailVerificationToken(email);

    return {
      message: 'Verification code sent successfully.',
      verificationToken,
    };
  } catch (err) {
    throw new Error(err.message || 'Failed to send verification code');
  }
};

const getUser = async (userId) => {
  try {
    const user = await User.findByPk(userId, {
      attributes: { exclude: ['password_hash'] },
    });

    if (!user) throw new Error('User not found');

    const userJson = user.toJSON();
    delete userJson.password_hash;

    return userJson;
  } catch (err) {
    throw new Error(err.message || 'Failed to get user');
  }
};

const deleteUser = async (userId) => {
  try {
    const user = await User.findByPk(userId);

    if (!user) throw new Error('User not found');

    const imageUrl = user.image_url;

    await user.destroy();

    // Delete profile picture if exists AND user was successfully deleted
    if (imageUrl) {
      await deleteImage(imageUrl);
    }

    return { message: 'User deleted successfully' };
  } catch (err) {
    throw new Error(err.message || 'Failed to delete user');
  }
};

const verifyEmail = async (code, token) => {
  try {
    const decoded = Jwt.verifyEmailVerificationToken(token);
    const email = decoded.email;

    if (!email) throw new Error('Invalid token');

    const storedCode = await redisClient.get(email);
    if (!storedCode) throw new Error('Verification code expired or not found');

    if (storedCode !== code) throw new Error('Invalid verification code');

    const user = await User.findOne({ where: { email } });
    if (!user) throw new Error('User not found');

    if (user.is_verified) {
      return { message: 'Email is already verified' };
    }

    user.is_verified = true;
    await user.save();
    await redisClient.del(email);

    return { message: 'Email verified successfully' };
  } catch (err) {
    throw new Error(err.message || 'Email verification failed');
  }
};

const changeUserPassword = async (userId, oldPassword, newPassword) => {
  try {
    const user = await User.findByPk(userId);

    if (!user) throw new Error('User not found');

    const isMatch = await bcrypt.compare(oldPassword, user.password_hash);
    if (!isMatch) throw new Error('Invalid password');

    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
    user.password_hash = hashedPassword;
    await user.save();

    return { message: 'Password changed successfully' };
  } catch (err) {
    throw new Error(err.message || 'Failed to change password');
  }
};

const updateUser = async (userId, data) => {
  try {
    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('User not found');
    }

    if (data.email && data.email !== user.email) {
      const emailExists = await User.findOne({ where: { email: data.email } });
      if (emailExists) throw new Error('Email already exists');
    }

    const oldImageUrl = user.image_url;

    const updateFields = {};
    if (data.name) updateFields.name = data.name;
    if (data.gender) updateFields.gender = data.gender;
    if (data.imageUrl) updateFields.image_url = data.imageUrl;

    await user.update(updateFields);

    // If new image is provided and it's different from old one, delete old one
    if (data.imageUrl && oldImageUrl && data.imageUrl !== oldImageUrl) {
      await deleteImage(oldImageUrl);
    }

    const userJson = user.toJSON();
    delete userJson.password_hash;

    return { message: 'User updated successfully', user: userJson };
  } catch (err) {
    throw new Error(err.message || 'Failed to update user');
  }
};

const requestPasswordReset = async (email) => {
  try {
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return { message: 'If an account exists with this email, a reset code has been sent.' };
    }

    const code = generateVerificationCode();
    await redisClient.set(`reset:${email}`, code, {
      EX: 15 * 60, // 15 minutes
    });

    const { sendPasswordResetEmail } = require('../utils/emailUtils');
    await sendPasswordResetEmail(code, email);

    const resetToken = Jwt.generatePasswordResetToken(email);

    // Log password reset request
    const logService = require('./log.service');
    logService.createLog({
      userId: user.id,
      action: 'PASSWORD_RESET_REQUEST',
      details: 'Password reset code sent to email',
      entity: 'User',
      entityId: user.id
    });

    return {
      message: 'If an account exists with this email, a reset code has been sent.',
      resetToken,
    };
  } catch (err) {
    throw new Error(err.message || 'Failed to request password reset');
  }
};

const resetPassword = async (code, token, newPassword) => {
  try {
    const decoded = Jwt.verifyPasswordResetToken(token);
    const email = decoded.email;

    if (!email) throw new Error('Invalid token');

    const storedCode = await redisClient.get(`reset:${email}`);
    if (!storedCode) throw new Error('Reset code expired or not found');

    if (storedCode !== code) throw new Error('Invalid reset code');

    const user = await User.findOne({ where: { email } });
    if (!user) throw new Error('User not found');

    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
    user.password_hash = hashedPassword;
    await user.save();

    await redisClient.del(`reset:${email}`);

    // Log successful password reset
    const logService = require('./log.service');
    logService.createLog({
      userId: user.id,
      action: 'PASSWORD_RESET_SUCCESS',
      details: 'Password was reset successfully',
      entity: 'User',
      entityId: user.id
    });

    return { message: 'Password reset successfully' };
  } catch (err) {
    throw new Error(err.message || 'Password reset failed');
  }
};

module.exports = {
  registerUser,
  loginUser,
  refreshToken,
  sendVerificationCode,
  getUser,
  deleteUser,
  verifyEmail,
  changeUserPassword,
  updateUser,
  requestPasswordReset,
  resetPassword,
};
