const express = require('express');
const controller = require('../controllers/food.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const upload = require('../middleware/upload.middleware.js');

const router = express.Router();

router.use(verifyUser);

/**
 * @openapi
 * tags:
 *   name: Foods
 *   description: Food items management
 */

/**
 * @openapi
 * /food:
 *   get:
 *     summary: Get all foods in user's group
 *     tags: [Foods]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: group_id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID to get foods from
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
 *       - in: query
 *         name: name
 *         schema:
 *           type: string
 *         description: Filter by food name
 *       - in: query
 *         name: category_id
 *         schema:
 *           type: integer
 *         description: Filter by category ID
 *     responses:
 *       200:
 *         description: List of foods in the group
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 foods:
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
router.get('/', controller.getAllFoodsInGroup);

/**
 * @openapi
 * /food/{id}:
 *   get:
 *     summary: Get a food item by ID
 *     tags: [Foods]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Food ID
 *     responses:
 *       200:
 *         description: Food item details
 *       404:
 *         description: Food not found
 */
router.get('/:id', controller.getFoodById);

/**
 * @openapi
 * /food:
 *   post:
 *     summary: Create a new food item
 *     tags: [Foods]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - group_id
 *             properties:
 *               name:
 *                 type: string
 *               group_id:
 *                 type: string
 *               category:
 *                 type: string
 *               unit:
 *                 type: string
 *               quantity:
 *                 type: number
 *               image:
 *                 type: string
 *                 format: binary
 *     responses:
 *       201:
 *         description: Food created successfully
 *       400:
 *         description: Invalid input
 */
router.post('/', upload.single('image'), controller.createFood);

/**
 * @openapi
 * /food/{id}:
 *   put:
 *     summary: Update a food item
 *     tags: [Foods]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Food ID
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               category:
 *                 type: string
 *               unit:
 *                 type: string
 *               quantity:
 *                 type: number
 *               image:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: Food updated successfully
 *       404:
 *         description: Food not found
 */
router.put('/:id', upload.single('image'), controller.updateFood);

/**
 * @openapi
 * /food/{id}:
 *   delete:
 *     summary: Delete a food item
 *     tags: [Foods]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Food ID
 *     responses:
 *       200:
 *         description: Food deleted successfully
 *       404:
 *         description: Food not found
 */
router.delete('/:id', controller.deleteFood);

module.exports = router;
