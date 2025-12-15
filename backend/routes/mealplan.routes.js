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
 * /mealplans:
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
 * /mealplans:
 *   delete:
 *     summary: Delete a meal plan
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
 *             properties:
 *               date:
 *                 type: string
 *                 format: date
 *     responses:
 *       200:
 *         description: Meal plan deleted successfully
 *       404:
 *         description: Meal plan not found
 */
router.delete('/', controller.deletePlan);

/**
 * @openapi
 * /mealplans:
 *   put:
 *     summary: Update a meal plan
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
router.put('/', controller.updateMealPlan);

/**
 * @openapi
 * /mealplans:
 *   get:
 *     summary: Get meal plan by date
 *     tags: [MealPlans]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: date
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *         description: Date to get meal plan for
 *     responses:
 *       200:
 *         description: Meal plan for the specified date
 *       404:
 *         description: No meal plan found for this date
 */
router.get('/', controller.getMealPlanByDate);

module.exports = router;
