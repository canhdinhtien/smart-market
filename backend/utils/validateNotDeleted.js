/**
 * Validate that an entity exists and is not soft deleted
 * @param {Model} model - Sequelize model
 * @param {number} id - Entity ID
 * @param {string} entityName - Human-readable entity name for error messages
 * @returns {Promise<Object>} The entity if valid
 * @throws {Error} If entity not found or is deleted
 */
const validateNotDeleted = async (model, id, entityName) => {
    // Query with paranoid: false to check if entity exists at all
    const entity = await model.findByPk(id, { paranoid: false });

    if (!entity) {
        const error = new Error(`${entityName} not found`);
        error.statusCode = 404;
        throw error;
    }

    if (entity.deleted_at) {
        const error = new Error(`Cannot use deleted ${entityName.toLowerCase()}`);
        error.statusCode = 400;
        throw error;
    }

    return entity;
};

module.exports = { validateNotDeleted };
