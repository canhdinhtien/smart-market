const express = require('express');
const controller = require('../controllers/mealplan.controller.js');

const router = express.Router();

router.post('/', controller.createMealPlan);
router.delete('/', controller.deletePlan);
router.put('/', controller.updateMealPlan);
router.get('/', controller.getMealPlanByDate);

module.exports = router;
