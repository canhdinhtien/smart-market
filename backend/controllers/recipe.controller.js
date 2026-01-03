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
    let { foodId, group_id, name, page, limit } = req.query;

    // Only require one of them
    if (!foodId && !group_id) {
      const error = new Error('Either foodId or group_id is required');
      error.statusCode = 400;
      throw error;
    }

    page = parseInt(page) || 1;
    limit = parseInt(limit) || 20;

    const result = await recipeService.getRecipesByFoodId(foodId, req.user.id, page, limit, group_id, name);

    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

/**
 * Get recipe recommendations matches based on fridge items
 */
const getRecipeRecommendations = async (req, res, next) => {
  try {
    const { group_id, page, limit } = req.query;

    if (!group_id) {
      return res.status(400).json({ message: 'group_id is required' });
    }

    const result = await recipeService.getRecipeRecommendations(
      group_id,
      req.user.id,
      parseInt(page) || 1,
      parseInt(limit) || 20
    );

    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createRecipe,
  updateRecipe,
  deleteRecipe,
  getRecipesByFoodId,
  getRecipeRecommendations
};
