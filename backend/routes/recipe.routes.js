const express = require('express');
const controller = require('../controllers/recipe.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.post('/', controller.createRecipe);
router.put('/', controller.updateRecipe);
router.delete('/', controller.deleteRecipe);
router.get('/', controller.getRecipesByFoodId);

module.exports = router;
