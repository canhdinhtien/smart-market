const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');
const Group = require('./Group');
const Recipe = require('./Recipe');
const Food = require('./Food');

class MealPlan extends Model {}

MealPlan.init({
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, allowNull: false },
  meal_type: { 
    type: DataTypes.STRING,
    allowNull: false,
    validate: { isIn: [['sang', 'trua', 'toi']] }
  },
  date: { type: DataTypes.DATEONLY, allowNull: false },
  recipe_id: { type: DataTypes.INTEGER, references: { model: Recipe, key: 'id' } },
  food_id: { type: DataTypes.INTEGER, references: { model: Food, key: 'id' } },
  note: DataTypes.TEXT,
  group_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: Group, key: 'id' } },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'MealPlan',
  tableName: 'meal_plans',
  timestamps: false,
  hooks: { beforeUpdate: (m) => { m.updated_at = new Date(); } }
});

MealPlan.belongsTo(Group, { foreignKey: 'group_id' });
MealPlan.belongsTo(Recipe, { foreignKey: 'recipe_id' });
MealPlan.belongsTo(Food, { foreignKey: 'food_id' });

module.exports = MealPlan;
