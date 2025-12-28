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
  if (!groupName) throw new Error('Group name is required');

  const group = await Group.create({ name: groupName, admin_user_id: adminId });

  const adminUser = await User.findByPk(adminId);
  if (adminUser) {
    await addMember(group.id, adminUser.username, adminId);
  }

  return group;
};

/**
 * Add a member to a group by username
 * @param {number} groupId
 * @param {string} username
 */
const addMember = async (groupId, username, requestingUserId) => {
  const group = await Group.findByPk(groupId);
  if (!group) throw new Error('Group not found');
  if (group.admin_user_id !== requestingUserId) throw new Error('Only group admin can add members');

  const user = await User.findOne({ where: { username } });
  if (!user) throw new Error('User not found');

  const exists = await GroupMember.findOne({ where: { group_id: groupId, user_id: user.id } });
  if (exists) throw new Error('User already in group');

  await GroupMember.create({ group_id: groupId, user_id: user.id });

  // Notify the user
  await NotificationService.sendToUser(
    user.id,
    'Added to Group',
    `You have been added to the group "${group.name}"`,
    { type: 'GROUP_ADD', groupId: group.id }
  );

  return { message: 'Member added successfully' };
};

/**
 * Delete a member from a group by username
 * @param {number} groupId
 * @param {string} username
 */
const deleteMember = async (groupId, username, requestingUserId) => {
  const group = await Group.findByPk(groupId);
  if (!group) throw new Error('Group not found');
  if (group.admin_user_id !== requestingUserId) throw new Error('Only group admin can remove members');

  const user = await User.findOne({ where: { username } });
  if (!user) throw new Error('User not found');

  const member = await GroupMember.findOne({ where: { group_id: groupId, user_id: user.id } });
  if (!member) throw new Error('User not in group');

  await member.destroy();

  // Notify the user (even though they are removed, they might still get the push if token is active)
  await NotificationService.sendToUser(
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
    include: { model: User, as: 'members', attributes: ['id', 'username', 'name', 'email'] }
  });

  if (!group) throw new Error('Group not found');

  const isMember = await GroupMember.findOne({ where: { group_id: groupId, user_id: requestingUserId } });
  if (group.admin_user_id !== requestingUserId && !isMember) {
    throw new Error('Access denied: You must be a member or admin to view this group');
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


module.exports = {
  createGroup,
  addMember,
  deleteMember,
  getGroupMembers,
  getUserGroups,
  getGroupById,
};
