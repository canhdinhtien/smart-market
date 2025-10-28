const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');
const Group = require('./Group');

class ShoppingList extends Model {}

ShoppingList.init({
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, allowNull: false },
  name: { type: DataTypes.STRING, allowNull: false },
  date: DataTypes.DATEONLY,
  note: DataTypes.TEXT,
  group_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: Group, key: 'id' } },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'ShoppingList',
  tableName: 'shopping_lists',
  timestamps: false,
  hooks: { beforeUpdate: (s) => { s.updated_at = new Date(); } }
});

ShoppingList.belongsTo(Group, { foreignKey: 'group_id' });

module.exports = ShoppingList;
