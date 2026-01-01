'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        const tableDescription = await queryInterface.describeTable('categories');

        if (tableDescription.createdAt) {
            await queryInterface.renameColumn('categories', 'createdAt', 'created_at');
        }
        if (tableDescription.updatedAt) {
            await queryInterface.renameColumn('categories', 'updatedAt', 'updated_at');
        }
    },

    async down(queryInterface, Sequelize) {
        const tableDescription = await queryInterface.describeTable('categories');

        if (tableDescription.created_at) {
            await queryInterface.renameColumn('categories', 'created_at', 'createdAt');
        }
        if (tableDescription.updated_at) {
            await queryInterface.renameColumn('categories', 'updated_at', 'updatedAt');
        }
    }
};
