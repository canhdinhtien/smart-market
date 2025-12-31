const Log = require('../models/Log');
const { getCurrentUser } = require('../utils/context');

const createLog = async ({ userId, action, details, entity, entityId }) => {
  try {
    // If userId is not explicitly provided, try to get it from the context
    if (!userId) {
      const currentUser = getCurrentUser();
      if (currentUser) {
        userId = currentUser.id;
      }
    }

    const log = await Log.create({
      user_id: userId,
      action,
      details,
      entity,
      entity_id: entityId,
    });
    return log;
  } catch (error) {
    console.error('Error creating log:', error);
  }
};

const getLogs = async ({ page = 1, limit = 10, userId }) => {
  const User = require('../models/User'); // Lazy load
  const offset = (page - 1) * limit;
  const where = {};
  if (userId) {
    where.user_id = userId;
  }

  const { count, rows } = await Log.findAndCountAll({
    where,
    limit: parseInt(limit),
    offset: parseInt(offset),
    order: [['timestamp', 'DESC']],
    include: [{
      model: User,
      attributes: ['id', 'email', 'name']
    }]
  });

  return {
    total: count,
    pages: Math.ceil(count / limit),
    currentPage: parseInt(page),
    logs: rows
  };
};

module.exports = {
  createLog,
  getLogs,
};
