const FridgeItem = require('../models/FridgeItem');
const Food = require('../models/Food');
const Category = require('../models/Category');
const Unit = require('../models/Unit');
const Group = require('../models/Group');
const groupService = require('./group.service');
const NotificationService = require('./notification.service');
const { validateNotDeleted } = require('../utils/validateNotDeleted');
const { Op } = require('sequelize');

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

  // Validate that referenced entities are not deleted
  await validateNotDeleted(Food, food_id, 'Food');
  await validateNotDeleted(Group, group_id, 'Group');

  const newItem = await FridgeItem.create(data);

  // Notify group
  const food = await Food.findByPk(food_id);
  NotificationService.sendToGroup(
    group_id,
    'Fridge Update',
    `${food ? food.name : 'Item'} đã được thêm vào tủ lạnh`,
    { type: 'FRIDGE_ADD', itemId: newItem.id },
    requestingUserId
  );

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

  NotificationService.sendToGroup(
    item.group_id,
    'Fridge Update',
    'Item in fridge updated',
    { type: 'FRIDGE_UPDATE', itemId: item.id },
    requestingUserId
  );

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

  NotificationService.sendToGroup(
    item.group_id,
    'Fridge Update',
    'Item removed from fridge',
    { type: 'FRIDGE_REMOVE', itemId: id },
    requestingUserId
  );

  return { message: 'Fridge item deleted successfully' };
};

const getAllFridgeItems = async (groupId, requestingUserId, page = 1, limit = 20, name = null) => {
  const isMember = await groupService.isMember(groupId, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view fridge items');
    error.statusCode = 403;
    throw error;
  }

  const offset = (page - 1) * limit;

  const foodInclude = {
    model: Food,
    attributes: ['id', 'name', 'image_url', 'deleted_at'],
    paranoid: false,
    include: [
      { model: Unit, attributes: ['id', 'name', 'deleted_at'], paranoid: false },
      { model: Category, attributes: ['id', 'name', 'deleted_at'], paranoid: false }
    ]
  };

  if (name) {
    foodInclude.where = { name: { [Op.iLike]: `%${name}%` } };
  }

  const { count, rows } = await FridgeItem.findAndCountAll({
    where: { group_id: groupId },
    include: [foodInclude],
    limit: limit,
    offset: offset,
    order: [['created_at', 'DESC']]
  });

  // Add is_deleted flags
  const itemsWithFlags = rows.map(item => {
    const itemJson = item.toJSON();
    if (itemJson.Food) {
      itemJson.Food.is_deleted = !!itemJson.Food.deleted_at;
      delete itemJson.Food.deleted_at;

      if (itemJson.Food.Unit) {
        itemJson.Food.Unit.is_deleted = !!itemJson.Food.Unit.deleted_at;
        delete itemJson.Food.Unit.deleted_at;
      }
      if (itemJson.Food.Category) {
        itemJson.Food.Category.is_deleted = !!itemJson.Food.Category.deleted_at;
        delete itemJson.Food.Category.deleted_at;
      }
    }
    return itemJson;
  });

  return {
    items: itemsWithFlags,
    total: count,
    page: parseInt(page),
    totalPages: Math.ceil(count / limit)
  };
};

const getFridgeItemById = async (id, requestingUserId) => {
  const item = await FridgeItem.findByPk(id, {
    include: [
      {
        model: Food,
        attributes: ['id', 'name', 'image_url', 'deleted_at'],
        paranoid: false,
        include: [
          { model: Category, attributes: ['id', 'name', 'deleted_at'], paranoid: false },
          { model: Unit, attributes: ['id', 'name', 'deleted_at'], paranoid: false }
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

  // Add is_deleted flags
  const itemJson = item.toJSON();
  if (itemJson.Food) {
    itemJson.Food.is_deleted = !!itemJson.Food.deleted_at;
    delete itemJson.Food.deleted_at;

    if (itemJson.Food.Category) {
      itemJson.Food.Category.is_deleted = !!itemJson.Food.Category.deleted_at;
      delete itemJson.Food.Category.deleted_at;
    }
    if (itemJson.Food.Unit) {
      itemJson.Food.Unit.is_deleted = !!itemJson.Food.Unit.deleted_at;
      delete itemJson.Food.Unit.deleted_at;
    }
  }

  return itemJson;
};

module.exports = {
  createFridgeItem,
  updateFridgeItem,
  deleteFridgeItem,
  getAllFridgeItems,
  getFridgeItemById,
};
