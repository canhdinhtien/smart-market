const express = require('express');
const userRoutes = require('./user.routes');
const groupRoutes = require('./group.routes');
const categoryRoutes = require('./category.routes');
const unitRoutes = require('./unit.routes');
const logRoutes = require('./log.routes');
const foodRoutes = require('./food.routes');
const fridgeRoutes = require('./fridge.routes');
const shoppinglistRoutes = require('./shoppinglist.routes');
const mealplanRoutes = require('./mealplan.routes');
const recipeRoutes = require('./recipe.routes');

const router = express.Router();

router.use('/user', userRoutes);
router.use('/user/group', groupRoutes);
router.use('/admin/category', categoryRoutes);
router.use('/admin/unit', unitRoutes);
router.use('/logs', logRoutes);
router.use('/food', foodRoutes);
router.use('/fridge', fridgeRoutes);
router.use('/shopping', shoppinglistRoutes);
router.use('/meal', mealplanRoutes);
router.use('/recipe', recipeRoutes);

module.exports = router;