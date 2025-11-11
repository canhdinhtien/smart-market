const express = require('express');
const controller = require('../controllers/group.controller.js');
const { route } = require('./user.routes.js');

const router = express.Router();

router.post('/', controller.createGroup);
router.post('/add', controller.addMember);
router.delete('/', controller.deleteMember);
router.get('/', controller.getGroupMembers);
router.get('/all', controller.getUserGroups);

module.exports = router;
