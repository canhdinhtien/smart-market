const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');


class FridgeItem extends Model { }

FridgeItem.init({
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, allowNull: false },
  food_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'foods', key: 'id' } },
  quantity: { type: DataTypes.NUMERIC, allowNull: false },
  use_within_days: { type: DataTypes.INTEGER, allowNull: false },
  note: DataTypes.TEXT,
  position: DataTypes.STRING,
  group_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'groups', key: 'id' } },
  expiry_date: DataTypes.DATE,
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'FridgeItem',
  tableName: 'fridge_items',
  timestamps: true,
  underscored: true,
  paranoid: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  deletedAt: 'deleted_at'
});

FridgeItem.associate = (models) => {
  FridgeItem.belongsTo(models.Food, { foreignKey: 'food_id' });
  FridgeItem.belongsTo(models.Group, { foreignKey: 'group_id' });
};

module.exports = FridgeItem;

