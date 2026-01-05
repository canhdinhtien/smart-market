const mealplanService = require('../services/mealplan.service');

const createMealPlan = async (req, res, next) => {
  try {
    const plan = await mealplanService.createMealPlan(req.body, req.user.id);
    return res.status(201).json({
      message: 'Meal plan created successfully',
      data: plan
    });
  } catch (error) {
    next(error);
  }
};

const deletePlan = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await mealplanService.deletePlan(id, req.user.id);
    return res.json(result);
  } catch (error) {
    next(error);
  }
};

const updateMealPlan = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updated = await mealplanService.updateMealPlan(id, req.body, req.user.id);
    return res.json({
      message: 'Meal plan updated successfully',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

const getMealPlanByDate = async (req, res, next) => {
  try {
    const { groupId } = req.params;
    let { startDate, endDate, page, limit } = req.query;

    page = parseInt(page) || 1;
    limit = parseInt(limit) || 20;

    const result = await mealplanService.getMealPlanByDate(
      groupId,
      startDate,
      endDate,
      req.user.id,
      page,
      limit
    );

    return res.json(result);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createMealPlan,
  deletePlan,
  updateMealPlan,
  getMealPlanByDate,
};
