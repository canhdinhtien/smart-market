const dotenv = require('dotenv');
const Jwt = require('../utils/jwtUtils');
const User = require('../models/User');
const { getContext } = require('../utils/context');

dotenv.config();

async function verifyUser(req, res, next) {
    const token = req.cookies.accessToken;
    if (!token) return res.status(401).json({ message: 'Access Denied' });
    try {
        const decoded = Jwt.verifyAccessToken(token);
        const user = await User.findByPk(decoded.id);
        if (!user) return res.status(404).json({ message: 'User not found' });
        if (!user.is_verified) return res.status(403).json({ message: 'User is not verified' });
        req.user = { id: user.id, email: user.email, is_admin: user.is_admin };
        const store = getContext();
        if (store) {
            store.user = req.user;
        }
        next();
    } catch (error) {
        return res.status(403).json({ message: 'Invalid or Expired Token' });
    }
};

function verifyAdmin(req, res, next) {
    if (!req.user || !req.user.is_admin) {
        return res.status(403).json({ message: 'Access Denied: Admins only' });
    }
    next();
}

module.exports = {
    verifyUser,
    verifyAdmin
}