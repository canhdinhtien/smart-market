const express = require('express');
const controller = require('../controllers/unit.controller.js');

const router = express.Router();

router.post('/', controller.createUnit);
router.get('/', controller.getAllUnits);
router.put('/', controller.editUnitByName);
router.delete('/', controller.deleteUnitByName);

module.exports = router;
