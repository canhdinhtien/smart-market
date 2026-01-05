'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.addColumn('recipes', 'group_id', {
            type: Sequelize.INTEGER,
            // We set allowNull to true initially to avoid issues if there's existing data without a group.
            // Ideally this should be false as per model, but safety first for migrations.
            allowNull: true,
            references: {
                model: 'groups',
                key: 'id'
            },
            onDelete: 'CASCADE'
        });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.removeColumn('recipes', 'group_id');
    }
};
