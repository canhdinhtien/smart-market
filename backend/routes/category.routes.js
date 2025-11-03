const express = require('express');
const controller = require('../controllers/category.controller.js');

const router = express.Router();

router.post('/', controller.createCategory);
router.get('/', controller.getAllCategories);
router.put('/', controller.editCategoryByName);
router.delete('/', controller.deleteCategoryByName);

module.exports = router;
