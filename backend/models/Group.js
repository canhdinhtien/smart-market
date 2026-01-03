const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database'); // adjust path


class Group extends Model { }

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
      model: 'users',
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
  timestamps: true, // Required for paranoid mode
  underscored: true,
  paranoid: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  deletedAt: 'deleted_at'
});



Group.associate = (models) => {
  Group.belongsTo(models.User, { foreignKey: 'admin_user_id', as: 'admin' });
  Group.belongsToMany(models.User, {
    through: models.GroupMember,
    as: 'members',
    foreignKey: 'group_id',
    otherKey: 'user_id'
  });
};

module.exports = Group;

