const express = require('express');
const controller = require('../controllers/fridge.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.post('/', controller.createFridgeItem);
router.put('/', controller.updateFridgeItem);
router.delete('/', controller.deleteFridgeItem);
router.get('/', controller.getAllFridgeItems);
router.get('/:foodName', controller.getSpecificFridgeItem);

module.exports = router;
