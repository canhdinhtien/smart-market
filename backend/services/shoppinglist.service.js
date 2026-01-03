const ShoppingList = require('../models/ShoppingList');
const ShoppingListTask = require('../models/ShoppingListTask');
const Food = require('../models/Food');
const User = require('../models/User');
const Unit = require('../models/Unit');
const Category = require('../models/Category');
const Group = require('../models/Group');
const groupService = require('./group.service');
const NotificationService = require('./notification.service');
const { validateNotDeleted } = require('../utils/validateNotDeleted');
const { Op } = require('sequelize');

const createShoppingList = async (data, requestingUserId) => {
  const { name, group_id } = data;
  if (!name || !group_id) {
    const error = new Error('Name and Group ID are required');
    error.statusCode = 400;
    throw error;
  }

  const isMember = await groupService.isMember(group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to create a shopping list');
    error.statusCode = 403;
    throw error;
  }

  // Validate that group is not deleted
  await validateNotDeleted(Group, group_id, 'Group');

  return await ShoppingList.create(data);
};

const updateShoppingList = async (id, data, requestingUserId) => {
  const list = await ShoppingList.findByPk(id);
  if (!list) {
    const error = new Error('Shopping list not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(list.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to update this shopping list');
    error.statusCode = 403;
    throw error;
  }

  await list.update(data);
  return list;
};

const deleteShoppingList = async (id, requestingUserId) => {
  const list = await ShoppingList.findByPk(id);
  if (!list) {
    const error = new Error('Shopping list not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(list.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to delete this shopping list');
    error.statusCode = 403;
    throw error;
  }

  await list.destroy();
  return { message: 'Shopping list deleted successfully' };
};

const getAllShoppingLists = async (groupId, requestingUserId, page = 1, limit = 20, name = null) => {
  const isMember = await groupService.isMember(groupId, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view shopping lists');
    error.statusCode = 403;
    throw error;
  }

  const offset = (page - 1) * limit;

  const whereClause = { group_id: groupId };
  if (name) {
    whereClause.name = { [Op.iLike]: `%${name}%` };
  }

  const { count, rows } = await ShoppingList.findAndCountAll({
    where: whereClause,
    include: [
      {
        model: ShoppingListTask,
        as: 'tasks',
        attributes: ['id', 'name', 'quantity', 'is_purchased']
      }
    ],
    limit: limit,
    offset: offset,
    order: [['created_at', 'DESC']]
  });

  return {
    lists: rows,
    total: count,
    page: parseInt(page),
    totalPages: Math.ceil(count / limit)
  };
};

const getShoppingListById = async (id, requestingUserId) => {
  const list = await ShoppingList.findByPk(id, {
    include: [
      {
        model: ShoppingListTask,
        paranoid: false,  // Include deleted tasks for history
        include: [
          {
            model: Food,
            attributes: ['id', 'name', 'image_url', 'deleted_at'],
            paranoid: false,  // Include deleted foods for purchase history
            include: [
              { model: Unit, attributes: ['id', 'name', 'deleted_at'], paranoid: false },
              { model: Category, attributes: ['id', 'name', 'deleted_at'], paranoid: false }
            ]
          },
          {
            model: User,
            attributes: ['id', 'name', 'email', 'deleted_at'],
            paranoid: false  // Include deleted users
          }
        ]
      }
    ],
    order: [[ShoppingListTask, 'created_at', 'ASC']]
  });
  if (!list) {
    const error = new Error('Shopping list not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(list.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view this shopping list');
    error.statusCode = 403;
    throw error;
  }

  // Add is_deleted flags
  const listJson = list.toJSON();
  if (listJson.ShoppingListTasks) {
    listJson.ShoppingListTasks = listJson.ShoppingListTasks.map(task => {
      task.is_deleted = !!task.deleted_at;
      delete task.deleted_at;

      if (task.Food) {
        task.Food.is_deleted = !!task.Food.deleted_at;
        delete task.Food.deleted_at;

        if (task.Food.Unit) {
          task.Food.Unit.is_deleted = !!task.Food.Unit.deleted_at;
          delete task.Food.Unit.deleted_at;
        }
        if (task.Food.Category) {
          task.Food.Category.is_deleted = !!task.Food.Category.deleted_at;
          delete task.Food.Category.deleted_at;
        }
      }

      if (task.User) {
        task.User.is_deleted = !!task.User.deleted_at;
        delete task.User.deleted_at;
      }

      return task;
    });
  }

  return listJson;
};

const createTasks = async (listId, tasksData, requestingUserId) => {
  const list = await ShoppingList.findByPk(listId);
  if (!list) {
    const error = new Error('Shopping list not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(list.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to add tasks');
    error.statusCode = 403;
    throw error;
  }

  // Validate that shopping list is not deleted
  await validateNotDeleted(ShoppingList, listId, 'Shopping list');

  // Validate food items if provided
  const tasksArray = Array.isArray(tasksData) ? tasksData : [tasksData];
  for (const task of tasksArray) {
    if (task.food_id) {
      await validateNotDeleted(Food, task.food_id, 'Food');
    }
    if (task.assign_to_user_id) {
      await validateNotDeleted(User, task.assign_to_user_id, 'User');
    }
  }

  let newTasks;
  // If tasksData is array
  if (Array.isArray(tasksData)) {
    const tasksWithListId = tasksData.map(task => ({ ...task, shopping_list_id: listId }));
    newTasks = await ShoppingListTask.bulkCreate(tasksWithListId);
  } else {
    // Single task
    newTasks = await ShoppingListTask.create({ ...tasksData, shopping_list_id: listId });
  }

  // Notify group members
  const taskCount = Array.isArray(tasksData) ? tasksData.length : 1;
  NotificationService.sendToGroup(
    list.group_id,
    'New Shopping Task',
    `${taskCount} new task(s) added to list "${list.name}"`,
    { type: 'SHOPPING_LIST_UPDATE', listId: list.id, groupId: list.group_id },
    requestingUserId
  );

  return newTasks;
};

const getListOfTasks = async (shoppingListId, requestingUserId, page = 1, limit = 20, name = null, isPurchased = null) => {
  const list = await ShoppingList.findByPk(shoppingListId);
  if (!list) {
    const error = new Error('Shopping list not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(list.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view tasks');
    error.statusCode = 403;
    throw error;
  }

  const offset = (page - 1) * limit;

  const whereClause = { shopping_list_id: shoppingListId };
  if (name) {
    whereClause.name = { [Op.iLike]: `%${name}%` };
  }
  if (isPurchased !== null && isPurchased !== undefined) {
    whereClause.is_purchased = isPurchased === 'true'; // Convert query string to boolean
  }

  const { count, rows } = await ShoppingListTask.findAndCountAll({
    where: whereClause,
    paranoid: false,  // Include deleted tasks
    include: [
      {
        model: Food,
        attributes: ['id', 'name', 'image_url', 'deleted_at'],
        paranoid: false,
        include: [
          { model: Unit, attributes: ['id', 'name', 'deleted_at'], paranoid: false },
          { model: Category, attributes: ['id', 'name', 'deleted_at'], paranoid: false }
        ]
      },
      {
        model: User,
        attributes: ['id', 'name', 'email', 'deleted_at'],
        paranoid: false
      }
    ],
    limit: limit,
    offset: offset,
    order: [['created_at', 'ASC']]
  });

  // Add is_deleted flags
  const tasksWithFlags = rows.map(task => {
    const taskJson = task.toJSON();
    taskJson.is_deleted = !!taskJson.deleted_at;
    delete taskJson.deleted_at;

    if (taskJson.Food) {
      taskJson.Food.is_deleted = !!taskJson.Food.deleted_at;
      delete taskJson.Food.deleted_at;

      if (taskJson.Food.Unit) {
        taskJson.Food.Unit.is_deleted = !!taskJson.Food.Unit.deleted_at;
        delete taskJson.Food.Unit.deleted_at;
      }
      if (taskJson.Food.Category) {
        taskJson.Food.Category.is_deleted = !!taskJson.Food.Category.deleted_at;
        delete taskJson.Food.Category.deleted_at;
      }
    }

    if (taskJson.User) {
      taskJson.User.is_deleted = !!taskJson.User.deleted_at;
      delete taskJson.User.deleted_at;
    }

    return taskJson;
  });

  return {
    tasks: tasksWithFlags,
    total: count,
    page: parseInt(page),
    totalPages: Math.ceil(count / limit)
  };
};

const deleteTask = async (taskId, requestingUserId) => {
  const task = await ShoppingListTask.findByPk(taskId, { include: ShoppingList });
  if (!task) {
    const error = new Error('Task not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(task.ShoppingList.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to delete tasks');
    error.statusCode = 403;
    throw error;
  }

  await task.destroy();
  return { message: 'Task deleted successfully' };
};

const updateTask = async (taskId, data, requestingUserId) => {
  const task = await ShoppingListTask.findByPk(taskId, { include: ShoppingList });
  if (!task) {
    const error = new Error('Task not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(task.ShoppingList.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to update tasks');
    error.statusCode = 403;
    throw error;
  }

  await task.update(data);

  // Notify if task is completed or important update
  // For now, we notify on any update but we could filter
  if (data.is_purchased !== undefined) {
    const status = data.is_purchased ? 'completed' : 'uncompleted';
    // We should probably fetch the Task name again or use existing if not updated
    // But task object has old data before reload? 
    // Wait, update modifies the instance in place in Sequelize? Yes usually.
    NotificationService.sendToGroup(
      task.ShoppingList.group_id,
      'Shopping Task Updated',
      `Task "${task.name || 'Unknown'}" marked as ${status}`,
      { type: 'SHOPPING_TASK_UPDATE', listId: task.shopping_list_id, groupId: task.ShoppingList.group_id },
      requestingUserId
    );
  }

  return task;
};

module.exports = {
  createShoppingList,
  updateShoppingList,
  deleteShoppingList,
  getAllShoppingLists,
  getShoppingListById,
  createTasks,
  getListOfTasks,
  deleteTask,
  updateTask,
};
