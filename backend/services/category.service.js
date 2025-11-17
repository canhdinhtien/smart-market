const Category = require('../models/Category');

const createCategory = async (categoryData) => {
  const { name } = categoryData;
  const existingCategory = await Category.findOne({ where: { name } });
  if (existingCategory) {
    const error = new Error('Category already exists');
    error.statusCode = 409;
    throw error;
  }
  const newCategory = await Category.create({ name });
  return newCategory;
};

const getAllCategories = async () => {
  return await Category.findAll();
};

const editCategoryByName = async (categoryName, newCategoryName) => {
  const existingCategory = await Category.findOne({ where: { name: newCategoryName } });
  if (existingCategory) {
    const error = new Error('Category with that name already exists');
    error.statusCode = 409;
    throw error;
  }

  const [updatedRows] = await Category.update(
    { name: newCategoryName },
    { where: { name: categoryName } }
  );

  if (updatedRows === 0) {
    const error = new Error('Category not found');
    error.statusCode = 404;
    throw error;
  }

  const updatedCategory = await Category.findOne({ where: { name: newCategoryName } });
  return updatedCategory;
};

const deleteCategoryByName = async (categoryName) => {
  const deletedRows = await Category.destroy({ where: { name: categoryName } });
  if (deletedRows === 0) {
    const error = new Error('Category not found');
    error.statusCode = 404;
    throw error;
  }
  return { message: 'Category deleted successfully' };
};

module.exports = {
  createCategory,
  getAllCategories,
  editCategoryByName,
  deleteCategoryByName,
};
