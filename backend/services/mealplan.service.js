const { Op } = require('sequelize');
const MealPlan = require('../models/MealPlan');
const Recipe = require('../models/Recipe');
const Food = require('../models/Food');
const Group = require('../models/Group');
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
    await validateNotDeleted(Recipe, recipe_id, 'Recipe');
  }
  if (food_id) {
    await validateNotDeleted(Food, food_id, 'Food');
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
