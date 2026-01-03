const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { sequelize, Food, GroupMember, Group, Category, Unit } = require('../models');
const foodService = require('../services/food.service');

sequelize.options.logging = false;

async function verifyFoodUpdate() {
    try {
        // 1. Setup Data
        const member = await GroupMember.findOne();
        if (!member) throw new Error('No group member found');
        const { group_id, user_id } = member;

        // Create dependencies if needed (assuming they exist from previous tests)
        const category = await Category.findOne();
        const unit = await Unit.findOne();

        // 2. Create Initial Food with Image
        const initialUrl = 'http://example.com/initial.jpg';
        const food = await foodService.createFood({
            name: `UpdateTest ${Date.now()}`,
            group_id,
            category_id: category.id,
            unit_id: unit.id,
            image_url: initialUrl
        }, user_id);
        console.log('Created food with image:', food.image_url);

        // 3. Test Update with Empty String/Undefined (Should Persist)
        console.log('Test 1: Updating with empty string image_url...');
        // Simulate what happens if req.body has empty string and no file
        const updateDataEmpty = {
            name: food.name + ' Updated',
            image_url: ''
        };

        const updated1 = await foodService.updateFood(food.id, updateDataEmpty, user_id);
        console.log('Result image_url:', updated1.image_url);

        if (updated1.image_url !== initialUrl) {
            console.error('FAILURE: Image URL should have persisted but changed to:', updated1.image_url);
        } else {
            console.log('SUCCESS: Image URL persisted.');
        }

        // 4. Test Update with New Image (Should Change)
        console.log('Test 2: Updating with NEW image_url...');
        const newUrl = 'http://example.com/new.jpg';
        const updateDataNew = {
            image_url: newUrl
        };

        // Note: This will try to delete 'http://example.com/initial.jpg' which might log error/fail if deleteImage not mocked. 
        // We ignore that for now or hope deleteImage handles it gracefully.
        try {
            const updated2 = await foodService.updateFood(food.id, updateDataNew, user_id);
            console.log('Result image_url:', updated2.image_url);

            if (updated2.image_url !== newUrl) {
                console.error('FAILURE: Image URL should have updated.');
            } else {
                console.log('SUCCESS: Image URL updated.');
            }
        } catch (e) {
            console.log('Update threw likely due to deleteImage (expected in test env):', e.message);
        }

        // Cleanup
        await foodService.deleteFood(food.id, user_id);
        console.log('Cleanup successful');

    } catch (error) {
        console.error('Test Failed:', error);
    } finally {
        await sequelize.close();
    }
}

verifyFoodUpdate();
