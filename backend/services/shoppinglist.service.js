const ShoppingList = require('../models/ShoppingList');
const ShoppingListTask = require('../models/ShoppingListTask');
const Food = require('../models/Food');
const User = require('../models/User');
const Unit = require('../models/Unit');
const Category = require('../models/Category');
const groupService = require('./group.service');
const NotificationService = require('./notification.service');

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

const getAllShoppingLists = async (groupId, requestingUserId) => {
  const isMember = await groupService.isMember(groupId, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view shopping lists');
    error.statusCode = 403;
    throw error;
  }

  return await ShoppingList.findAll({
    where: { group_id: groupId },
    order: [['created_at', 'DESC']]
  });
};

const getShoppingListById = async (id, requestingUserId) => {
  const list = await ShoppingList.findByPk(id);
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
  return list;
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
  await NotificationService.sendToGroup(
    list.group_id,
    'New Shopping Task',
    `${taskCount} new task(s) added to list "${list.name}"`,
    { type: 'SHOPPING_LIST_UPDATE', listId: list.id, groupId: list.group_id },
    requestingUserId
  );

  return newTasks;
};

const getListOfTasks = async (shoppingListId, requestingUserId) => {
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

  return await ShoppingListTask.findAll({
    where: { shopping_list_id: shoppingListId },
    include: [
      {
        model: Food,
        attributes: ['id', 'name', 'image_url'],
        include: [
          { model: Unit, attributes: ['id', 'name'] },
          { model: Category, attributes: ['id', 'name'] }
        ]
      },
      {
        model: User,
        attributes: ['id', 'name', 'email']
      }
    ],
    order: [['created_at', 'ASC']]
  });
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
  if (data.is_completed !== undefined) {
    const status = data.is_completed ? 'completed' : 'uncompleted';
    // We should probably fetch the Task name again or use existing if not updated
    // But task object has old data before reload? 
    // Wait, update modifies the instance in place in Sequelize? Yes usually.
    await NotificationService.sendToGroup(
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
