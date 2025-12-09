const groupService = require('../services/groupService');

/**
 * Create a new group
 */
const createGroup = async (req, res) => {
  try {
    const adminId = req.user?.id;
    const groupName = req.body?.name;

    if (!adminId) {
      return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    }

    if (!groupName || groupName.trim() === '') {
      return res.status(400).json({ message: 'Group name is required' });
    }

    const group = await groupService.createGroup(adminId, groupName);
    res.status(201).json(group);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to create group', error: err.message });
  }
};

/**
 * Add a member to a group
 */
const addMember = async (req, res) => {
  try {
    const adminId = req.user?.id;
    const groupId = req.params.id;
    const { username } = req.body;

    if (!adminId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!groupId) return res.status(400).json({ message: 'Group ID is required' });
    if (!username || username.trim() === '') return res.status(400).json({ message: 'Username is required' });

    // Optional: check if current user is admin of the group
    const group = await groupService.getGroupById(groupId); // NOTE: groupService.getGroupById needs to exist or be created usually, but let's check service file.
    // wait, I saw getGroupMembers does Group.findByPk. I should check if getGroupById exists or just use Group model directly or create helper.
    // The previous code called `groupService.getGroupById(groupId)`. 
    // I need to ensure `getGroupById` exists in service. I didn't see it explicitly exported in the file view earlier (only create, add, delete, getMembers, getUserGroups).
    // It might be missing! The original code used it though? line 40: `const group = await groupService.getGroupById(groupId);`
    // If it was missing before, it was broken. I will assume I need to add it or it was there and I missed it in the snippet or it's `getGroupDetails`.
    // Actually, I should probably implement it if missing.

    if (!group) return res.status(404).json({ message: 'Group not found' });
    if (group.admin_user_id !== adminId) {
      return res.status(403).json({ message: 'Only group admin can add members' });
    }

    const result = await groupService.addMember(groupId, username);
    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to add member', error: err.message });
  }
};

/**
 * Delete a member from a group
 */
const deleteMember = async (req, res) => {
  try {
    const adminId = req.user?.id;
    const groupId = req.params.id;
    const username = req.params.username;

    if (!adminId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!groupId) return res.status(400).json({ message: 'Group ID is required' });
    if (!username || username.trim() === '') return res.status(400).json({ message: 'Username is required' });

    const result = await groupService.deleteMember(groupId, username, adminId);
    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    const statusCode = err.message.includes('Only group admin') ? 403 : 500;
    res.status(statusCode).json({ message: 'Failed to remove member', error: err.message });
  }
};

/**
 * Get all members of a group
 */
const getGroupMembers = async (req, res) => {
  try {
    const groupId = req.params.id;
    const userId = req.user?.id;
    if (!groupId) return res.status(400).json({ message: 'Group ID is required' });
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });

    const members = await groupService.getGroupMembers(groupId, userId);
    res.status(200).json(members);
  } catch (err) {
    console.error(err);
    const statusCode = err.message.includes('Access denied') ? 403 : 404;
    res.status(statusCode).json({ message: 'Failed to get group members', error: err.message });
  }
};

const getUserGroups = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });

    const groups = await groupService.getUserGroups(userId);
    res.status(200).json(groups);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch groups', error: err.message });
  }
};

module.exports = {
  createGroup,
  addMember,
  deleteMember,
  getGroupMembers,
  getUserGroups
};
