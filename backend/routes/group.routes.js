const express = require('express');
const controller = require('../controllers/group.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.post('/', controller.createGroup);
router.post('/add', controller.addMember);
router.delete('/', controller.deleteMember);
router.get('/', controller.getGroupMembers);
router.get('/all', controller.getUserGroups);

module.exports = router;
