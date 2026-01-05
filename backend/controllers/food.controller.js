const foodService = require('../services/food.service');

const createFood = async (req, res, next) => {
  try {
    const foodData = req.body;
    if (req.file) {
      foodData.image_url = req.file.path;
    }
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!foodData.name || !foodData.group_id) {
      return res.status(400).json({ message: 'Name and group_id are required' });
    }
    const newFood = await foodService.createFood(foodData, userId);
    res.status(201).json(newFood);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    next(error);
  }
};

const updateFood = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    if (req.file) {
      updateData.image_url = req.file.path;
    }
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!id) {
      return res.status(400).json({ message: 'Food ID is required' });
    }
    const updatedFood = await foodService.updateFood(id, updateData, userId);
    res.status(200).json(updatedFood);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    next(error);
  }
};

const deleteFood = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!id) {
      return res.status(400).json({ message: 'Food ID is required' });
    }
    const result = await foodService.deleteFood(id, userId);
    res.status(200).json(result);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    next(error);
  }
};

const getAllFoodsInGroup = async (req, res, next) => {
  try {
    const { group_id } = req.query;
    let { page, limit, name, category_id } = req.query;
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!group_id) {
      return res.status(400).json({ message: 'Group ID is required' });
    }

    page = parseInt(page) || 1;
    limit = parseInt(limit) || 20;

    const foods = await foodService.getAllFoodsInGroup(group_id, userId, page, limit, name, category_id);
    res.status(200).json(foods);
  } catch (error) {
    next(error);
  }
};

const getUnits = async (req, res, next) => {
  try {
    const units = await foodService.getUnits();
    res.status(200).json(units);
  } catch (error) {
    next(error);
  }
};

const getCategories = async (req, res, next) => {
  try {
    const categories = await foodService.getCategories();
    res.status(200).json(categories);
  } catch (error) {
    next(error);
  }
};

const getFoodById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    if (!id) return res.status(400).json({ message: 'Food ID is required' });

    const food = await foodService.getFoodById(id, userId);
    res.status(200).json(food);
  } catch (error) {
    if (error.statusCode) return res.status(error.statusCode).json({ message: error.message });
    next(error);
  }
};

module.exports = {
  createFood,
  updateFood,
  deleteFood,
  getAllFoodsInGroup,
  getUnits,
  getCategories,
  getFoodById,
};
