const { Op } = require('sequelize');
const MealPlan = require('../models/MealPlan');
const Recipe = require('../models/Recipe');
const Food = require('../models/Food');

const createMealPlan = async (data) => {
  const { meal_type, date, group_id } = data;

  if (!meal_type || !date || !group_id) {
    const error = new Error('Meal type, date, and group ID are required');
    error.statusCode = 400;
    throw error;
  }

  // Validate meal_type
  if (!['sang', 'trua', 'toi'].includes(meal_type)) {
    const error = new Error('Invalid meal type. Must be sang, trua, or toi');
    error.statusCode = 400;
    throw error;
  }

  return await MealPlan.create(data);
};

const deletePlan = async (id) => {
  const deletedRows = await MealPlan.destroy({ where: { id } });
  if (deletedRows === 0) {
    const error = new Error('Meal plan not found');
    error.statusCode = 404;
    throw error;
  }
  return { message: 'Meal plan deleted successfully' };
};

const updateMealPlan = async (id, data) => {
  const plan = await MealPlan.findByPk(id);
  if (!plan) {
    const error = new Error('Meal plan not found');
    error.statusCode = 404;
    throw error;
  }

  if (data.meal_type && !['sang', 'trua', 'toi'].includes(data.meal_type)) {
    const error = new Error('Invalid meal type. Must be sang, trua, or toi');
    error.statusCode = 400;
    throw error;
  }

  await plan.update(data);
  return plan;
};

const getMealPlanByDate = async (groupId, startDate, endDate) => {
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

  return await MealPlan.findAll({
    where: whereClause,
    include: [
      { model: Recipe, attributes: ['id', 'name'] },
      { model: Food, attributes: ['id', 'name', 'image_url'] }
    ],
    order: [['date', 'ASC'], ['meal_type', 'ASC']]
  });
};

module.exports = {
  createMealPlan,
  deletePlan,
  updateMealPlan,
  getMealPlanByDate,
};
