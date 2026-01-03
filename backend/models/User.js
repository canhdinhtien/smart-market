const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');
const { hashValue, compareValues } = require('../utils/hashUtils');

class User extends Model {
  checkPassword(candidatePassword) {
    return compareValues(candidatePassword, this.password_hash);
  }

  async updatePassword(newPassword) {
    const hashedPassword = await hashValue(newPassword);
    this.password_hash = hashedPassword;
    await this.save();
  }
}

User.init({
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  email: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true
    }
  },
  password_hash: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  name: {
    type: DataTypes.STRING(100),
    unique: false,
    allowNull: false
  },
  gender: {
    type: DataTypes.ENUM('male', 'female', 'other'),
    allowNull: true
  },
  image_url: {
    type: DataTypes.STRING(255),
    allowNull: true,
    validate: {
      isUrl: true
    }
  },
  is_verified: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  is_admin: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
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
  modelName: 'User',
  tableName: 'users',
  timestamps: false, // since we are using custom timestamps
  hooks: {
    beforeUpdate: (user) => {
      user.updated_at = new Date();
    }
  }
});


User.associate = (models) => {
  User.hasMany(models.UserDevice, {
    foreignKey: "user_id",
    as: "devices",
  });
  User.hasMany(models.Group, {
    foreignKey: 'admin_user_id',
    as: 'adminGroups'
  });
  User.belongsToMany(models.Group, {
    through: models.GroupMember,
    as: 'memberships',
    foreignKey: 'user_id',
    otherKey: 'group_id'
  });
};

module.exports = User;
