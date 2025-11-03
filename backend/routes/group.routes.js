const express = require('express');
const controller = require('../controllers/group.controller.js');

const router = express.Router();

router.post('/', controller.createGroup);
router.post('/add', controller.addMember);
router.delete('/', controller.deleteMember);
router.get('/', controller.getGroupMembers);

module.exports = router;
