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
const notificationRoutes = require('./notification.routes');

const router = express.Router();

router.use('/users', userRoutes);
router.use('/groups', groupRoutes);
router.use('/categories', categoryRoutes);
router.use('/units', unitRoutes);
router.use('/logs', logRoutes);
router.use('/food', foodRoutes);
router.use('/fridge', fridgeRoutes);
router.use('/shopping', shoppinglistRoutes);
router.use('/meals', mealplanRoutes);
router.use('/recipes', recipeRoutes);
router.use('/recipes', recipeRoutes);
router.use('/notifications', notificationRoutes);
router.use('/consumptions', require('./consumption.routes'));

module.exports = router;