const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');


class ShoppingList extends Model { }

ShoppingList.init({
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, allowNull: false },
  name: { type: DataTypes.STRING, allowNull: false },
  date: DataTypes.DATEONLY,
  note: DataTypes.TEXT,
  group_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'groups', key: 'id' } },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'ShoppingList',
  tableName: 'shopping_lists',
  timestamps: true,
  underscored: true,
  paranoid: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  deletedAt: 'deleted_at'
});

ShoppingList.associate = (models) => {
  ShoppingList.belongsTo(models.Group, { foreignKey: 'group_id' });
  ShoppingList.hasMany(models.ShoppingListTask, { foreignKey: 'shopping_list_id', as: 'tasks' });
};


module.exports = ShoppingList;
