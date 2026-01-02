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

const getLogs = async (page = 1, limit = 20, userId = null) => {
  const User = require('../models/User');
  const offset = (page - 1) * limit;
  const where = {};
  if (userId) {
    where.user_id = userId;
  }

  const { count, rows } = await Log.findAndCountAll({
    where,
    include: [{ model: User, attributes: ['id', 'name', 'email'] }],
    order: [['created_at', 'DESC']],
    limit: limit,
    offset: offset
  });

  return {
    logs: rows,
    total: count,
    page: parseInt(page),
    totalPages: Math.ceil(count / limit)
  };
};

module.exports = {
  createLog,
  getLogs,
};
