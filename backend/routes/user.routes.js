const express = require('express');
const controller = require('../controllers/user.controller.js');

const router = express.Router();

router.post('/register', controller.registerUser);
router.post('/login', controller.loginUser);
router.post('/logout', controller.logoutUser);
router.post('/refresh-token', controller.refreshToken);
router.post('/send-verification-code', controller.sendVerificationCode);
router.get('/:userId', controller.getUser);
router.delete('/:userId', controller.deleteUser);
router.post('/verify-email', controller.verifyEmail);
router.post('/change-password', controller.changeUserPassword);
router.put('/:userId', controller.editUser);

module.exports = router;