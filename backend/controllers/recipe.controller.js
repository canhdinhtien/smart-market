const recipeService = require('../services/recipe.service');

/**
 * Create a recipe
 */
const createRecipe = async (req, res, next) => {
  try {
    const data = req.body;
    const recipe = await recipeService.createRecipe(data, req.user.id);

    res.status(201).json({
      message: 'Recipe created successfully',
      data: recipe
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update a recipe
 */
const updateRecipe = async (req, res, next) => {
  try {
    const { id } = req.params;
    const data = req.body;

    const updatedRecipe = await recipeService.updateRecipe(id, data, req.user.id);

    res.status(200).json({
      message: 'Recipe updated successfully',
      data: updatedRecipe
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete a recipe
 */
const deleteRecipe = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await recipeService.deleteRecipe(id, req.user.id);

    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

/**
 * Get recipes containing a specific food item
 */
const getRecipesByFoodId = async (req, res, next) => {
  try {
    const { foodId } = req.query;

    if (!foodId) {
      const error = new Error('foodId is required');
      error.statusCode = 400;
      throw error;
    }

    const recipes = await recipeService.getRecipesByFoodId(foodId);

    res.status(200).json({
      message: 'Recipes fetched successfully',
      data: recipes
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createRecipe,
  updateRecipe,
  deleteRecipe,
  getRecipesByFoodId
};
