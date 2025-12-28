const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');


class Recipe extends Model { }

Recipe.init({
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, allowNull: false },
  name: { type: DataTypes.STRING, allowNull: false },
  description: DataTypes.TEXT,
  instructions: DataTypes.TEXT,
  group_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'groups', key: 'id' } },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'Recipe',
  tableName: 'recipes',
  timestamps: false,
  hooks: { beforeUpdate: (r) => { r.updated_at = new Date(); } }
});

Recipe.associate = (models) => {
  Recipe.belongsTo(models.Group, { foreignKey: 'group_id' });
};


module.exports = Recipe;
