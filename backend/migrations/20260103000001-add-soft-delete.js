'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        // Tables that will have soft delete enabled
        // NOTE: logs and consumptions are intentionally excluded
        // - logs: immutable audit trail, should never be deleted
        // - consumptions: transactional data, hard delete is appropriate
        const tables = [
            'users',
            'groups',
            'categories',
            'units',
            'foods',
            'fridge_items',
            'recipes',
            'recipe_ingredients',
            'meal_plans',
            'shopping_lists',
            'shopping_list_tasks'
        ];

        // Add deleted_at column to each table
        for (const table of tables) {
            await queryInterface.addColumn(table, 'deleted_at', {
                type: Sequelize.DATE,
                allowNull: true,
                defaultValue: null
            });

            // Add index for better query performance
            await queryInterface.addIndex(table, ['deleted_at'], {
                name: `${table}_deleted_at_idx`
            });
        }
    },

    async down(queryInterface, Sequelize) {
        const tables = [
            'users',
            'groups',
            'categories',
            'units',
            'foods',
            'fridge_items',
            'recipes',
            'recipe_ingredients',
            'meal_plans',
            'shopping_lists',
            'shopping_list_tasks'
        ];

        // Remove indexes and columns
        for (const table of tables) {
            await queryInterface.removeIndex(table, `${table}_deleted_at_idx`);
            await queryInterface.removeColumn(table, 'deleted_at');
        }
    }
};
