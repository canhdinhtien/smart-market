const Recipe = require('../models/Recipe');
const RecipeIngredient = require('../models/RecipeIngredient');
const Food = require('../models/Food');
const Unit = require('../models/Unit');
const Group = require('../models/Group');
const sequelize = require('../config/database');
const NotificationService = require('./notification.service');
const groupService = require('./group.service');
const { validateNotDeleted } = require('../utils/validateNotDeleted');
const { Op } = require('sequelize');
const { deleteImage } = require('../utils/imageUtils');

const createRecipe = async (data, requestingUserId) => {
  const { name, description, instructions, group_id, ingredients, image_url } = data;

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

  // Validate that group is not deleted
  await validateNotDeleted(Group, group_id, 'Group');

  // Validate ingredients if provided
  if (ingredients && ingredients.length > 0) {
    for (const ing of ingredients) {
      await validateNotDeleted(Food, ing.food_id, 'Food');
      await validateNotDeleted(Unit, ing.unit_id, 'Unit');
    }
  }

  const t = await sequelize.transaction();
  let recipe;

  try {
    recipe = await Recipe.create({
      name,
      image_url,
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
  } catch (error) {
    await t.rollback();
    throw error;
  }

  NotificationService.sendToGroup(
    group_id,
    'New Recipe',
    `${name} added to group recipes`,
    { type: 'RECIPE_ADD', recipeId: recipe.id },
    requestingUserId
  );

  return await getRecipeById(recipe.id, requestingUserId);
};

const updateRecipe = async (id, data, requestingUserId) => {
  let { name, description, instructions, ingredients, image_url } = data;

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

  const oldImageUrl = recipe.image_url;
  const t = await sequelize.transaction();

  try {
    image_url = image_url ? image_url : oldImageUrl;
    await recipe.update({
      name,
      image_url,
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

    // Check if image needs deletion after commit
    if (image_url && oldImageUrl && image_url !== oldImageUrl) {
      await deleteImage(oldImageUrl);
    }

  } catch (error) {
    await t.rollback();
    throw error;
  }

  NotificationService.sendToGroup(
    recipe.group_id,
    'Recipe Updated',
    `${name || recipe.name} has been updated`,
    { type: 'RECIPE_UPDATE', recipeId: id },
    requestingUserId
  );

  return await getRecipeById(id, requestingUserId);
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

  const imageUrl = recipe.image_url;
  const t = await sequelize.transaction();
  try {
    // Delete ingredients first (if no cascade)
    await RecipeIngredient.destroy({ where: { recipe_id: id }, transaction: t });

    await recipe.destroy({ transaction: t });

    await t.commit();

    if (imageUrl) {
      await deleteImage(imageUrl);
    }

    return { message: 'Recipe deleted successfully' };
  } catch (error) {
    await t.rollback();
    throw error;
  }
};

const getRecipesByFoodId = async (foodId, requestingUserId, page = 1, limit = 20, groupId = null, name = null) => {
  let recipes = [];
  let total = 0;

  const includeOptions = [
    {
      model: RecipeIngredient,
      paranoid: false,
      include: [
        { model: Food, attributes: ['id', 'name', 'image_url', 'deleted_at'], paranoid: false },
        { model: Unit, attributes: ['id', 'name', 'deleted_at'], paranoid: false }
      ]
    }
  ];

  // Case 1: Filter by group_id directly (general search)
  if (groupId) {
    const isMember = await groupService.isMember(groupId, requestingUserId);
    if (!isMember) {
      const error = new Error('Access denied: You must be a member of the group to view recipes');
      error.statusCode = 403;
      throw error;
    }

    const whereClause = { group_id: groupId };
    if (name) {
      whereClause.name = { [Op.iLike]: `%${name}%` };
    }

    const { count, rows } = await Recipe.findAndCountAll({
      where: whereClause,
      include: includeOptions,
      limit: limit,
      offset: (page - 1) * limit,
      order: [['created_at', 'DESC']],
      distinct: true // Important for correct count with includes
    });

    recipes = rows;
    total = count;
  } else {
    // Case 2: Filter by foodId
    // Optimization: Filter by user's groups FIRST + Index-Optimized Food Filter

    // 1. Get all group IDs for the user(
    const userGroupIds = await groupService.getAllUserGroupIds(requestingUserId);

    if (userGroupIds.length === 0) {
      return {
        recipes: [],
        total: 0,
        page: parseInt(page),
        totalPages: 0
      };
    }

    // 2. First, find candidate Recipe IDs efficiently.
    const matchingIngredients = await RecipeIngredient.findAll({
      where: { food_id: foodId },
      include: [{
        model: Recipe,
        attributes: [], // We don't need recipe data here
        where: { group_id: { [Op.in]: userGroupIds } },
        required: true
      }],
      attributes: ['recipe_id'],
      raw: true
    });

    const candidateRecipeIds = [...new Set(matchingIngredients.map(i => i.recipe_id))];

    if (candidateRecipeIds.length === 0) {
      return {
        recipes: [],
        total: 0,
        page: parseInt(page),
        totalPages: 0
      };
    }

    // 3. Fetch Full Details for these IDs
    const { count, rows } = await Recipe.findAndCountAll({
      where: {
        id: { [Op.in]: candidateRecipeIds },
        ...(name ? { name: { [Op.iLike]: `%${name}%` } } : {})
      },
      include: includeOptions, // Pure data fetching
      limit: limit,
      offset: (page - 1) * limit,
      order: [['created_at', 'DESC']],
      distinct: true
    });

    recipes = rows;
    total = count;
  }

  // Add is_deleted flags (Post-processing)
  const processedRecipes = recipes.map(recipe => {
    const recipeJson = recipe.toJSON();
    if (recipeJson.RecipeIngredients) {
      recipeJson.RecipeIngredients = recipeJson.RecipeIngredients.map(ingredient => {
        ingredient.is_deleted = !!ingredient.deleted_at;
        delete ingredient.deleted_at;

        if (ingredient.Food) {
          ingredient.Food.is_deleted = !!ingredient.Food.deleted_at;
          delete ingredient.Food.deleted_at;
        }
        if (ingredient.Unit) {
          ingredient.Unit.is_deleted = !!ingredient.Unit.deleted_at;
          delete ingredient.Unit.deleted_at;
        }

        return ingredient;
      });
    }
    return recipeJson;
  });

  return {
    recipes: processedRecipes,
    total: total,
    page: parseInt(page),
    totalPages: Math.ceil(total / limit)
  };
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
        paranoid: false,  // Include deleted ingredients
        include: [
          { model: Food, attributes: ['id', 'name', 'image_url', 'deleted_at'], paranoid: false },
          { model: Unit, attributes: ['id', 'name', 'deleted_at'], paranoid: false }
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

  // Add is_deleted flags
  const recipeJson = recipe.toJSON();
  if (recipeJson.RecipeIngredients) {
    recipeJson.RecipeIngredients = recipeJson.RecipeIngredients.map(ingredient => {
      ingredient.is_deleted = !!ingredient.deleted_at;
      delete ingredient.deleted_at;

      if (ingredient.Food) {
        ingredient.Food.is_deleted = !!ingredient.Food.deleted_at;
        delete ingredient.Food.deleted_at;
      }
      if (ingredient.Unit) {
        ingredient.Unit.is_deleted = !!ingredient.Unit.deleted_at;
        delete ingredient.Unit.deleted_at;
      }

      return ingredient;
    });
  }

  return recipeJson;
};

const getRecipeRecommendations = async (
  groupId,
  requestingUserId,
  page = 1,
  limit = 20
) => {
  const FridgeItem = require('../models/FridgeItem');

  // 1. Authorization (fail fast)
  const isMember = await groupService.isMember(groupId, requestingUserId);
  if (!isMember) {
    const error = new Error(
      'Access denied: You must be a member of the group to view recommendations'
    );
    error.statusCode = 403;
    throw error;
  }

  // 2. Get fridge food IDs (Set for O(1) lookups)
  const fridgeItems = await FridgeItem.findAll({
    where: { group_id: groupId },
    attributes: ['food_id'],
    raw: true
  });

  if (!fridgeItems.length) {
    return {
      recommendations: [],
      total: 0,
      page,
      totalPages: 0
    };
  }

  const fridgeFoodIds = Array.from(new Set(fridgeItems.map(i => i.food_id)));
  const fridgeFoodIdsSet = new Set(fridgeFoodIds);

  // 3. Pre-optimization: Get IDs of recipes that have AT LEAST one matching ingredient
  // This drastically reduces the search space compared to fetching all recipes
  const matchingIngredients = await RecipeIngredient.findAll({
    where: { food_id: { [Op.in]: fridgeFoodIds } },
    attributes: ['recipe_id'],
    raw: true,
    group: ['recipe_id'] // Ensure distinct recipe IDs
  });

  if (!matchingIngredients.length) {
    return {
      recommendations: [],
      total: 0,
      page,
      totalPages: 0
    };
  }

  const potentialRecipeIds = matchingIngredients.map(i => i.recipe_id);

  // 4. Fetch full details ONLY for potential matches
  const recipes = await Recipe.findAll({
    where: {
      group_id: groupId,
      id: { [Op.in]: potentialRecipeIds }
    },
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

  // 5. Score recipes
  const scoredRecipes = [];

  for (const recipe of recipes) {
    const recipeJson = recipe.toJSON();
    const ingredients = recipeJson.RecipeIngredients ?? [];

    if (!ingredients.length) continue;

    let matchedIngredientsCount = 0;
    const missingIngredients = [];

    for (const ing of ingredients) {
      ing.in_fridge = fridgeFoodIdsSet.has(ing.food_id);
      if (ing.in_fridge) {
        matchedIngredientsCount++;
      } else {
        // Collect detailed missing ingredient info
        missingIngredients.push({
          food_id: ing.food_id,
          name: ing.Food ? ing.Food.name : 'Unknown Food',
          image_url: ing.Food ? ing.Food.image_url : null,
          quantity: ing.quantity,
          unit: ing.Unit ? ing.Unit.name : null
        });
      }
    }

    // Should theoretically be > 0 due to pre-filtering, but safe check
    if (matchedIngredientsCount === 0) continue;

    const matchPercentage = Number(
      ((matchedIngredientsCount / ingredients.length) * 100).toFixed(1)
    );

    scoredRecipes.push({
      ...recipeJson,
      matchPercentage,
      matchedIngredientsCount,
      missingIngredientsCount: missingIngredients.length,
      missingIngredients // Detailed list restored
    });
  }

  // 6. Sort: Match % DESC -> Matched Count DESC
  scoredRecipes.sort((a, b) =>
    b.matchPercentage - a.matchPercentage ||
    b.matchedIngredientsCount - a.matchedIngredientsCount
  );

  // 7. Pagination
  const total = scoredRecipes.length;
  const startIndex = (page - 1) * limit;

  return {
    recommendations: scoredRecipes.slice(startIndex, startIndex + limit),
    total,
    page,
    totalPages: Math.ceil(total / limit)
  };
};

module.exports = {
  createRecipe,
  updateRecipe,
  deleteRecipe,
  getRecipesByFoodId,
  getAllRecipesInGroup,
  getRecipeById,
  getRecipeRecommendations,
};
