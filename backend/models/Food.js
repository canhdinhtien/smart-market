const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');
const Category = require('./Category');
const Unit = require('./Unit');
const Group = require('./Group');

class Food extends Model {}

Food.init({
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  name: { type: DataTypes.STRING, allowNull: false },
  category_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: Category, key: 'id' }
  },
  unit_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: Unit, key: 'id' }
  },
  image_url: DataTypes.STRING,
  group_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: Group, key: 'id' }
  },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'Food',
  tableName: 'foods',
  timestamps: false,
  hooks: {
    beforeUpdate: (food) => { food.updated_at = new Date(); }
  }
});

// Associations
Food.belongsTo(Category, { foreignKey: 'category_id' });
Food.belongsTo(Unit, { foreignKey: 'unit_id' });
Food.belongsTo(Group, { foreignKey: 'group_id' });

module.exports = Food;
