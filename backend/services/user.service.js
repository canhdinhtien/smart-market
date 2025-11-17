const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { nanoid } = require('nanoid');
const { Op } = require('sequelize');
const User = require('../models/User');
const Jwt = require('../utils/jwtUtils');
const redisClient = require('../config/redis');
const { generateVerificationCode } = require('../utils/codeUtils');
const { sendVerificationEmail } = require('../utils/emailUtils');

// TODO refactor

dotenv.config();
const saltRounds = 10;

const registerUser = async ({ email, password, name }) => {
  const existingUser = await User.findOne({ where: { email } });
  if (existingUser) throw new Error('User already exists');

  const hashedPassword = await bcrypt.hash(password, saltRounds);
  const user = await User.create({
    email,
    password_hash: hashedPassword,
    name,
    username: nanoid(10),
  });
  return user;
};

const loginUser = async ({ identifier, password }) => {
  const user = await User.findOne({
    where: {
      [Op.or]: [{ email: identifier }, { username: identifier }],
    },
  });
  if (!user) throw new Error('User not found!');

  const isMatch = await bcrypt.compare(password, user.password_hash);
  if (!isMatch) throw new Error('Invalid credentials!');

  const accessToken = Jwt.generateAccessToken(user.id);
  const refreshToken = Jwt.generateRefreshToken(user.id);

  return { user, accessToken, refreshToken };
};

const refreshToken = async (refreshToken) => {
  const decoded = Jwt.verifyRefreshToken(refreshToken);
  const accessToken = Jwt.generateAccessToken(decoded.id);
  return accessToken;
};

const sendVerificationCode = async (email) => {
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
};

const getUser = async (userId) => {
  const user = await User.findByPk(userId, {
    attributes: { exclude: ['password_hash'] },
  });

  if (!user) throw new Error('User not found');

  return user;
};

const deleteUser = async (userId) => {
  const user = await User.findByPk(userId);

  if (!user) throw new Error('User not found');

  await user.destroy();
  return { message: 'User deleted successfully' };
};

const verifyEmail = async () => {
  
};

const changeUserPassword = async (userId, oldPassword, newPassword) => {
  const user = await User.findByPk(userId);

  if (!user) throw new Error('User not found');

  if (user.checkPassword(oldPassword)) {
    user.updatePassword(newPassword);
  } else {
    throw new Error("Invalid password");
  }
};

const editUser = async () => {
  // Implementation for editUser
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
  editUser,
};