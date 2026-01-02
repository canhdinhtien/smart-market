const Group = require('../models/Group');
const GroupMember = require('../models/GroupMember');
const User = require('../models/User');
const NotificationService = require('./notification.service');

/**
 * Create a new group
 * @param {number} adminId
 * @param {string} groupName
 */
const createGroup = async (adminId, groupName) => {
  if (!groupName) {
    const error = new Error('Group name is required');
    error.statusCode = 400;
    throw error;
  }

  const group = await Group.create({ name: groupName, admin_user_id: adminId });

  const adminUser = await User.findByPk(adminId);
  if (adminUser) {
    await addMember(group.id, adminUser.id, adminId);
  }

  return group;
};

/**
 * Add a member to a group by userId
 * @param {number} groupId
 * @param {number} targetUserId
 */
const addMember = async (groupId, targetUserId, requestingUserId) => {
  const group = await Group.findByPk(groupId);
  if (!group) {
    const error = new Error('Group not found');
    error.statusCode = 404;
    throw error;
  }
  if (group.admin_user_id != requestingUserId) {
    const error = new Error('Only group admin can add members');
    error.statusCode = 403;
    throw error;
  }

  const user = await User.findByPk(targetUserId);
  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  const exists = await GroupMember.findOne({ where: { group_id: groupId, user_id: user.id } });
  if (exists) {
    const error = new Error('User already in group');
    error.statusCode = 409;
    throw error;
  }

  await GroupMember.create({ group_id: groupId, user_id: user.id });

  // Notify the user
  NotificationService.sendToUser(
    user.id,
    'Added to Group',
    `You have been added to the group "${group.name}"`,
    { type: 'GROUP_ADD', groupId: group.id }
  );

  return { message: 'Member added successfully' };
};

/**
 * Delete a member from a group by userId
 * @param {number} groupId
 * @param {string} targetUserId
 */
const deleteMember = async (groupId, targetUserId, requestingUserId) => {
  const group = await Group.findByPk(groupId);
  if (!group) {
    const error = new Error('Group not found');
    error.statusCode = 404;
    throw error;
  }
  if (group.admin_user_id != requestingUserId) {
    const error = new Error('Only group admin can remove members');
    error.statusCode = 403;
    throw error;
  }

  const user = await User.findByPk(targetUserId);
  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  const member = await GroupMember.findOne({ where: { group_id: groupId, user_id: user.id } });
  if (!member) {
    const error = new Error('User not in group');
    error.statusCode = 404; // User not in group is conceptually 404 (resource not found), or 400.
    throw error;
  }

  await member.destroy();

  // Notify the user (even though they are removed, they might still get the push if token is active)
  NotificationService.sendToUser(
    user.id,
    'Removed from Group',
    `You have been removed from the group "${group.name}"`,
    { type: 'GROUP_REMOVE', groupId: group.id }
  );

  return { message: 'Member removed successfully' };
};

/**
 * Get all members of a group
 * @param {number} groupId
 */
const getGroupMembers = async (groupId, requestingUserId) => {
  const group = await Group.findByPk(groupId, {
    include: { model: User, as: 'members', attributes: ['id', 'name', 'email'] }
  });

  if (!group) {
    const error = new Error('Group not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await GroupMember.findOne({ where: { group_id: groupId, user_id: requestingUserId } });
  if (group.admin_user_id != requestingUserId && !isMember) {
    const error = new Error('Access denied: You must be a member or admin to view this group');
    error.statusCode = 403;
    throw error;
  }

  return group.members;
};

const getUserGroups = async (userId) => {
  // Groups where user is admin
  const adminGroups = await Group.findAll({
    where: { admin_user_id: userId },
    attributes: ['id', 'name', 'admin_user_id'],
  });

  // Groups where user is a member
  const memberGroups = await Group.findAll({
    include: [
      {
        model: User,
        as: 'members',
        where: { id: userId },
        attributes: [],
        through: { attributes: [] },
      },
    ],
    attributes: ['id', 'name', 'admin_user_id'],
  });

  // Combine and remove duplicates (if user is both admin and member)
  const allGroups = [...adminGroups, ...memberGroups].reduce((acc, group) => {
    if (!acc.find(g => g.id === group.id)) acc.push(group);
    return acc;
  }, []);

  return allGroups;
};

const getGroupById = async (groupId) => {
  const group = await Group.findByPk(groupId);
  return group;
};

/**
 * Check if a user is a member of a group
 * @param {number} groupId
 * @param {number} userId
 */
const isMember = async (groupId, userId) => {
  const group = await Group.findByPk(groupId);
  if (group && group.admin_user_id == userId) {
    return true;
  }

  const member = await GroupMember.findOne({
    where: {
      group_id: groupId,
      user_id: userId
    }
  });
  return !!member;
};


module.exports = {
  createGroup,
  addMember,
  deleteMember,
  getGroupMembers,
  getUserGroups,
  getGroupById,
  isMember,
};
