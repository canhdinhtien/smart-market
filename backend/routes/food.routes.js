const express = require('express');
const controller = require('../controllers/food.controller.js');

const router = express.Router();

router.post('/', controller.createFood);
router.put('/', controller.updateFood);
router.delete('/', controller.deleteFood);
router.get('/', controller.getAllFoodsInGroup);
router.get('/unit', controller.getUnits);
router.get('/category', controller.getCategories);

module.exports = router;
