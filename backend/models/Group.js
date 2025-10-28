const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database'); // adjust path
const User = require('./User.js'); // make sure path to User model is correct

class Group extends Model {}

Group.init({
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  name: {
    type: DataTypes.STRING(100),
    allowNull: false
  },
  admin_user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
      key: 'id'
    },
    onDelete: 'CASCADE'
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  updated_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  sequelize,
  modelName: 'Group',
  tableName: 'groups',
  timestamps: false, // using custom timestamps
  hooks: {
    beforeUpdate: (group) => {
      group.updated_at = new Date();
    }
  }
});

// Optional: define association
Group.belongsTo(User, { foreignKey: 'admin_user_id', as: 'admin' });
User.hasMany(Group, { foreignKey: 'admin_user_id', as: 'adminGroups' });

module.exports = Group;
