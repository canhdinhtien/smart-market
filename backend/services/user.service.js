const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { nanoid } = require('nanoid');
const { Op } = require('sequelize');
const User = require('../models/User');
const Jwt = require('../utils/jwt');

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
  const decoded = Jwt.verifyToken(refreshToken);
  const accessToken = Jwt.generateAccessToken(decoded.id);
  return accessToken;
};

const sendVerificationCode = async () => {
  // Implementation for sendVerificationCode
};

const getUser = async () => {
  // Implementation for getUser
};

const deleteUser = async () => {
  // Implementation for deleteUser
};

const verifyEmail = async () => {
  // Implementation for verifyEmail
};

const changeUserPassword = async () => {
  // Implementation for changeUserPassword
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
