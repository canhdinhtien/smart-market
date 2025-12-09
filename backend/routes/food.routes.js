const express = require('express');
const controller = require('../controllers/food.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const upload = require('../middleware/upload.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.get('/', controller.getAllFoodsInGroup);
router.get('/unit', controller.getUnits);
router.get('/category', controller.getCategories);
router.get('/:id', controller.getFoodById);
router.post('/', upload.single('image'), controller.createFood);
router.put('/:id', upload.single('image'), controller.updateFood);
router.delete('/:id', controller.deleteFood);

module.exports = router;
