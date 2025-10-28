const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class Unit extends Model {}

Unit.init({
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
  modelName: 'Unit',
  tableName: 'units',
  timestamps: false
});

module.exports = Unit;
