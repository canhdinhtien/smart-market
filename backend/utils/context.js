const { AsyncLocalStorage } = require('async_hooks');
const context = new AsyncLocalStorage();

const runWithContext = (callback) => {
    return context.run({}, callback);
};

const getContext = () => {
    return context.getStore();
};

const getCurrentUser = () => {
    const store = context.getStore();
    return store ? store.user : null;
};

module.exports = {
    runWithContext,
    getContext,
    getCurrentUser,
    context
};
