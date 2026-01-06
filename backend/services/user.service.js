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
    if (existingUser) {
      const error = new Error('Người dùng đã tồn tại');
      error.statusCode = 409;
      throw error;
    }

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
    throw new Error(err.message || 'Đăng ký người dùng thất bại');
  }
};

const loginUser = async ({ identifier, password }) => {
  try {
    const user = await User.findOne({
      where: {
        [Op.or]: [{ email: identifier }],
      },
    });
    if (!user) {
      const error = new Error('Không tìm thấy người dùng!');
      error.statusCode = 401; // Avoid enumeration, treat as auth failure
      throw error;
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      const error = new Error('Thông tin đăng nhập không hợp lệ!');
      error.statusCode = 401;
      throw error;
    }

    if (!user.is_verified) {
      const error = new Error('Người dùng chưa được xác minh!');
      error.statusCode = 401;
      throw error;
    }

    const accessToken = Jwt.generateAccessToken(user.id);
    const refreshToken = Jwt.generateRefreshToken(user.id);

    const userJson = user.toJSON();
    delete userJson.password_hash;

    return { user: userJson, accessToken, refreshToken };
  } catch (err) {
    throw new Error(err.message || 'Đăng nhập thất bại');
  }
};

const refreshToken = async (refreshToken) => {
  try {
    const decoded = Jwt.verifyRefreshToken(refreshToken);
    const accessToken = Jwt.generateAccessToken(decoded.id);
    return accessToken;
  } catch (err) {
    const error = new Error(err.message || 'Làm mới token thất bại');
    error.statusCode = 401;
    throw error;
  }
};

const sendVerificationCode = async (email) => {
  try {
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser && existingUser.is_verified) {
      const error = new Error('Email này đã được liên kết với một tài khoản đã xác minh.');
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
      message: 'Đã gửi mã xác minh thành công.',
      verificationToken,
    };
  } catch (err) {
    throw new Error(err.message || 'Gửi mã xác minh thất bại');
  }
};

const getUser = async (userId) => {
  try {
    const user = await User.findByPk(userId, {
      attributes: { exclude: ['password_hash'] },
    });

    if (!user) {
      const error = new Error('Không tìm thấy người dùng');
      error.statusCode = 404;
      throw error;
    }

    const userJson = user.toJSON();
    delete userJson.password_hash;

    return userJson;
  } catch (err) {
    throw new Error(err.message || 'Lấy thông tin người dùng thất bại');
  }
};

const deleteUser = async (userId) => {
  try {
    const user = await User.findByPk(userId);

    if (!user) {
      const error = new Error('Không tìm thấy người dùng');
      error.statusCode = 404;
      throw error;
    }

    const imageUrl = user.image_url;

    await user.destroy();

    // Delete profile picture if exists AND user was successfully deleted
    if (imageUrl) {
      await deleteImage(imageUrl);
    }

    return { message: 'Đã xóa người dùng thành công' };
  } catch (err) {
    throw new Error(err.message || 'Xóa người dùng thất bại');
  }
};

const verifyEmail = async (code, token) => {
  try {
    const decoded = Jwt.verifyEmailVerificationToken(token);
    const email = decoded.email;

    if (!email) {
      const error = new Error('Token không hợp lệ');
      error.statusCode = 400;
      throw error;
    }

    const storedCode = await redisClient.get(email);
    if (!storedCode) {
      const error = new Error('Mã xác minh hết hạn hoặc không tìm thấy');
      error.statusCode = 400;
      throw error;
    }

    if (storedCode !== code) {
      const error = new Error('Mã xác minh không hợp lệ');
      error.statusCode = 400;
      throw error;
    }

    const user = await User.findOne({ where: { email } });
    if (!user) {
      const error = new Error('Không tìm thấy người dùng');
      error.statusCode = 404;
      throw error;
    }

    if (user.is_verified) {
      return { message: 'Email đã được xác minh' };
    }

    user.is_verified = true;
    await user.save();
    await redisClient.del(email);

    return { message: 'Email đã được xác minh thành công' };
  } catch (err) {
    throw new Error(err.message || 'Xác minh email thất bại');
  }
};

const changeUserPassword = async (userId, oldPassword, newPassword) => {
  try {
    const user = await User.findByPk(userId);

    if (!user) {
      const error = new Error('Không tìm thấy người dùng');
      error.statusCode = 404;
      throw error;
    }

    const isMatch = await bcrypt.compare(oldPassword, user.password_hash);
    if (!isMatch) {
      const error = new Error('Mật khẩu không hợp lệ');
      error.statusCode = 401;
      throw error;
    }

    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
    user.password_hash = hashedPassword;
    await user.save();

    return { message: 'Đổi mật khẩu thành công' };
  } catch (err) {
    throw new Error(err.message || 'Đổi mật khẩu thất bại');
  }
};

const updateUser = async (userId, data) => {
  try {
    const user = await User.findByPk(userId);
    if (!user) {
      const error = new Error('Không tìm thấy người dùng');
      error.statusCode = 404;
      throw error;
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

    return { message: 'Cập nhật người dùng thành công', user: userJson };
  } catch (err) {
    throw new Error(err.message || 'Cập nhật người dùng thất bại');
  }
};

const requestPasswordReset = async (email) => {
  try {
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return { message: 'Nếu tài khoản tồn tại với email này, mã đặt lại đã được gửi.' };
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
      message: 'Nếu tài khoản tồn tại với email này, mã đặt lại đã được gửi.',
      resetToken,
    };
  } catch (err) {
    throw new Error(err.message || 'Yêu cầu đặt lại mật khẩu thất bại');
  }
};

const resetPassword = async (code, token, newPassword) => {
  try {
    const decoded = Jwt.verifyPasswordResetToken(token);
    const email = decoded.email;

    if (!email) {
      const error = new Error('Token không hợp lệ');
      error.statusCode = 400;
      throw error;
    }

    const storedCode = await redisClient.get(`reset:${email}`);
    if (!storedCode) {
      const error = new Error('Mã đặt lại đã hết hạn hoặc không tìm thấy');
      error.statusCode = 400;
      throw error;
    }

    if (storedCode !== code) {
      const error = new Error('Mã đặt lại không hợp lệ');
      error.statusCode = 400;
      throw error;
    }

    const user = await User.findOne({ where: { email } });
    if (!user) {
      const error = new Error('Không tìm thấy người dùng');
      error.statusCode = 404;
      throw error;
    }

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

    return { message: 'Đặt lại mật khẩu thành công' };
  } catch (err) {
    throw new Error(err.message || 'Đặt lại mật khẩu thất bại');
  }
};

const searchUsers = async (query, page = 1, limit = 20) => {
  try {
    const offset = (page - 1) * limit;
    const whereClause = {};

    if (query) {
      whereClause[Op.or] = [
        { name: { [Op.iLike]: `%${query}%` } },
        { email: { [Op.iLike]: `%${query}%` } }
      ];
    }

    const { count, rows } = await User.findAndCountAll({
      where: whereClause,
      attributes: ['id', 'name', 'email', 'image_url'],
      limit: limit,
      offset: offset,
      order: [['name', 'ASC']]
    });

    return {
      users: rows,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / limit)
    };
  } catch (err) {
    throw new Error(err.message || 'Tìm kiếm người dùng thất bại');
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
  searchUsers,
};
