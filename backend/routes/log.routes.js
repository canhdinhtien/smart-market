const express = require('express');
const controller = require('../controllers/log.controller.js');

const router = express.Router();

router.get('/', controller.getLogs);

module.exports = router;
