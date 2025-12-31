const logService = require('../services/log.service');

const getLogs = async (req, res, next) => {
  try {
    const { page, limit, userId } = req.query;
    const result = await logService.getLogs({ page, limit, userId });
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getLogs,
};
