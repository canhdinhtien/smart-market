const { context } = require('../utils/context');

const contextMiddleware = (req, res, next) => {
    context.run({}, () => {
        next();
    });
};

module.exports = { contextMiddleware };
