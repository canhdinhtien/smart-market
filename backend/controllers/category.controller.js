const categoryService = require('../services/category.service');

const createCategory = async (req, res, next) => {
  try {
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({ message: 'Category name is required' });
    }
    const newCategory = await categoryService.createCategory({ name });
    res.status(201).json(newCategory);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    next(error);
  }
};

const getAllCategories = async (req, res, next) => {
  try {
    const categories = await categoryService.getAllCategories();
    res.status(200).json(categories);
  } catch (error) {
    next(error);
  }
};

const editCategoryByName = async (req, res, next) => {
  try {
    const { oldName, newName } = req.body;
    if (!newName) {
      return res.status(400).json({ message: 'New category name is required' });
    }
    const updatedCategory = await categoryService.editCategoryByName(oldName, newName);
    res.status(200).json(updatedCategory);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    next(error);
  }
};

const deleteCategoryByName = async (req, res, next) => {
  try {
    const { name } = req.body;
    const result = await categoryService.deleteCategoryByName(name);
    res.status(200).json(result);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    next(error);
  }
};

module.exports = {
  createCategory,
  getAllCategories,
  editCategoryByName,
  deleteCategoryByName,
};
