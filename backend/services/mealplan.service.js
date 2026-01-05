const { Op } = require('sequelize');
const MealPlan = require('../models/MealPlan');
const Recipe = require('../models/Recipe');
const Food = require('../models/Food');
const Group = require('../models/Group');
const FridgeItem = require('../models/FridgeItem');
const RecipeIngredient = require('../models/RecipeIngredient');
const NotificationService = require('./notification.service');
const groupService = require('./group.service');
const { validateNotDeleted } = require('../utils/validateNotDeleted');

const createMealPlan = async (data, requestingUserId) => {
  const { meal_type, date, group_id, recipe_id, food_id } = data;

  if (!meal_type || !date || !group_id) {
    const error = new Error('Meal type, date, and group ID are required');
    error.statusCode = 400;
    throw error;
  }

  const isMember = await groupService.isMember(group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to create a meal plan');
    error.statusCode = 403;
    throw error;
  }

  // Validate meal_type
  if (!['sang', 'trua', 'toi'].includes(meal_type)) {
    const error = new Error('Invalid meal type. Must be sang, trua, or toi');
    error.statusCode = 400;
    throw error;
  }

  // Validate that referenced entities are not deleted
  await validateNotDeleted(Group, group_id, 'Group');
  if (recipe_id) {
    const recipe = await Recipe.findByPk(recipe_id, {
      include: [{
        model: RecipeIngredient,
        include: [Food]
      }]
    });

    if (!recipe) {
      const error = new Error('Recipe not found');
      error.statusCode = 404;
      throw error;
    }

    if (recipe.deleted_at) {
      const error = new Error('Recipe has been deleted');
      error.statusCode = 400;
      throw error;
    }

    // Check ingredients availability in Fridge
    if (recipe.RecipeIngredients && recipe.RecipeIngredients.length > 0) {
      // 1. Collect all food IDs from ingredients
      const ingredientFoodIds = recipe.RecipeIngredients.map(ing => ing.food_id);

      // 2. Batch fetch all relevant fridge items in one query
      const allFridgeItems = await FridgeItem.findAll({
        where: {
          group_id: group_id,
          food_id: {
            [Op.in]: ingredientFoodIds
          }
        }
      });

      // 3. Group fridge items by food_id for easy lookup
      // Map<food_id, FridgeItem[]>
      const fridgeItemsMap = new Map();
      for (const item of allFridgeItems) {
        if (!fridgeItemsMap.has(item.food_id)) {
          fridgeItemsMap.set(item.food_id, []);
        }
        fridgeItemsMap.get(item.food_id).push(item);
      }

      for (const ingredient of recipe.RecipeIngredients) {
        // Validate Unit Consistency FIRST
        const foodUnitId = ingredient.Food ? ingredient.Food.unit_id : null;

        if (foodUnitId && ingredient.unit_id && foodUnitId !== ingredient.unit_id) {
          const foodName = ingredient.Food ? ingredient.Food.name : `Food ID ${ingredient.food_id}`;
          const error = new Error(`Unit mismatch for ${foodName}. Recipe requires unit ${ingredient.unit_id}, but food is stored in unit ${foodUnitId}. Automatic conversion not supported.`);
          error.statusCode = 400;
          throw error;
        }

        // Get matching fridge items from map
        const fridgeItems = fridgeItemsMap.get(ingredient.food_id) || [];

        // Calculate total available quantity
        const totalAvailable = fridgeItems.reduce((sum, item) => sum + Number(item.quantity), 0);

        if (totalAvailable < ingredient.quantity) {
          const foodName = ingredient.Food ? ingredient.Food.name : `Food ID ${ingredient.food_id}`;
          const error = new Error(`Insufficient quantity for ingredient ${foodName}. Required: ${ingredient.quantity}, Available: ${totalAvailable}`);
          error.statusCode = 400;
          throw error;
        }
      }
    }
  }
  if (food_id) {
    await validateNotDeleted(Food, food_id, 'Food');

    // Check availability in Fridge
    const fridgeItem = await FridgeItem.findOne({
      where: {
        group_id: group_id,
        food_id: food_id
      }
    });

    if (!fridgeItem) {
      const error = new Error('Food item not found in the group fridge');
      error.statusCode = 400;
      throw error;
    }

    if (fridgeItem.quantity <= 0) {
      const error = new Error('Food item in fridge is out of stock');
      error.statusCode = 400;
      throw error;
    }

    // Optional: check if requested quantity is available if provided in data
    // Assuming data might have a 'quantity' field for the meal plan itself? 
    // The MealPlan model doesn't explicitly have a quantity field visible in the snippet (only note, meal_type, etc.), 
    // but if it were passed:
    if (data.quantity && fridgeItem.quantity < data.quantity) {
      const error = new Error(`Insufficient quantity in fridge. Available: ${fridgeItem.quantity}`);
      error.statusCode = 400;
      throw error;
    }
  }

  const plan = await MealPlan.create(data);

  NotificationService.sendToGroup(
    group_id,
    'New Meal Plan',
    `Meal plan added for ${date} (${meal_type})`,
    { type: 'MEAL_PLAN_ADD', planId: plan.id },
    requestingUserId
  );

  return plan;
};

const deletePlan = async (id, requestingUserId) => {
  const plan = await MealPlan.findByPk(id);
  if (!plan) {
    const error = new Error('Meal plan not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(plan.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to delete this meal plan');
    error.statusCode = 403;
    throw error;
  }

  await plan.destroy();
  return { message: 'Meal plan deleted successfully' };
};

const updateMealPlan = async (id, data, requestingUserId) => {
  const plan = await MealPlan.findByPk(id);
  if (!plan) {
    const error = new Error('Meal plan not found');
    error.statusCode = 404;
    throw error;
  }

  const isMember = await groupService.isMember(plan.group_id, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to update this meal plan');
    error.statusCode = 403;
    throw error;
  }

  if (data.meal_type && !['sang', 'trua', 'toi'].includes(data.meal_type)) {
    const error = new Error('Invalid meal type. Must be sang, trua, or toi');
    error.statusCode = 400;
    throw error;
  }

  await plan.update(data);

  NotificationService.sendToGroup(
    plan.group_id,
    'Meal Plan Updated',
    `Meal plan for ${plan.date} updated`,
    { type: 'MEAL_PLAN_UPDATE', planId: plan.id },
    requestingUserId
  );

  return plan;
};

const getMealPlanByDate = async (groupId, startDate, endDate, requestingUserId, page = 1, limit = 20) => {
  const isMember = await groupService.isMember(groupId, requestingUserId);
  if (!isMember) {
    const error = new Error('Access denied: You must be a member of the group to view meal plans');
    error.statusCode = 403;
    throw error;
  }

  const whereClause = {
    group_id: groupId
  };

  if (startDate && endDate) {
    whereClause.date = {
      [Op.between]: [startDate, endDate]
    };
  } else if (startDate) {
    whereClause.date = startDate;
  }

  const offset = (page - 1) * limit;

  const { count, rows } = await MealPlan.findAndCountAll({
    where: whereClause,
    paranoid: false,  // Include deleted meal plans for history
    include: [
      {
        model: Recipe,
        attributes: ['id', 'name', 'deleted_at'],
        paranoid: false  // Include deleted recipes for historical meal plans
      },
      {
        model: Food,
        attributes: ['id', 'name', 'image_url', 'deleted_at'],
        paranoid: false  // Include deleted foods for historical meal plans
      }
    ],
    order: [['date', 'ASC'], ['meal_type', 'ASC']],
    limit: limit,
    offset: offset
  });

  // Add is_deleted flags
  const plansWithFlags = rows.map(plan => {
    const planJson = plan.toJSON();
    planJson.is_deleted = !!planJson.deleted_at;
    delete planJson.deleted_at;

    if (planJson.Recipe) {
      planJson.Recipe.is_deleted = !!planJson.Recipe.deleted_at;
      delete planJson.Recipe.deleted_at;
    }

    if (planJson.Food) {
      planJson.Food.is_deleted = !!planJson.Food.deleted_at;
      delete planJson.Food.deleted_at;
    }

    return planJson;
  });

  return {
    plans: plansWithFlags,
    total: count,
    page: parseInt(page),
    totalPages: Math.ceil(count / limit)
  };
};

module.exports = {
  createMealPlan,
  deletePlan,
  updateMealPlan,
  getMealPlanByDate,
};
