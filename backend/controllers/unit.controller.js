const unitService = require('../services/unit.service');

const createUnit = async (req, res, next) => {
  try {
    const { unitName } = req.body;

    if (!unitName) {
      const error = new Error('unitName is required');
      error.statusCode = 400;
      throw error;
    }

    const newUnit = await unitService.createUnit(unitName);
    res.status(201).json(newUnit);
  } catch (error) {
    next(error);
  }
};

const getAllUnits = async (req, res, next) => {
  try {
    let { page, limit } = req.query;
    page = parseInt(page) || 1;
    limit = parseInt(limit) || 20;
    const units = await unitService.getAllUnits(page, limit);
    res.status(200).json(units);
  } catch (error) {
    next(error);
  }
};

const editUnitByName = async (req, res, next) => {
  try {
    const { oldName, newName } = req.body;

    if (!oldName || !newName) {
      const error = new Error('oldName and newName are required');
      error.statusCode = 400;
      throw error;
    }

    const updatedUnit = await unitService.editUnitByName(oldName, newName);
    res.status(200).json(updatedUnit);
  } catch (error) {
    next(error);
  }
};

const deleteUnitByName = async (req, res, next) => {
  try {
    const { unitName } = req.body;

    if (!unitName) {
      const error = new Error('unitName is required');
      error.statusCode = 400;
      throw error;
    }

    const result = await unitService.deleteUnitByName(unitName);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createUnit,
  getAllUnits,
  editUnitByName,
  deleteUnitByName,
};
