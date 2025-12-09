const shoppinglistService = require('../services/shoppinglist.service');

const createShoppingList = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });

    const newItem = await shoppinglistService.createShoppingList(req.body, userId);
    res.status(201).json(newItem);
  } catch (error) {
    if (error.statusCode) return res.status(error.statusCode).json({ message: error.message });
    next(error);
  }
};

const updateShoppingList = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!id) return res.status(400).json({ message: 'List ID is required' });

    const updatedItem = await shoppinglistService.updateShoppingList(id, req.body, userId);
    res.status(200).json(updatedItem);
  } catch (error) {
    if (error.statusCode) return res.status(error.statusCode).json({ message: error.message });
    next(error);
  }
};

const deleteShoppingList = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!id) return res.status(400).json({ message: 'List ID is required' });

    const result = await shoppinglistService.deleteShoppingList(id, userId);
    res.status(200).json(result);
  } catch (error) {
    if (error.statusCode) return res.status(error.statusCode).json({ message: error.message });
    next(error);
  }
};

const getAllShoppingLists = async (req, res, next) => {
  try {
    const { group_id } = req.query;
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!group_id) return res.status(400).json({ message: 'Group ID is required' });

    const result = await shoppinglistService.getAllShoppingLists(group_id, userId);
    res.status(200).json(result);
  } catch (error) {
    if (error.statusCode) return res.status(error.statusCode).json({ message: error.message });
    next(error);
  }
};

const getShoppingListById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!id) return res.status(400).json({ message: 'List ID is required' });

    const result = await shoppinglistService.getShoppingListById(id, userId);
    res.status(200).json(result);
  } catch (error) {
    if (error.statusCode) return res.status(error.statusCode).json({ message: error.message });
    next(error);
  }
};

const createTasks = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!id) return res.status(400).json({ message: 'List ID is required' });

    const newItem = await shoppinglistService.createTasks(id, req.body, userId);
    res.status(201).json(newItem);
  } catch (error) {
    if (error.statusCode) return res.status(error.statusCode).json({ message: error.message });
    next(error);
  }
};

const getListOfTasks = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!id) return res.status(400).json({ message: 'List ID is required' });

    const result = await shoppinglistService.getListOfTasks(id, userId);
    res.status(200).json(result);
  } catch (error) {
    if (error.statusCode) return res.status(error.statusCode).json({ message: error.message });
    next(error);
  }
};

const deleteTask = async (req, res, next) => {
  try {
    const { taskId } = req.params;
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!taskId) return res.status(400).json({ message: 'Task ID is required' });

    const result = await shoppinglistService.deleteTask(taskId, userId);
    res.status(200).json(result);
  } catch (error) {
    if (error.statusCode) return res.status(error.statusCode).json({ message: error.message });
    next(error);
  }
};

const updateTask = async (req, res, next) => {
  try {
    const { taskId } = req.params;
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!taskId) return res.status(400).json({ message: 'Task ID is required' });

    const updatedItem = await shoppinglistService.updateTask(taskId, req.body, userId);
    res.status(200).json(updatedItem);
  } catch (error) {
    if (error.statusCode) return res.status(error.statusCode).json({ message: error.message });
    next(error);
  }
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
