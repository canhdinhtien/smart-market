const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');

dotenv.config();

function generateAccessToken(id) {
    return jwt.sign({ id }, process.env.JWT_ACCESS_SECRET, { expiresIn: process.env.ACCESS_TOKEN_EXPIRES_IN || '15m' });
}

function generateRefreshToken(id) {
    return jwt.sign({ id }, process.env.JWT_REFRESH_SECRET, { expiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN || '7d' });
}

function generateEmailVerificationToken(email) {
    return jwt.sign({ email }, process.env.JWT_EMAIL_SECRET, { expiresIn: '15m' });
}

const verifyToken = (token, secret) => {
    return jwt.verify(token, secret);
};

const verifyAccessToken = (token) => {
    return verifyToken(token, process.env.JWT_ACCESS_SECRET);
}

const verifyRefreshToken = (token) => {
    return verifyToken(token, process.env.JWT_REFRESH_SECRET);
}

const verifyEmailVerificationToken = (token) => {
    return verifyToken(token, process.env.JWT_EMAIL_SECRET);
}

function generatePasswordResetToken(email) {
    return jwt.sign({ email, purpose: 'password_reset' }, process.env.JWT_EMAIL_SECRET, { expiresIn: '15m' });
}

const verifyPasswordResetToken = (token) => {
    const decoded = verifyToken(token, process.env.JWT_EMAIL_SECRET);
    if (decoded.purpose !== 'password_reset') {
        throw new Error('Invalid token purpose');
    }
    return decoded;
}

module.exports = {
    generateAccessToken,
    generateRefreshToken,
    generateEmailVerificationToken,
    generatePasswordResetToken,
    verifyAccessToken,
    verifyRefreshToken,
    verifyEmailVerificationToken,
    verifyPasswordResetToken
};
