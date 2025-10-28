const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');
const Food = require('./Food');
const Group = require('./Group');

class FridgeItem extends Model {}

FridgeItem.init({
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, allowNull: false },
  food_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: Food, key: 'id' } },
  quantity: { type: DataTypes.NUMERIC, allowNull: false },
  use_within_days: { type: DataTypes.INTEGER, allowNull: false },
  note: DataTypes.TEXT,
  position: DataTypes.STRING,
  group_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: Group, key: 'id' } },
  expiry_date: DataTypes.DATE,
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'FridgeItem',
  tableName: 'fridge_items',
  timestamps: false,
  hooks: { beforeUpdate: (item) => { item.updated_at = new Date(); } }
});

FridgeItem.belongsTo(Food, { foreignKey: 'food_id' });
FridgeItem.belongsTo(Group, { foreignKey: 'group_id' });

module.exports = FridgeItem;
