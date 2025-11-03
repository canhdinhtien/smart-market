const express = require('express');
const controller = require('../controllers/fridge.controller.js');

const router = express.Router();

router.post('/', controller.createFridgeItem);
router.put('/', controller.updateFridgeItem);
router.delete('/', controller.deleteFridgeItem);
router.get('/', controller.getAllFridgeItems);
router.get('/:foodName', controller.getSpecificFridgeItem);

module.exports = router;
