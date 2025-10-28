const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');
const Recipe = require('./Recipe');
const Food = require('./Food');
const Unit = require('./Unit');

class RecipeIngredient extends Model {}

RecipeIngredient.init({
  recipe_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: Recipe, key: 'id' } },
  food_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: Food, key: 'id' } },
  quantity: { type: DataTypes.NUMERIC, allowNull: false },
  unit_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: Unit, key: 'id' } }
}, {
  sequelize,
  modelName: 'RecipeIngredient',
  tableName: 'recipe_ingredients',
  timestamps: false
});

RecipeIngredient.belongsTo(Recipe, { foreignKey: 'recipe_id' });
RecipeIngredient.belongsTo(Food, { foreignKey: 'food_id' });
RecipeIngredient.belongsTo(Unit, { foreignKey: 'unit_id' });

module.exports = RecipeIngredient;
