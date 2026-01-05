const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');


class Consumption extends Model { }

Consumption.init({
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, allowNull: false },
  fridge_item_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'fridge_items', key: 'id' } },
  quantity_consumed: { type: DataTypes.NUMERIC, allowNull: false },
  date_consumed: { type: DataTypes.DATEONLY, allowNull: false },
  user_id: { type: DataTypes.INTEGER, references: { model: 'users', key: 'id' } },
  note: DataTypes.TEXT,
  group_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'groups', key: 'id' } },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'Consumption',
  tableName: 'consumptions',
  timestamps: false,
  hooks: { beforeUpdate: (c) => { c.updated_at = new Date(); } }
});

Consumption.associate = (models) => {
  Consumption.belongsTo(models.FridgeItem, { foreignKey: 'fridge_item_id' });
  Consumption.belongsTo(models.User, { foreignKey: 'user_id' });
  Consumption.belongsTo(models.Group, { foreignKey: 'group_id' });
};

module.exports = Consumption;

