const express = require('express');
const controller = require('../controllers/log.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.get('/', controller.getLogs);

module.exports = router;
