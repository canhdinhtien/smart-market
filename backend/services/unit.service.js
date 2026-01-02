const Unit = require('../models/Unit');

const createUnit = async (unitName) => {
  const existingUnit = await Unit.findOne({ where: { name: unitName } });
  if (existingUnit) {
    const error = new Error('Unit already exists');
    error.statusCode = 409;
    throw error;
  }

  const newUnit = await Unit.create({ name: unitName });
  return newUnit;
};

const getAllUnits = async (page = 1, limit = 20) => {
  const offset = (page - 1) * limit;
  const { count, rows } = await Unit.findAndCountAll({
    limit: limit,
    offset: offset,
    order: [['name', 'ASC']]
  });
  return {
    units: rows,
    total: count,
    page: parseInt(page),
    totalPages: Math.ceil(count / limit)
  };
};

const editUnitByName = async (oldName, newName) => {
  const nameExists = await Unit.findOne({ where: { name: newName } });
  if (nameExists) {
    const error = new Error('Unit with that new name already exists');
    error.statusCode = 409;
    throw error;
  }

  const [updatedRows] = await Unit.update(
    { name: newName },
    { where: { name: oldName } }
  );

  if (updatedRows === 0) {
    const error = new Error('Unit not found');
    error.statusCode = 404;
    throw error;
  }

  const updatedUnit = await Unit.findOne({ where: { name: newName } });
  return updatedUnit;
};

const deleteUnitByName = async (unitName) => {
  const deletedRows = await Unit.destroy({ where: { name: unitName } });

  if (deletedRows === 0) {
    const error = new Error('Unit not found');
    error.statusCode = 404;
    throw error;
  }

  return { message: 'Unit deleted successfully' };
};

module.exports = {
  createUnit,
  getAllUnits,
  editUnitByName,
  deleteUnitByName,
};
