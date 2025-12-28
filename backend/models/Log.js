const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');


class Log extends Model { }

Log.init({
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, allowNull: false },
  user_id: { type: DataTypes.INTEGER, references: { model: 'users', key: 'id' } },
  action: { type: DataTypes.STRING, allowNull: false },
  details: DataTypes.TEXT,
  entity: DataTypes.STRING,
  entity_id: DataTypes.BIGINT,
  timestamp: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  sequelize,
  modelName: 'Log',
  tableName: 'logs',
  timestamps: false
});

Log.associate = (models) => {
  Log.belongsTo(models.User, { foreignKey: 'user_id' });
};


module.exports = Log;
