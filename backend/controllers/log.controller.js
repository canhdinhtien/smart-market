const logService = require('../services/log.service');

const getLogs = async (req, res, next) => {
  try {
    let { page, limit } = req.query;
    page = parseInt(page) || 1;
    limit = parseInt(limit) || 20;

    const logs = await logService.getLogs(page, limit);
    res.json(logs);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getLogs,
};
