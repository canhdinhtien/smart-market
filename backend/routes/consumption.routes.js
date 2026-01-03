const express = require('express');
const router = express.Router();
const consumptionController = require('../controllers/consumption.controller');
const { verifyUser } = require('../middleware/auth.middleware');

router.use(verifyUser);

/**
 * @openapi
 * tags:
 *   name: Consumption
 *   description: Consumption statistics
 */

/**
 * @openapi
 * /consumption/my-stats:
 *   get:
 *     summary: Get self consumption stats
 *     tags: [Consumption]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of consumed items grouped by name and unit
 *       401:
 *         description: Unauthorized
 */
router.get('/my-stats', consumptionController.getMyStats);

/**
 * @openapi
 * /consumption/group/{groupId}/stats:
 *   get:
 *     summary: Get group consumption stats
 *     tags: [Consumption]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *     responses:
 *       200:
 *         description: List of consumed items for the group
 *       403:
 *         description: Access denied (Not a member)
 *       404:
 *         description: Group not found
 */
router.get('/group/:groupId/stats', consumptionController.getGroupStats);

/**
 * @openapi
 * /consumption/stats:
 *   get:
 *     summary: Get all consumption stats (Admin only)
 *     tags: [Consumption]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Global consumption stats
 *       403:
 *         description: Access denied (Admin only)
 */
router.get('/stats', consumptionController.getAllStats);

module.exports = router;
