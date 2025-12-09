const express = require('express');
const controller = require('../controllers/group.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.get('/', controller.getUserGroups);
router.post('/', controller.createGroup);
router.get('/:id/members', controller.getGroupMembers);
router.post('/:id/members', controller.addMember);
router.delete('/:id/members/:username', controller.deleteMember);

module.exports = router;
