const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');


class GroupMember extends Model { }

GroupMember.init({
  user_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: 'users', key: 'id' } },
  group_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: 'groups', key: 'id' } },
  joined_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'GroupMember',
  tableName: 'group_members',
  timestamps: false
});

GroupMember.associate = (models) => {
  GroupMember.belongsTo(models.User, { foreignKey: 'user_id' });
  GroupMember.belongsTo(models.Group, { foreignKey: 'group_id' });
};

module.exports = GroupMember;

