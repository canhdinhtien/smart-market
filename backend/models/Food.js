const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');


class Food extends Model { }

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
    references: { model: 'categories', key: 'id' }
  },
  unit_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'units', key: 'id' }
  },
  image_url: DataTypes.STRING,
  group_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'groups', key: 'id' }
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



Food.associate = (models) => {
  Food.belongsTo(models.Category, { foreignKey: 'category_id' });
  Food.belongsTo(models.Unit, { foreignKey: 'unit_id' });
  Food.belongsTo(models.Group, { foreignKey: 'group_id' });
};

module.exports = Food;

