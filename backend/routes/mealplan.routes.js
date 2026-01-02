const express = require('express');
const controller = require('../controllers/mealplan.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

/**
 * @openapi
 * tags:
 *   name: MealPlans
 *   description: Meal planning management
 */

/**
 * @openapi
 * /meals:
 *   post:
 *     summary: Create a new meal plan
 *     tags: [MealPlans]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - date
 *               - meals
 *             properties:
 *               date:
 *                 type: string
 *                 format: date
 *               meals:
 *                 type: array
 *                 items:
 *                   type: object
 *     responses:
 *       201:
 *         description: Meal plan created successfully
 *       400:
 *         description: Invalid input
 */
router.post('/', controller.createMealPlan);

/**
 * @openapi
 * /meals/{id}:
 *   delete:
 *     summary: Delete a meal plan
 *     tags: [MealPlans]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Meal plan ID
 *     responses:
 *       200:
 *         description: Meal plan deleted successfully
 *       404:
 *         description: Meal plan not found
 */
router.delete('/:id', controller.deletePlan);

/**
 * @openapi
 * /meals/{id}:
 *   put:
 *     summary: Update a meal plan
 *     tags: [MealPlans]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Meal plan ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               date:
 *                 type: string
 *                 format: date
 *               meals:
 *                 type: array
 *                 items:
 *                   type: object
 *     responses:
 *       200:
 *         description: Meal plan updated successfully
 *       404:
 *         description: Meal plan not found
 */
router.put('/:id', controller.updateMealPlan);

/**
 * @openapi
 * /meals/{groupId}:
 *   get:
 *     summary: Get meal plan by date for a group
 *     tags: [MealPlans]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: End date
 *     responses:
 *       200:
 *         description: Meal plan for the specified date range
 *       404:
 *         description: No meal plan found
 */
router.get('/:groupId', controller.getMealPlanByDate);

module.exports = router;
