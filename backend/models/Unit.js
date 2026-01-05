const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class Unit extends Model { }

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
  timestamps: true,
  underscored: true,
  paranoid: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  deletedAt: 'deleted_at'
});

Unit.associate = (models) => {
  Unit.hasMany(models.Food, {
    foreignKey: 'unit_id',
    as: 'foods'
  });
};

module.exports = Unit;
