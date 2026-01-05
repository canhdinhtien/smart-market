const express = require('express');
const router = express.Router();
const consumptionController = require('../controllers/consumption.controller');
const { verifyUser, verifyAdmin } = require('../middleware/auth.middleware');

router.use(verifyUser);

/**
 * @openapi
 * tags:
 *   name: Consumption
 *   description: Consumption statistics
 */

/**
 * @openapi
 * /consumptions/my-stats:
 *   get:
 *     summary: Get self consumption stats
 *     tags: [Consumption]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of consumed items grouped by name and unit
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   name:
 *                     type: string
 *                     description: Name of the food item
 *                   unit:
 *                     type: string
 *                     description: Unit of measurement (e.g., kg, liters)
 *                   image_url:
 *                     type: string
 *                     description: URL to the food image
 *                   total_quantity:
 *                     type: number
 *                     description: Total aggregated quantity consumed
 *       401:
 *         description: Unauthorized
 */
router.get('/my-stats', consumptionController.getMyStats);

/**
 * @openapi
 * /consumptions/group/{groupId}/stats:
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
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   name:
 *                     type: string
 *                     description: Name of the food item
 *                   unit:
 *                     type: string
 *                     description: Unit of measurement (e.g., kg, liters)
 *                   image_url:
 *                     type: string
 *                     description: URL to the food image
 *                   total_quantity:
 *                     type: number
 *                     description: Total aggregated quantity consumed
 *       403:
 *         description: Access denied (Not a member)
 *       404:
 *         description: Group not found
 */
router.get('/group/:groupId/stats', consumptionController.getGroupStats);

/**
 * @openapi
 * /consumptions/stats:
 *   get:
 *     summary: Get all consumption stats (Admin only)
 *     tags: [Consumption]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of consumed items grouped by name and unit
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   name:
 *                     type: string
 *                     description: Name of the food item
 *                   unit:
 *                     type: string
 *                     description: Unit of measurement (e.g., kg, liters)
 *                   image_url:
 *                     type: string
 *                     description: URL to the food image
 *                   total_quantity:
 *                     type: number
 *                     description: Total aggregated quantity consumed
 *       403:
 *         description: Access denied (Admin only)
 */
router.get('/stats', verifyAdmin, consumptionController.getAllStats);

module.exports = router;
