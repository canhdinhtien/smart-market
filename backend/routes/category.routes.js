const express = require('express');
const controller = require('../controllers/category.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.post('/', controller.createCategory);
router.get('/', controller.getAllCategories);
router.put('/', controller.editCategoryByName);
router.delete('/', controller.deleteCategoryByName);

module.exports = router;
