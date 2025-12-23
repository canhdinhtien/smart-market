const { DataTypes } = require("sequelize");
const sequelize = require("../config/database");
const User = require("./User");

const UserDevice = sequelize.define("UserDevice", {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },

  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
      key: "id",
    },
    onDelete: "CASCADE",
  },

  fcm_token: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },

  platform: {
    type: DataTypes.ENUM("android", "ios", "web"),
    allowNull: false,
  },

  device_id: {
    type: DataTypes.STRING,
    allowNull: true,
  },

  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
}, {
  tableName: "user_devices",
  timestamps: true,
});


User.hasMany(UserDevice, { foreignKey: "user_id" });
UserDevice.belongsTo(User, { foreignKey: "user_id" });

module.exports = UserDevice;
