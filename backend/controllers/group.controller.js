const groupService = require('../services/groupService');

/**
 * Create a new group
 */
const createGroup = async (req, res, next) => {
  try {
    const adminId = req.user?.id;
    const groupName = req.body?.name;

    if (!adminId) {
      const error = new Error('Unauthorized: User ID missing');
      error.statusCode = 401;
      throw error;
    }

    if (!groupName || groupName.trim() === '') {
      const error = new Error('Group name is required');
      error.statusCode = 400;
      throw error;
    }

    const group = await groupService.createGroup(adminId, groupName);
    res.status(201).json(group);
  } catch (err) {
    next(err);
  }
};

/**
 * Add a member to a group
 */
const addMember = async (req, res, next) => {
  try {
    const adminId = req.user?.id;
    const groupId = req.params.id;
    const { username } = req.body;

    if (!adminId) {
      const error = new Error('Unauthorized: User ID missing');
      error.statusCode = 401;
      throw error;
    }

    if (!groupId) {
      const error = new Error('Group ID is required');
      error.statusCode = 400;
      throw error;
    }

    if (!username || username.trim() === '') {
      const error = new Error('Username is required');
      error.statusCode = 400;
      throw error;
    }

    const group = await groupService.getGroupById(groupId);
    if (!group) {
      const error = new Error('Group not found');
      error.statusCode = 404;
      throw error;
    }

    if (group.admin_user_id !== adminId) {
      const error = new Error('Only group admin can add members');
      error.statusCode = 403;
      throw error;
    }

    const result = await groupService.addMember(groupId, username);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

/**
 * Delete a member from a group
 */
const deleteMember = async (req, res, next) => {
  try {
    const adminId = req.user?.id;
    const groupId = req.params.id;
    const username = req.params.username;

    if (!adminId) {
      const error = new Error('Unauthorized: User ID missing');
      error.statusCode = 401;
      throw error;
    }

    if (!groupId) {
      const error = new Error('Group ID is required');
      error.statusCode = 400;
      throw error;
    }

    if (!username || username.trim() === '') {
      const error = new Error('Username is required');
      error.statusCode = 400;
      throw error;
    }

    const result = await groupService.deleteMember(groupId, username, adminId);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

/**
 * Get all members of a group
 */
const getGroupMembers = async (req, res, next) => {
  try {
    const groupId = req.params.id;
    const userId = req.user?.id;

    if (!groupId) {
      const error = new Error('Group ID is required');
      error.statusCode = 400;
      throw error;
    }

    if (!userId) {
      const error = new Error('Unauthorized: User ID missing');
      error.statusCode = 401;
      throw error;
    }

    const members = await groupService.getGroupMembers(groupId, userId);
    res.json(members);
  } catch (err) {
    next(err);
  }
};

/**
 * Get groups of a user
 */
const getUserGroups = async (req, res, next) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      const error = new Error('Unauthorized: User ID missing');
      error.statusCode = 401;
      throw error;
    }

    const groups = await groupService.getUserGroups(userId);
    res.json(groups);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createGroup,
  addMember,
  deleteMember,
  getGroupMembers,
  getUserGroups
};
