'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        // Drop the table if it exists to clean up old schema
        await queryInterface.dropTable('logs');

        await queryInterface.createTable('logs', {
            id: {
                allowNull: false,
                autoIncrement: true,
                primaryKey: true,
                type: Sequelize.INTEGER
            },
            user_id: {
                type: Sequelize.INTEGER,
                references: {
                    model: 'users',
                    key: 'id'
                },
                onUpdate: 'CASCADE',
                onDelete: 'SET NULL'
            },
            action: {
                type: Sequelize.STRING,
                allowNull: false
            },
            details: {
                type: Sequelize.TEXT
            },
            entity: {
                type: Sequelize.STRING
            },
            entity_id: {
                type: Sequelize.BIGINT
            },
            timestamp: {
                type: Sequelize.DATE,
                defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
            }
        });

        // Add index for faster querying by user and timestamp
        await queryInterface.addIndex('logs', ['user_id']);
        await queryInterface.addIndex('logs', ['timestamp']);
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.dropTable('logs');
    }
};
