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
    const { groupId, username } = req.body;

    if (!adminId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!groupId) return res.status(400).json({ message: 'Group ID is required' });
    if (!username || username.trim() === '') return res.status(400).json({ message: 'Username is required' });

    // Optional: check if current user is admin of the group
    const group = await groupService.getGroupById(groupId);
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
    const { groupId, username } = req.body;

    if (!adminId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!groupId) return res.status(400).json({ message: 'Group ID is required' });
    if (!username || username.trim() === '') return res.status(400).json({ message: 'Username is required' });

    const group = await groupService.getGroupById(groupId);
    if (!group) return res.status(404).json({ message: 'Group not found' });
    if (group.admin_user_id !== adminId) {
      return res.status(403).json({ message: 'Only group admin can remove members' });
    }

    const result = await groupService.deleteMember(groupId, username);
    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to remove member', error: err.message });
  }
};

/**
 * Get all members of a group
 */
const getGroupMembers = async (req, res) => {
  try {
    const { groupId } = req.body;
    if (!groupId) return res.status(400).json({ message: 'Group ID is required' });

    const members = await groupService.getGroupMembers(groupId);
    res.status(200).json(members);
  } catch (err) {
    console.error(err);
    res.status(404).json({ message: 'Failed to get group members', error: err.message });
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
