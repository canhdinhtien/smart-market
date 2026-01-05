const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class Category extends Model { }

Category.init({
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  }
}, {
  sequelize,
  modelName: 'Category',
  tableName: 'categories',
  timestamps: true,
  underscored: true,
  paranoid: true, // Enable soft delete
  deletedAt: 'deleted_at'
});

Category.associate = (models) => {
  Category.hasMany(models.Food, {
    foreignKey: 'category_id',
    as: 'foods'
  });
};

module.exports = Category;
