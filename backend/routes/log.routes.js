const express = require('express');
const controller = require('../controllers/log.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

/**
 * @openapi
 * tags:
 *   name: Logs
 *   description: Activity logs
 */

/**
 * @openapi
 * /logs:
 *   get:
 *     summary: Get activity logs
 *     tags: [Logs]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of activity logs
 *       401:
 *         description: Unauthorized
 */
router.get('/', controller.getLogs);

module.exports = router;
