'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        // 1. Fix Units table: Missing both created_at and updated_at
        await queryInterface.addColumn('units', 'created_at', {
            type: Sequelize.DATE,
            allowNull: false,
            defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
        });

        await queryInterface.addColumn('units', 'updated_at', {
            type: Sequelize.DATE,
            allowNull: false,
            defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
        });

        // 2. Fix Recipe Ingredients table: Missing updated_at (created_at exists)
        await queryInterface.addColumn('recipe_ingredients', 'updated_at', {
            type: Sequelize.DATE,
            allowNull: false,
            defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
        });
    },

    async down(queryInterface, Sequelize) {
        // Revert Recipe Ingredients
        await queryInterface.removeColumn('recipe_ingredients', 'updated_at');

        // Revert Units
        await queryInterface.removeColumn('units', 'created_at');
        await queryInterface.removeColumn('units', 'updated_at');
    }
};
