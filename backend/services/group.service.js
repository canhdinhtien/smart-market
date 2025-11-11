const Group = require('../models/Group');
const GroupMember = require('../models/GroupMember');
const User = require('../models/User');

/**
 * Create a new group
 * @param {number} adminId
 * @param {string} groupName
 */
const createGroup = async (adminId, groupName) => {
  if (!groupName) throw new Error('Group name is required');

  const group = await Group.create({ name: groupName, admin_user_id: adminId });
  return group;
};

/**
 * Add a member to a group by username
 * @param {number} groupId
 * @param {string} username
 */
const addMember = async (groupId, username) => {
  const user = await User.findOne({ where: { username } });
  if (!user) throw new Error('User not found');

  const exists = await GroupMember.findOne({ where: { group_id: groupId, user_id: user.id } });
  if (exists) throw new Error('User already in group');

  await GroupMember.create({ group_id: groupId, user_id: user.id });
  return { message: 'Member added successfully' };
};

/**
 * Delete a member from a group by username
 * @param {number} groupId
 * @param {string} username
 */
const deleteMember = async (groupId, username) => {
  const user = await User.findOne({ where: { username } });
  if (!user) throw new Error('User not found');

  const member = await GroupMember.findOne({ where: { group_id: groupId, user_id: user.id } });
  if (!member) throw new Error('User not in group');

  await member.destroy();
  return { message: 'Member removed successfully' };
};

/**
 * Get all members of a group
 * @param {number} groupId
 */
const getGroupMembers = async (groupId) => {
  const group = await Group.findByPk(groupId, {
    include: { model: User, as: 'members', attributes: ['id', 'username', 'name', 'email'] }
  });

  if (!group) throw new Error('Group not found');
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


module.exports = {
  createGroup,
  addMember,
  deleteMember,
  getGroupMembers,
  getUserGroups
};
