'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        // Try to remove based on standard naming convention for Postgres
        // Usually 'users_name_key' or 'users_name_unique'
        try {
            await queryInterface.removeConstraint('users', 'users_name_key');
        } catch (error) {
            console.warn('Could not remove constraint users_name_key, checking other potential names or if it exists.');
            // Fallback or just ignore if it doesn't exist (though it should)
        }

        // Explicitly change column to ensure metadata is updated if needed by Sequelize
        await queryInterface.changeColumn('users', 'name', {
            type: Sequelize.STRING(100),
            allowNull: false,
            unique: false
        });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.changeColumn('users', 'name', {
            type: Sequelize.STRING(100),
            allowNull: false,
            unique: true
        });
    }
};
