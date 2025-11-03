const express = require('express');
const controller = require('../controllers/recipe.controller.js');

const router = express.Router();

router.post('/', controller.createRecipe);
router.put('/', controller.updateRecipe);
router.delete('/', controller.deleteRecipe);
router.get('/', controller.getRecipesByFoodId);

module.exports = router;
