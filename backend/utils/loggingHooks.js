const logService = require('../services/log.service');
const { getCurrentUser } = require('../utils/context');

const addLoggingHooks = (Model, entityName) => {
    Model.addHook('afterCreate', async (instance, options) => {
        try {
            const currentUser = getCurrentUser();
            // Use context user, or fallback to options.userId if provided manually, or instance.id if it's the User model being created
            const actorId = (currentUser && currentUser.id) || options.userId || (entityName === 'User' ? instance.id : null);

            if (actorId) {
                await logService.createLog({
                    userId: actorId,
                    action: 'CREATE',
                    details: `${entityName} created`,
                    entity: entityName,
                    entityId: instance.id
                });
            }
        } catch (err) {
            console.error(`Error in afterCreate hook for ${entityName}:`, err);
        }
    });

    Model.addHook('afterUpdate', async (instance, options) => {
        try {
            const currentUser = getCurrentUser();
            const actorId = (currentUser && currentUser.id) || options.userId || (entityName === 'User' ? instance.id : null);

            if (actorId) {
                await logService.createLog({
                    userId: actorId,
                    action: 'UPDATE',
                    details: `${entityName} updated`,
                    entity: entityName,
                    entityId: instance.id
                });
            }
        } catch (err) {
            console.error(`Error in afterUpdate hook for ${entityName}:`, err);
        }
    });

    Model.addHook('afterDestroy', async (instance, options) => {
        try {
            const currentUser = getCurrentUser();
            const actorId = (currentUser && currentUser.id) || options.userId || (entityName === 'User' ? instance.id : null);

            if (actorId) {
                await logService.createLog({
                    userId: actorId,
                    action: 'DELETE',
                    details: `${entityName} deleted`,
                    entity: entityName,
                    entityId: instance.id
                });
            }
        } catch (err) {
            console.error(`Error in afterDestroy hook for ${entityName}:`, err);
        }
    });
};

module.exports = {
    addLoggingHooks
};
