const FridgeItem = require('../models/FridgeItem');
const Food = require('../models/Food');
const Category = require('../models/Category');
const Unit = require('../models/Unit');
const groupService = require('./group.service');

const createFridgeItem = async (data, requestingUserId) => {
  const { food_id, group_id } = data;

  // Basic validation
  if (!food_id || !group_id) {
    const error = new Error('Food ID and Group ID are required');
    error.statusCode = 400;
    throw error;
  }

  const isMember = await groupService.isMember(group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to add fridge items');
    error.statusCode = 403;
    throw error;
  }

  const newItem = await FridgeItem.create(data);
  return newItem;
};

const updateFridgeItem = async (id, data, requestingUserId) => {
  const item = await FridgeItem.findByPk(id);
  if (!item) {
    const error = new Error('Fridge item not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(item.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to update fridge items');
    error.statusCode = 403;
    throw error;
  }

  await item.update(data);
  return item;
};

const deleteFridgeItem = async (id, requestingUserId) => {
  const item = await FridgeItem.findByPk(id);
  if (!item) {
    const error = new Error('Fridge item not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(item.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to delete fridge items');
    error.statusCode = 403;
    throw error;
  }

  await item.destroy();
  return { message: 'Fridge item deleted successfully' };
};

const getAllFridgeItems = async (groupId, requestingUserId) => {
  const isMember = await groupService.isMember(groupId, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view fridge items');
    error.statusCode = 403;
    throw error;
  }

  return await FridgeItem.findAll({
    where: { group_id: groupId },
    include: [
      {
        model: Food,
        attributes: ['id', 'name', 'image_url'],
        include: [
          { model: Category, attributes: ['id', 'name'] },
          { model: Unit, attributes: ['id', 'name'] }
        ]
      }
    ],
    order: [['expiry_date', 'ASC'], ['created_at', 'DESC']]
  });
};

const getFridgeItemById = async (id, requestingUserId) => {
  const item = await FridgeItem.findByPk(id, {
    include: [
      {
        model: Food,
        attributes: ['id', 'name', 'image_url'],
        include: [
          { model: Category, attributes: ['id', 'name'] },
          { model: Unit, attributes: ['id', 'name'] }
        ]
      }
    ]
  });

  if (!item) {
    const error = new Error('Fridge item not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(item.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view this fridge item');
    error.statusCode = 403;
    throw error;
  }

  return item;
};

module.exports = {
  createFridgeItem,
  updateFridgeItem,
  deleteFridgeItem,
  getAllFridgeItems,
  getFridgeItemById,
};
