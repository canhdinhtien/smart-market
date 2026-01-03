const express = require('express');
const controller = require('../controllers/recipe.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');
const upload = require('../middleware/upload.middleware.js');

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
 *               instructions:
 *                 type: string
 *               description:
 *                 type: string
 *               image:
 *                 type: string
 *                 format: binary
 *               ingredients:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     food_id:
 *                       type: integer
 *                     quantity:
 *                       type: number
 *                     unit_id:
 *                       type: integer
 *     responses:
 *       201:
 *         description: Recipe created successfully
 *       400:
 *         description: Invalid input
 */
router.post('/', upload.single('image'), controller.createRecipe);

/**
 * @openapi
 * /recipes/{id}:
 *   put:
 *     summary: Update a recipe
 *     tags: [Recipes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Recipe ID
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               instructions:
 *                 type: string
 *               image:
 *                 type: string
 *                 format: binary
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
router.put('/:id', upload.single('image'), controller.updateRecipe);

/**
 * @openapi
 * /recipes/{id}:
 *   delete:
 *     summary: Delete a recipe
 *     tags: [Recipes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Recipe ID
 *     responses:
 *       200:
 *         description: Recipe deleted successfully
 *       404:
 *         description: Recipe not found
 */
router.delete('/:id', controller.deleteRecipe);

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
 *         required: false
 *         schema:
 *           type: string
 *         description: Food ID to get recipes for (Required if group_id not provided)
 *       - in: query
 *         name: group_id
 *         required: false
 *         schema:
 *           type: string
 *         description: Group ID to filter recipes (Required if foodId not provided)
 *       - in: query
 *         name: name
 *         schema:
 *           type: string
 *         description: Filter by recipe name
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
 *         description: List of recipes for the food
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 recipes:
 *                   type: array
 *                   items:
 *                     type: object
 *                 total:
 *                   type: integer
 *                 page:
 *                   type: integer
 *                 totalPages:
 *                   type: integer
 *       404:
 *         description: No recipes found
 */
router.get('/', controller.getRecipesByFoodId);

/**
 * @openapi
 * /recipes/recommendations:
 *   get:
 *     summary: Get recipe recommendations based on fridge items
 *     tags: [Recipes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: group_id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID to get recommendations for
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
 *         description: List of recommended recipes sorted by match percentage
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 recommendations:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       matchPercentage:
 *                         type: number
 *                         description: Percentage of matched ingredients
 *                       matchedIngredientsCount:
 *                         type: integer
 *                         description: Number of ingredients available in fridge
 *                       missingIngredientsCount:
 *                         type: integer
 *                       missingIngredients:
 *                         type: array
 *                 total:
 *                   type: integer
 *                 page:
 *                   type: integer
 *                 totalPages:
 *                   type: integer
 *       400:
 *         description: Group ID is required
 *       403:
 *         description: Not a member of the group
 */
router.get('/recommendations', controller.getRecipeRecommendations);

module.exports = router;
