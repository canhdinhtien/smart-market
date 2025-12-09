const express = require('express');
const controller = require('../controllers/user.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');
const upload = require('../middleware/upload.middleware.js');

const router = express.Router();

router.post('/', controller.registerUser);
router.post('/login', controller.loginUser);
router.post('/logout', controller.logoutUser);
router.post('/refresh-token', verifyUser, controller.refreshToken);
router.post('/send-verification-code', controller.sendVerificationCode);
router.get('/', verifyUser, controller.getUser);
router.delete('/', verifyUser, controller.deleteUser);
router.post('/verify-email', controller.verifyEmail);
router.post('/change-password', verifyUser, controller.changeUserPassword);
router.put('/', verifyUser, upload.single('profile_pic'), controller.editUser);

module.exports = router;