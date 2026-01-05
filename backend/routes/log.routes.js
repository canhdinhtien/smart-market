const express = require('express');
const controller = require('../controllers/log.controller.js');
const { verifyUser, verifyAdmin } = require('../middleware/auth.middleware.js');

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
 *         description: Activity logs
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Items per page
 *     responses:
 *       200:
 *         description: List of activity logs
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 logs:
 *                   type: array
 *                   items:
 *                     type: object
 *                 total:
 *                   type: integer
 *                 page:
 *                   type: integer
 *                 totalPages:
 *                   type: integer
 *       401:
 *         description: Unauthorized
 */
router.get('/', verifyAdmin, controller.getLogs);

module.exports = router;
