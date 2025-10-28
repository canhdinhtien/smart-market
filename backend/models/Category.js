const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class Category extends Model {}

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
  timestamps: false
});

module.exports = Category;
