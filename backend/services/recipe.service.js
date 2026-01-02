const Recipe = require('../models/Recipe');
const RecipeIngredient = require('../models/RecipeIngredient');
const Food = require('../models/Food');
const Unit = require('../models/Unit');
const sequelize = require('../config/database');
const NotificationService = require('./notification.service');
const groupService = require('./group.service');

const createRecipe = async (data, requestingUserId) => {
  const { name, description, instructions, group_id, ingredients } = data;

  if (!name || !group_id) {
    const error = new Error('Name and Group ID are required');
    error.statusCode = 400;
    throw error;
  }

  const isMember = await groupService.isMember(group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to create a recipe');
    error.statusCode = 403;
    throw error;
  }

  const t = await sequelize.transaction();

  try {
    const recipe = await Recipe.create({
      name,
      description,
      instructions,
      group_id
    }, { transaction: t });

    if (ingredients && ingredients.length > 0) {
      const recipeIngredients = ingredients.map(ing => ({
        recipe_id: recipe.id,
        food_id: ing.food_id,
        quantity: ing.quantity,
        unit_id: ing.unit_id
      }));
      await RecipeIngredient.bulkCreate(recipeIngredients, { transaction: t });
    }

    await t.commit();

    NotificationService.sendToGroup(
      group_id,
      'New Recipe',
      `${name} added to group recipes`,
      { type: 'RECIPE_ADD', recipeId: recipe.id },
      requestingUserId
    );

    return await getRecipeById(recipe.id, requestingUserId);
  } catch (error) {
    await t.rollback();
    throw error;
  }
};

const updateRecipe = async (id, data, requestingUserId) => {
  const { name, description, instructions, ingredients } = data;

  const recipe = await Recipe.findByPk(id);
  if (!recipe) {
    const error = new Error('Recipe not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(recipe.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to update this recipe');
    error.statusCode = 403;
    throw error;
  }

  const t = await sequelize.transaction();

  try {
    await recipe.update({
      name,
      description,
      instructions
    }, { transaction: t });

    if (ingredients) {
      // Delete existing ingredients
      await RecipeIngredient.destroy({
        where: { recipe_id: id },
        transaction: t
      });

      // Add new ingredients
      if (ingredients.length > 0) {
        const recipeIngredients = ingredients.map(ing => ({
          recipe_id: id,
          food_id: ing.food_id,
          quantity: ing.quantity,
          unit_id: ing.unit_id
        }));
        await RecipeIngredient.bulkCreate(recipeIngredients, { transaction: t });
      }
    }

    await t.commit();

    NotificationService.sendToGroup(
      recipe.group_id,
      'Recipe Updated',
      `${name || recipe.name} has been updated`,
      { type: 'RECIPE_UPDATE', recipeId: id },
      requestingUserId
    );

    return await getRecipeById(id, requestingUserId);
  } catch (error) {
    await t.rollback();
    throw error;
  }
};

const deleteRecipe = async (id, requestingUserId) => {
  const recipe = await Recipe.findByPk(id);
  if (!recipe) {
    const error = new Error('Recipe not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(recipe.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to delete this recipe');
    error.statusCode = 403;
    throw error;
  }

  const t = await sequelize.transaction();
  try {
    // Delete ingredients first (if no cascade)
    await RecipeIngredient.destroy({ where: { recipe_id: id }, transaction: t });

    await recipe.destroy({ transaction: t });

    await t.commit();
    return { message: 'Recipe deleted successfully' };
  } catch (error) {
    await t.rollback();
    throw error;
  }
};

const getRecipesByFoodId = async (foodId, requestingUserId) => {
  const ingredients = await RecipeIngredient.findAll({
    where: { food_id: foodId },
    include: [{ model: Recipe }]
  });

  // Filter recipes where user is a member of the group
  const recipes = [];
  for (const ing of ingredients) {
    if (ing.Recipe) {
      const isMember = await groupService.isMember(ing.Recipe.group_id, requestingUserId);
      if (isMember) {
        recipes.push(ing.Recipe);
      }
    }
  }

  // Remove duplicates
  const uniqueRecipes = [];
  const map = new Map();
  for (const item of recipes) {
    if (!map.has(item.id)) {
      map.set(item.id, true);    // set any value to Map
      uniqueRecipes.push(item);
    }
  }

  return uniqueRecipes;
};

const getAllRecipesInGroup = async (groupId, requestingUserId) => {
  const isMember = await groupService.isMember(groupId, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view recipes');
    error.statusCode = 403;
    throw error;
  }

  return await Recipe.findAll({
    where: { group_id: groupId },
    order: [['created_at', 'DESC']]
  });
};

const getRecipeById = async (id, requestingUserId) => {
  const recipe = await Recipe.findByPk(id, {
    include: [
      {
        model: RecipeIngredient,
        include: [
          { model: Food, attributes: ['id', 'name', 'image_url'] },
          { model: Unit, attributes: ['id', 'name'] }
        ]
      }
    ]
  });

  if (!recipe) {
    const error = new Error('Recipe not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(recipe.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view this recipe');
    error.statusCode = 403;
    throw error;
  }

  return recipe;
};

module.exports = {
  createRecipe,
  updateRecipe,
  deleteRecipe,
  getRecipesByFoodId,
  getAllRecipesInGroup,
  getRecipeById,
};
