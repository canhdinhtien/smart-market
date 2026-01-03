const Food = require('../models/Food');
const Category = require('../models/Category');
const Unit = require('../models/Unit');
const Group = require('../models/Group');
const groupService = require('./group.service');
const { deleteImage } = require('../utils/imageUtils');
const { validateNotDeleted } = require('../utils/validateNotDeleted');
const { Op } = require('sequelize');

const createFood = async (foodData, requestingUserId) => {
  const { name, group_id, category_id, unit_id, image_url } = foodData;

  const isMember = await groupService.isMember(group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to add food');
    error.statusCode = 403;
    throw error;
  }

  // Validate that referenced entities are not deleted
  await validateNotDeleted(Group, group_id, 'Group');
  if (category_id) {
    await validateNotDeleted(Category, category_id, 'Category');
  }
  await validateNotDeleted(Unit, unit_id, 'Unit');

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

  const oldImageUrl = food.image_url;
  foodData.image_url = foodData.image_url ? foodData.image_url : oldImageUrl;

  await food.update(foodData);

  // If new image is provided and it's different from old one, delete old one
  if (foodData.image_url && oldImageUrl && foodData.image_url !== oldImageUrl) {
    await deleteImage(oldImageUrl);
  }

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

  const imageUrl = food.image_url;

  await food.destroy();

  // Delete image if exists
  if (imageUrl) {
    await deleteImage(imageUrl);
  }

  return { message: 'Food deleted successfully' };
};

const getAllFoodsInGroup = async (groupId, requestingUserId, page = 1, limit = 20, name = null, categoryId = null) => {
  const isMember = await groupService.isMember(groupId, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view foods');
    error.statusCode = 403;
    throw error;
  }

  const offset = (page - 1) * limit;

  const whereClause = { group_id: groupId };
  if (name) {
    whereClause.name = { [Op.iLike]: `%${name}%` };
  }
  if (categoryId) {
    whereClause.category_id = categoryId;
  }

  const { count, rows } = await Food.findAndCountAll({
    where: whereClause,
    include: [
      { model: Unit, attributes: ['id', 'name', 'deleted_at'], paranoid: false },
      { model: Category, attributes: ['id', 'name', 'deleted_at'], paranoid: false }
    ],
    limit: limit,
    offset: offset,
    order: [['name', 'ASC']]
  });

  // Add is_deleted flags
  const foodsWithFlags = rows.map(food => {
    const foodJson = food.toJSON();
    if (foodJson.Unit) {
      foodJson.Unit.is_deleted = !!foodJson.Unit.deleted_at;
      delete foodJson.Unit.deleted_at;
    }
    if (foodJson.Category) {
      foodJson.Category.is_deleted = !!foodJson.Category.deleted_at;
      delete foodJson.Category.deleted_at;
    }
    return foodJson;
  });

  return {
    foods: foodsWithFlags,
    total: count,
    page: parseInt(page),
    totalPages: Math.ceil(count / limit)
  };
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
      { model: Category, attributes: ['id', 'name', 'deleted_at'], paranoid: false },
      { model: Unit, attributes: ['id', 'name', 'deleted_at'], paranoid: false }
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

  // Add is_deleted flags
  const foodJson = food.toJSON();
  if (foodJson.Category) {
    foodJson.Category.is_deleted = !!foodJson.Category.deleted_at;
    delete foodJson.Category.deleted_at;
  }
  if (foodJson.Unit) {
    foodJson.Unit.is_deleted = !!foodJson.Unit.deleted_at;
    delete foodJson.Unit.deleted_at;
  }

  return foodJson;
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
