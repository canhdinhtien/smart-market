const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');
const FridgeItem = require('./FridgeItem');
const User = require('./User');
const Group = require('./Group');

class Consumption extends Model {}

Consumption.init({
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, allowNull: false },
  fridge_item_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: FridgeItem, key: 'id' } },
  quantity_consumed: { type: DataTypes.NUMERIC, allowNull: false },
  date_consumed: { type: DataTypes.DATEONLY, allowNull: false },
  user_id: { type: DataTypes.INTEGER, references: { model: User, key: 'id' } },
  note: DataTypes.TEXT,
  group_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: Group, key: 'id' } },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'Consumption',
  tableName: 'consumptions',
  timestamps: false,
  hooks: { beforeUpdate: (c) => { c.updated_at = new Date(); } }
});

Consumption.belongsTo(FridgeItem, { foreignKey: 'fridge_item_id' });
Consumption.belongsTo(User, { foreignKey: 'user_id' });
Consumption.belongsTo(Group, { foreignKey: 'group_id' });

module.exports = Consumption;
