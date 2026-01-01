'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        /**
         * 1. Create New Tables: consumptions, user_devices
         */
        await queryInterface.createTable('consumptions', {
            id: {
                type: Sequelize.INTEGER,
                primaryKey: true,
                autoIncrement: true,
                allowNull: false
            },
            fridge_item_id: {
                type: Sequelize.INTEGER,
                allowNull: false,
                references: { model: 'fridge_items', key: 'id' },
                onDelete: 'CASCADE'
            },
            quantity_consumed: {
                type: Sequelize.NUMERIC,
                allowNull: false
            },
            date_consumed: {
                type: Sequelize.DATEONLY,
                allowNull: false
            },
            user_id: {
                type: Sequelize.INTEGER,
                allowNull: true,
                references: { model: 'users', key: 'id' },
                onDelete: 'SET NULL'
            },
            note: {
                type: Sequelize.TEXT
            },
            group_id: {
                type: Sequelize.INTEGER,
                allowNull: false,
                references: { model: 'groups', key: 'id' },
                onDelete: 'CASCADE'
            },
            created_at: {
                type: Sequelize.DATE,
                defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
            },
            updated_at: {
                type: Sequelize.DATE,
                defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
            }
        });

        await queryInterface.createTable('user_devices', {
            id: {
                type: Sequelize.INTEGER,
                primaryKey: true,
                autoIncrement: true,
                allowNull: false
            },
            user_id: {
                type: Sequelize.INTEGER,
                allowNull: false,
                references: { model: 'users', key: 'id' },
                onDelete: 'CASCADE'
            },
            fcm_token: {
                type: Sequelize.STRING,
                allowNull: false,
                unique: true
            },
            platform: {
                type: Sequelize.ENUM('android', 'ios', 'web'),
                allowNull: false
            },
            device_id: {
                type: Sequelize.STRING,
                allowNull: true
            },
            is_active: {
                type: Sequelize.BOOLEAN,
                defaultValue: true
            },
            created_at: {
                type: Sequelize.DATE,
                allowNull: false,
                defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
            },
            updated_at: {
                type: Sequelize.DATE,
                allowNull: false,
                defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
            }
        });

        /**
         * 2. Update group_members: rename created_at to joined_at
         */
        await queryInterface.renameColumn('group_members', 'created_at', 'joined_at');

        /**
         * 3. Update fridge_items: add use_within_days, note, position
         */
        await queryInterface.addColumn('fridge_items', 'use_within_days', {
            type: Sequelize.INTEGER,
            allowNull: false,
            defaultValue: 7 // default safe value
        });
        await queryInterface.addColumn('fridge_items', 'note', {
            type: Sequelize.TEXT
        });
        await queryInterface.addColumn('fridge_items', 'position', {
            type: Sequelize.STRING
        });

        /**
         * 4. Update meal_plans: 
         *    - change meal_type to STRING (was ENUM)
         *    - add recipe_id, note
         */
        // PostGres doesn't easily convert ENUM to STRING implicitly with alterColumn sometimes, but let's try.
        // Ideally we drop the ENUM type if we change it to String.
        await queryInterface.changeColumn('meal_plans', 'meal_type', {
            type: Sequelize.STRING,
            allowNull: false
        });
        // Note: The old ENUM type 'enum_meal_plans_meal_type' might remain in Postgres, but that's usually fine.

        await queryInterface.addColumn('meal_plans', 'recipe_id', {
            type: Sequelize.INTEGER,
            references: { model: 'recipes', key: 'id' },
            onDelete: 'SET NULL'
        });
        await queryInterface.addColumn('meal_plans', 'note', {
            type: Sequelize.TEXT
        });

        /**
         * 5. Update recipes:
         *    - add name, description
         *    - remove food_id
         */
        // We add 'name' as allowNull: true first if there is existing data, but assuming development DB or we default it.
        // Since 'strict' mode, let's use a default or allow null first. Model says allowNull: false.
        // We will supply a default value to be safe.
        await queryInterface.addColumn('recipes', 'name', {
            type: Sequelize.STRING,
            allowNull: false,
            defaultValue: 'Untitled Recipe'
        });
        await queryInterface.addColumn('recipes', 'description', {
            type: Sequelize.TEXT
        });

        // Removing food_id. Warning: Data loss.
        await queryInterface.removeColumn('recipes', 'food_id');

        /**
         * 6. Update recipe_ingredients:
         *    - add unit_id
         */
        await queryInterface.addColumn('recipe_ingredients', 'unit_id', {
            type: Sequelize.INTEGER,
            references: { model: 'units', key: 'id' },
            onDelete: 'CASCADE',
            // If there is existing data, this will fail if we set allowNull: false without default.
            // We will set allowNull: true initially or default to first unit if known. 
            // For now, let's allow null in migration to be safe, though Model says allowNull: false.
            // Better: let's assume we can set it to 1 (if Unit 1 exists) or allow null. 
            // Safe bet: allow null for now. User can fix data.
            allowNull: true
        });

        /**
         * 7. Update shopping_lists:
         *    - add date, note
         */
        await queryInterface.addColumn('shopping_lists', 'date', {
            type: Sequelize.DATEONLY
        });
        await queryInterface.addColumn('shopping_lists', 'note', {
            type: Sequelize.TEXT
        });

        /**
         * 8. Update shopping_list_tasks:
         *    - add food_id, assign_to_user_id, note, is_purchased
         *    - remove name, is_completed
         */
        await queryInterface.addColumn('shopping_list_tasks', 'food_id', {
            type: Sequelize.INTEGER,
            references: { model: 'foods', key: 'id' },
            onDelete: 'CASCADE',
            allowNull: true // Cannot be null in Model, but we have no mapping from 'name', so must be null existing.
        });
        await queryInterface.addColumn('shopping_list_tasks', 'assign_to_user_id', {
            type: Sequelize.INTEGER,
            references: { model: 'users', key: 'id' },
            onDelete: 'SET NULL'
        });
        await queryInterface.addColumn('shopping_list_tasks', 'note', {
            type: Sequelize.TEXT
        });
        await queryInterface.addColumn('shopping_list_tasks', 'is_purchased', {
            type: Sequelize.BOOLEAN,
            defaultValue: false
        });

        await queryInterface.removeColumn('shopping_list_tasks', 'name');
        await queryInterface.removeColumn('shopping_list_tasks', 'is_completed');
    },

    async down(queryInterface, Sequelize) {
        /**
         * Revert changes (Best effort)
         */
        // 8. Revert shopping_list_tasks
        await queryInterface.addColumn('shopping_list_tasks', 'is_completed', {
            type: Sequelize.BOOLEAN,
            defaultValue: false
        });
        await queryInterface.addColumn('shopping_list_tasks', 'name', {
            type: Sequelize.STRING,
            allowNull: true // was false, but restoring data is hard
        });
        await queryInterface.removeColumn('shopping_list_tasks', 'is_purchased');
        await queryInterface.removeColumn('shopping_list_tasks', 'note');
        await queryInterface.removeColumn('shopping_list_tasks', 'assign_to_user_id');
        await queryInterface.removeColumn('shopping_list_tasks', 'food_id');

        // 7. Revert shopping_lists
        await queryInterface.removeColumn('shopping_lists', 'note');
        await queryInterface.removeColumn('shopping_lists', 'date');

        // 6. Revert recipe_ingredients
        await queryInterface.removeColumn('recipe_ingredients', 'unit_id');

        // 5. Revert recipes
        await queryInterface.addColumn('recipes', 'food_id', {
            type: Sequelize.INTEGER,
            references: { model: 'foods', key: 'id' },
            onDelete: 'CASCADE'
        });
        await queryInterface.removeColumn('recipes', 'description');
        await queryInterface.removeColumn('recipes', 'name');

        // 4. Revert meal_plans
        await queryInterface.removeColumn('meal_plans', 'note');
        await queryInterface.removeColumn('meal_plans', 'recipe_id');
        // Reverting type to ENUM is complex, requires casting.
        // Leaving as STRING or would need raw SQL to alter type back to using the enum type.

        // 3. Revert fridge_items
        await queryInterface.removeColumn('fridge_items', 'position');
        await queryInterface.removeColumn('fridge_items', 'note');
        await queryInterface.removeColumn('fridge_items', 'use_within_days');

        // 2. Revert group_members
        await queryInterface.renameColumn('group_members', 'joined_at', 'created_at');

        // 1. Drop tables
        await queryInterface.dropTable('user_devices');
        await queryInterface.dropTable('consumptions');
    }
};
