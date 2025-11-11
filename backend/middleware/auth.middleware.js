const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

dotenv.config();

async function verifyUser(req, res, next) {
    const token = req.cookies.accessToken;
    if (!token) return res.status(401).json({ message: 'Access Denied' });
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findByPk(decoded.id);
        if (!user) return res.status(404).json({ message: 'User not found' });
        req.user = { id: user._id, email: user.email };
        next();
    } catch (error) {
        return res.status(403).json({ message: 'Invalid or Expired Token' });
    }
};

module.exports = {
    verifyUser
}