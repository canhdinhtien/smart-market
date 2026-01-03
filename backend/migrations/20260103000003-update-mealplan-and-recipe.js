'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        const transaction = await queryInterface.sequelize.transaction();
        try {
            await queryInterface.addColumn('recipes', 'image_url', {
                type: Sequelize.STRING,
                allowNull: true
            }, { transaction });

            await transaction.commit();
        } catch (error) {
            await transaction.rollback();
            throw error;
        }
    },

    async down(queryInterface, Sequelize) {
        const transaction = await queryInterface.sequelize.transaction();
        try {
            // 1. Add food_id back to meal_plans
            await queryInterface.addColumn('meal_plans', 'food_id', {
                type: Sequelize.INTEGER,
                references: {
                    model: 'foods',
                    key: 'id'
                }
            }, { transaction });

            // 2. Migrate data back? (Lossy if multiple foods exist per plan, just taking one)
            // This is a simplified rollback
            const [mealPlanFoods] = await queryInterface.sequelize.query(
                'SELECT meal_plan_id, food_id FROM meal_plan_foods',
                { transaction }
            );

            // Group by meal_plan_id and take the first food_id
            const mapping = {};
            mealPlanFoods.forEach(mpf => {
                if (!mapping[mpf.meal_plan_id]) {
                    mapping[mpf.meal_plan_id] = mpf.food_id;
                }
            });

            for (const [mealPlanId, foodId] of Object.entries(mapping)) {
                await queryInterface.sequelize.query(
                    `UPDATE meal_plans SET food_id = ${foodId} WHERE id = ${mealPlanId}`,
                    { transaction }
                );
            }

            // 3. Drop meal_plan_foods table
            await queryInterface.dropTable('meal_plan_foods', { transaction });

            // 4. Remove image_url from recipes
            await queryInterface.removeColumn('recipes', 'image_url', { transaction });

            await transaction.commit();
        } catch (error) {
            await transaction.rollback();
            throw error;
        }
    }
};
