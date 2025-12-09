const Recipe = require('../models/Recipe');
const RecipeIngredient = require('../models/RecipeIngredient');
const Food = require('../models/Food');
const Unit = require('../models/Unit');
const sequelize = require('../config/database');

const createRecipe = async (data) => {
  const { name, description, instructions, group_id, ingredients } = data;

  if (!name || !group_id) {
    const error = new Error('Name and Group ID are required');
    error.statusCode = 400;
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
    return await getRecipeById(recipe.id);
  } catch (error) {
    await t.rollback();
    throw error;
  }
};

const updateRecipe = async (id, data) => {
  const { name, description, instructions, ingredients } = data;

  const recipe = await Recipe.findByPk(id);
  if (!recipe) {
    const error = new Error('Recipe not found');
    error.statusCode = 404;
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
    return await getRecipeById(id);
  } catch (error) {
    await t.rollback();
    throw error;
  }
};

const deleteRecipe = async (id) => {
  const t = await sequelize.transaction();
  try {
    // Delete ingredients first (if no cascade)
    await RecipeIngredient.destroy({ where: { recipe_id: id }, transaction: t });

    const deletedRows = await Recipe.destroy({ where: { id }, transaction: t });

    if (deletedRows === 0) {
      const error = new Error('Recipe not found');
      error.statusCode = 404;
      throw error;
    }

    await t.commit();
    return { message: 'Recipe deleted successfully' };
  } catch (error) {
    await t.rollback();
    throw error;
  }
};

const getRecipesByFoodId = async (foodId) => {
  const ingredients = await RecipeIngredient.findAll({
    where: { food_id: foodId },
    include: [{ model: Recipe }]
  });

  // Extract unique recipes
  const recipes = ingredients.map(ing => ing.Recipe);
  // Remove duplicates if any (though one food per recipe usually, but just in case)
  // Actually RecipeIngredient PK is recipe_id + food_id, so one food appears once per recipe.
  return recipes;
};

const getAllRecipesInGroup = async (groupId) => {
  return await Recipe.findAll({
    where: { group_id: groupId },
    order: [['created_at', 'DESC']]
  });
};

const getRecipeById = async (id) => {
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
