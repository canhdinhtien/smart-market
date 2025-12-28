const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');


class RecipeIngredient extends Model { }

RecipeIngredient.init({
  recipe_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: 'recipes', key: 'id' } },
  food_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: 'foods', key: 'id' } },
  quantity: { type: DataTypes.NUMERIC, allowNull: false },
  unit_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'units', key: 'id' } }
}, {
  sequelize,
  modelName: 'RecipeIngredient',
  tableName: 'recipe_ingredients',
  timestamps: false
});

RecipeIngredient.associate = (models) => {
  RecipeIngredient.belongsTo(models.Recipe, { foreignKey: 'recipe_id' });
  RecipeIngredient.belongsTo(models.Food, { foreignKey: 'food_id' });
  RecipeIngredient.belongsTo(models.Unit, { foreignKey: 'unit_id' });
};


module.exports = RecipeIngredient;
