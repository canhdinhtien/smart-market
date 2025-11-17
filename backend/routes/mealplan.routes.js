const express = require('express');
const controller = require('../controllers/mealplan.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.post('/', controller.createMealPlan);
router.delete('/', controller.deletePlan);
router.put('/', controller.updateMealPlan);
router.get('/', controller.getMealPlanByDate);

module.exports = router;
