const express = require('express');
const controller = require('../controllers/fridge.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

/**
 * @openapi
 * tags:
 *   name: Fridge
 *   description: Fridge inventory management
 */

/**
 * @openapi
 * /fridge:
 *   get:
 *     summary: Get all fridge items
 *     tags: [Fridge]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: group_id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID to get fridge items from
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
 *         description: List of fridge items
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 items:
 *                   type: array
 *                   items:
 *                     type: object
 *                 total:
 *                   type: integer
 *                 page:
 *                   type: integer
 *                 totalPages:
 *                   type: integer
 *       400:
 *         description: Group ID is required
 *       401:
 *         description: Unauthorized
 */
router.get('/', controller.getAllFridgeItems);

/**
 * @openapi
 * /fridge/{id}:
 *   get:
 *     summary: Get a fridge item by ID
 *     tags: [Fridge]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Fridge item ID
 *     responses:
 *       200:
 *         description: Fridge item details
 *       404:
 *         description: Item not found
 */
router.get('/:id', controller.getFridgeItemById);

/**
 * @openapi
 * /fridge:
 *   post:
 *     summary: Add a new item to fridge
 *     tags: [Fridge]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - food_id
 *               - group_id
 *             properties:
 *               food_id:
 *                 type: string
 *               group_id:
 *                 type: string
 *               quantity:
 *                 type: number
 *               expiryDate:
 *                 type: string
 *                 format: date
 *     responses:
 *       201:
 *         description: Item added to fridge
 *       400:
 *         description: Invalid input
 */
router.post('/', controller.createFridgeItem);

/**
 * @openapi
 * /fridge/{id}:
 *   put:
 *     summary: Update a fridge item
 *     tags: [Fridge]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Fridge item ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               quantity:
 *                 type: number
 *               expiryDate:
 *                 type: string
 *                 format: date
 *     responses:
 *       200:
 *         description: Fridge item updated
 *       404:
 *         description: Item not found
 */
router.put('/:id', controller.updateFridgeItem);

/**
 * @openapi
 * /fridge/{id}:
 *   delete:
 *     summary: Remove an item from fridge
 *     tags: [Fridge]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Fridge item ID
 *     responses:
 *       200:
 *         description: Item removed from fridge
 *       404:
 *         description: Item not found
 */
router.delete('/:id', controller.deleteFridgeItem);

module.exports = router;
