const express = require('express');
const controller = require('../controllers/fridge.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.get('/', controller.getAllFridgeItems);
router.get('/:id', controller.getFridgeItemById);
router.post('/', controller.createFridgeItem);
router.put('/:id', controller.updateFridgeItem);
router.delete('/:id', controller.deleteFridgeItem);

module.exports = router;
