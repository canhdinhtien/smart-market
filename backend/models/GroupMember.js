const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./User');
const Group = require('./Group');

class GroupMember extends Model {}

GroupMember.init({
  user_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: User, key: 'id' } },
  group_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: Group, key: 'id' } },
  joined_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'GroupMember',
  tableName: 'group_members',
  timestamps: false
});

GroupMember.belongsTo(User, { foreignKey: 'user_id' });
GroupMember.belongsTo(Group, { foreignKey: 'group_id' });

module.exports = GroupMember;
