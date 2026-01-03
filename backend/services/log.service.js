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
    include: [{
      model: User,
      attributes: ['id', 'name', 'email', 'deleted_at'],
      paranoid: false  // Include deleted users for audit trail
    }],
    order: [['timestamp', 'DESC']],
    limit: limit,
    offset: offset
  });

  // Add is_deleted flag to user data
  const logsWithDeletedFlag = rows.map(log => {
    const logJson = log.toJSON();
    if (logJson.User) {
      logJson.User.is_deleted = !!logJson.User.deleted_at;
      delete logJson.User.deleted_at; // Remove timestamp, keep only flag
    }
    return logJson;
  });

  return {
    logs: logsWithDeletedFlag,
    total: count,
    page: parseInt(page),
    totalPages: Math.ceil(count / limit)
  };
};

module.exports = {
  createLog,
  getLogs,
};
