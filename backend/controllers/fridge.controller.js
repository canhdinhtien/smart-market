const fridgeService = require('../services/fridge.service');

const createFridgeItem = async (req, res, next) => {
  try {
    const data = req.body;
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });

    if (!data.food_id || !data.group_id) {
      return res.status(400).json({ message: 'Food ID and Group ID are required' });
    }
    const newItem = await fridgeService.createFridgeItem(data, userId);
    res.status(201).json(newItem);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    next(error);
  }
};

const updateFridgeItem = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!id) {
      return res.status(400).json({ message: 'Fridge item ID is required' });
    }
    const updatedItem = await fridgeService.updateFridgeItem(id, updateData, userId);
    res.status(200).json(updatedItem);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    next(error);
  }
};

const deleteFridgeItem = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!id) {
      return res.status(400).json({ message: 'Fridge item ID is required' });
    }
    const result = await fridgeService.deleteFridgeItem(id, userId);
    res.status(200).json(result);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    next(error);
  }
};

const getAllFridgeItems = async (req, res, next) => {
  try {
    const { group_id } = req.query;
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!group_id) {
      return res.status(400).json({ message: 'Group ID is required' });
    }
    const items = await fridgeService.getAllFridgeItems(group_id, userId);
    res.status(200).json(items);
  } catch (error) {
    next(error);
  }
};

// TODO: This function is not currently exposed in routes
const getFridgeItemsByFoodName = async (req, res, next) => {
  try {
    const { name, group_id } = req.query;
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!name || !group_id) {
      return res.status(400).json({ message: 'Food name and Group ID are required' });
    }

    const items = await fridgeService.getFridgeItemsByFoodName(group_id, name, userId);
    res.status(200).json(items);
  } catch (error) {
    if (error.statusCode) return res.status(error.statusCode).json({ message: error.message });
    next(error);
  }
};

const getFridgeItemById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!id) return res.status(400).json({ message: 'Fridge item ID is required' });

    const item = await fridgeService.getFridgeItemById(id, userId);
    res.status(200).json(item);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    next(error);
  }
};

module.exports = {
  createFridgeItem,
  updateFridgeItem,
  deleteFridgeItem,
  getAllFridgeItems,
  getFridgeItemById,
};
