const express = require('express');
const controller = require('../controllers/unit.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.post('/', controller.createUnit);
router.get('/', controller.getAllUnits);
router.put('/', controller.editUnitByName);
router.delete('/', controller.deleteUnitByName);

module.exports = router;
