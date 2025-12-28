const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');


class MealPlan extends Model { }

MealPlan.init({
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, allowNull: false },
  meal_type: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: { isIn: [['sang', 'trua', 'toi']] }
  },
  date: { type: DataTypes.DATEONLY, allowNull: false },
  recipe_id: { type: DataTypes.INTEGER, references: { model: 'recipes', key: 'id' } },
  food_id: { type: DataTypes.INTEGER, references: { model: 'foods', key: 'id' } },
  note: DataTypes.TEXT,
  group_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'groups', key: 'id' } },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'MealPlan',
  tableName: 'meal_plans',
  timestamps: false,
  hooks: { beforeUpdate: (m) => { m.updated_at = new Date(); } }
});

MealPlan.associate = (models) => {
  MealPlan.belongsTo(models.Group, { foreignKey: 'group_id' });
  MealPlan.belongsTo(models.Recipe, { foreignKey: 'recipe_id' });
  MealPlan.belongsTo(models.Food, { foreignKey: 'food_id' });
};


module.exports = MealPlan;
