const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');


class ShoppingListTask extends Model { }

ShoppingListTask.init({
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, allowNull: false },
  shopping_list_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'shopping_lists', key: 'id' } },
  food_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'foods', key: 'id' } },
  quantity: { type: DataTypes.NUMERIC, allowNull: false },
  assign_to_user_id: { type: DataTypes.INTEGER, references: { model: 'users', key: 'id' } },
  is_purchased: { type: DataTypes.BOOLEAN, defaultValue: false },
  note: DataTypes.TEXT,
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'ShoppingListTask',
  tableName: 'shopping_list_tasks',
  timestamps: false,
  hooks: { beforeUpdate: (t) => { t.updated_at = new Date(); } }
});

ShoppingListTask.associate = (models) => {
  ShoppingListTask.belongsTo(models.ShoppingList, { foreignKey: 'shopping_list_id' });
  ShoppingListTask.belongsTo(models.Food, { foreignKey: 'food_id' });
  ShoppingListTask.belongsTo(models.User, { foreignKey: 'assign_to_user_id' });
};


module.exports = ShoppingListTask;
