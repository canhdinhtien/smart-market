const express = require('express');
const controller = require('../controllers/recipe.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

/**
 * @openapi
 * tags:
 *   name: Recipes
 *   description: Recipe management
 */

/**
 * @openapi
 * /recipes:
 *   post:
 *     summary: Create a new recipe
 *     tags: [Recipes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - foodId
 *               - instructions
 *             properties:
 *               foodId:
 *                 type: string
 *               instructions:
 *                 type: string
 *               ingredients:
 *                 type: array
 *                 items:
 *                   type: object
 *     responses:
 *       201:
 *         description: Recipe created successfully
 *       400:
 *         description: Invalid input
 */
router.post('/', controller.createRecipe);

/**
 * @openapi
 * /recipes:
 *   put:
 *     summary: Update a recipe
 *     tags: [Recipes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - id
 *             properties:
 *               id:
 *                 type: string
 *               instructions:
 *                 type: string
 *               ingredients:
 *                 type: array
 *                 items:
 *                   type: object
 *     responses:
 *       200:
 *         description: Recipe updated successfully
 *       404:
 *         description: Recipe not found
 */
router.put('/', controller.updateRecipe);

/**
 * @openapi
 * /recipes:
 *   delete:
 *     summary: Delete a recipe
 *     tags: [Recipes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - id
 *             properties:
 *               id:
 *                 type: string
 *     responses:
 *       200:
 *         description: Recipe deleted successfully
 *       404:
 *         description: Recipe not found
 */
router.delete('/', controller.deleteRecipe);

/**
 * @openapi
 * /recipes:
 *   get:
 *     summary: Get recipes by food ID
 *     tags: [Recipes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: foodId
 *         required: true
 *         schema:
 *           type: string
 *         description: Food ID to get recipes for
 *     responses:
 *       200:
 *         description: List of recipes for the food
 *       404:
 *         description: No recipes found
 */
router.get('/', controller.getRecipesByFoodId);

module.exports = router;
