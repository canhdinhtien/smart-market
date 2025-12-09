const Food = require('../models/Food');
const Category = require('../models/Category');
const Unit = require('../models/Unit');
const groupService = require('./group.service');

const createFood = async (foodData, requestingUserId) => {
  const { name, group_id } = foodData;

  const isMember = await groupService.isMember(group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to add food');
    error.statusCode = 403;
    throw error;
  }

  // Check if food with same name exists in the group
  const existingFood = await Food.findOne({ where: { name, group_id } });
  if (existingFood) {
    const error = new Error('Food with this name already exists in the group');
    error.statusCode = 409;
    throw error;
  }

  const newFood = await Food.create(foodData);
  return newFood;
};

const updateFood = async (id, foodData, requestingUserId) => {
  const food = await Food.findByPk(id);
  if (!food) {
    const error = new Error('Food not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(food.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to update food');
    error.statusCode = 403;
    throw error;
  }

  // If name is being updated, check for duplicates
  if (foodData.name && foodData.name !== food.name) {
    const existingFood = await Food.findOne({
      where: {
        name: foodData.name,
        group_id: food.group_id
      }
    });
    if (existingFood) {
      const error = new Error('Food with this name already exists in the group');
      error.statusCode = 409;
      throw error;
    }
  }

  await food.update(foodData);
  return food;
};

const deleteFood = async (id, requestingUserId) => {
  const food = await Food.findByPk(id);
  if (!food) {
    const error = new Error('Food not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(food.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to delete food');
    error.statusCode = 403;
    throw error;
  }

  await food.destroy();
  return { message: 'Food deleted successfully' };
};

const getAllFoodsInGroup = async (groupId, requestingUserId) => {
  const isMember = await groupService.isMember(groupId, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view foods');
    error.statusCode = 403;
    throw error;
  }

  return await Food.findAll({
    where: { group_id: groupId },
    include: [
      { model: Category, attributes: ['id', 'name'] },
      { model: Unit, attributes: ['id', 'name'] }
    ],
    order: [['created_at', 'DESC']]
  });
};

const getUnits = async () => {
  return await Unit.findAll();
};

const getCategories = async () => {
  return await Category.findAll();
};

const getFoodById = async (id, requestingUserId) => {
  const food = await Food.findByPk(id, {
    include: [
      { model: Category, attributes: ['id', 'name'] },
      { model: Unit, attributes: ['id', 'name'] }
    ]
  });

  if (!food) {
    const error = new Error('Food not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(food.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view this food');
    error.statusCode = 403;
    throw error;
  }

  return food;
};

module.exports = {
  createFood,
  updateFood,
  deleteFood,
  getAllFoodsInGroup,
  getUnits,
  getCategories,
  getFoodById
};
