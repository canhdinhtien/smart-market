const cron = require('node-cron');
const { Op } = require('sequelize');
const FridgeItem = require('../models/FridgeItem');
const Food = require('../models/Food');
const NotificationService = require('./notification.service');

const initCronJobs = () => {
    // Schedule task to run every day at 8:00 AM
    cron.schedule('0 8 * * *', async () => {
        console.log('Running daily food expiry check...');
        try {
            const today = new Date();
            const threeDaysLater = new Date();
            threeDaysLater.setDate(today.getDate() + 3);

            // Find items expiring within the next 3 days
            const expiringItems = await FridgeItem.findAll({
                where: {
                    expiry_date: {
                        [Op.between]: [today, threeDaysLater]
                    }
                },
                include: [
                    { model: Food, attributes: ['name'] }
                ]
            });

            if (expiringItems.length === 0) {
                console.log('No expiring items found.');
                return;
            }

            // Group items by group_id to send batched notifications
            const itemsByGroup = {};
            expiringItems.forEach(item => {
                if (!itemsByGroup[item.group_id]) {
                    itemsByGroup[item.group_id] = [];
                }
                itemsByGroup[item.group_id].push(item);
            });

            // Send notifications for each group
            for (const groupId in itemsByGroup) {
                const items = itemsByGroup[groupId];
                const itemNames = items.slice(0, 3).map(i => i.Food ? i.Food.name : 'Unknown Item').join(', ');
                const count = items.length;
                const remaining = count > 3 ? ` and ${count - 3} others` : '';

                const title = 'Food Expiry Warning';
                const body = `You have ${count} item(s) expiring soon: ${itemNames}${remaining}. Check your fridge!`;

                await NotificationService.sendToGroup(
                    parseInt(groupId),
                    title,
                    body,
                    { type: 'FOOD_EXPIRY', count: count }
                );
            }

            console.log(`Sent expiry notifications to ${Object.keys(itemsByGroup).length} groups.`);

        } catch (error) {
            console.error('Error running food expiry check:', error);
        }
    });

    // Schedule task to run every day at 00:01 AM for consumption processing
    cron.schedule('1 0 * * *', async () => {
        console.log('Running daily consumption processing...');
        try {
            await processDailyConsumptions();
            console.log('Daily consumption processing completed.');
        } catch (error) {
            console.error('Error running daily consumption processing:', error);
        }
    });

    console.log('Cron jobs initialized.');
};

const processDailyConsumptions = async () => {
    const Consumption = require('../models/Consumption');
    const MealPlan = require('../models/MealPlan');
    const Recipe = require('../models/Recipe');
    const RecipeIngredient = require('../models/RecipeIngredient');
    const Food = require('../models/Food');
    const Group = require('../models/Group');
    const User = require('../models/User');

    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    // Use local date components to avoid UTC shift issues at 00:01
    const year = yesterday.getFullYear();
    const month = String(yesterday.getMonth() + 1).padStart(2, '0');
    const day = String(yesterday.getDate()).padStart(2, '0');
    const dateString = `${year}-${month}-${day}`;

    console.log(`Processing consumptions for date: ${dateString}`);

    try {
        let mealPlans = await MealPlan.findAll({
            where: {
                date: dateString
            },
            include: [
                {
                    model: Recipe,
                    include: [
                        {
                            model: RecipeIngredient,
                            include: [
                                { model: Food } // To check unit if needed, though unit_id is on Ingredient directly
                            ]
                        }
                    ]
                }
            ]
        });

        console.log(`Found ${mealPlans.length} meal plans to process.`);

        // Sort meal plans by meal_type: sang -> trua -> toi
        const mealOrder = { 'sang': 1, 'trua': 2, 'toi': 3 };
        mealPlans.sort((a, b) => {
            return (mealOrder[a.meal_type] || 4) - (mealOrder[b.meal_type] || 4);
        });

        for (const plan of mealPlans) {
            if (!plan.Recipe || !plan.Recipe.RecipeIngredients) {
                continue; // Skip if no recipe or ingredients
            }

            // Fetch group members AND admin to distribute consumption
            const group = await Group.findByPk(plan.group_id, {
                include: ['members']
            });

            if (!group) continue;

            // Ensure admin is included in members list
            let members = group.members ? [...group.members] : [];
            if (group.admin_user_id) {
                const isAdminInMembers = members.some(m => m.id === group.admin_user_id);
                if (!isAdminInMembers) {
                    // Fetch admin user and add to list if not already there
                    const adminUser = await User.findByPk(group.admin_user_id);
                    if (adminUser) {
                        members.push(adminUser);
                    }
                }
            }

            // If still no members (unlikely if admin exists), handle gracefully
            if (members.length === 0) {
                members = [{ id: null }]; // Fallback
            }

            const memberCount = members.length;

            for (const ingredient of plan.Recipe.RecipeIngredients) {
                // Find matching fridge items for the group with the same food and unit
                // We prioritize items expiring soonest (FIFO)
                const fridgeItems = await FridgeItem.findAll({
                    where: {
                        group_id: plan.group_id,
                        food_id: ingredient.food_id,
                    },
                    include: [
                        {
                            model: Food,
                            where: { unit_id: ingredient.unit_id } // Strict unit matching
                        }
                    ],
                    order: [['expiry_date', 'ASC'], ['created_at', 'ASC']]
                });

                if (fridgeItems.length === 0) continue;

                // STRICT STOCK CHECK: Calculate total available first
                const totalAvailable = fridgeItems.reduce((sum, item) => sum + parseFloat(item.quantity), 0);
                const requiredQuantity = parseFloat(ingredient.quantity);

                if (totalAvailable < requiredQuantity) {
                    console.log(`Insufficient stock for Food ID ${ingredient.food_id}. Required: ${requiredQuantity}, Available: ${totalAvailable}. Skipping consumption.`);
                    continue; // Skip strict check failed
                }

                let remainingQuantityToConsume = requiredQuantity;

                for (const item of fridgeItems) {
                    if (remainingQuantityToConsume <= 0) break;

                    const itemQty = parseFloat(item.quantity);
                    let consumeFromThis = 0;

                    if (itemQty >= remainingQuantityToConsume) {
                        consumeFromThis = remainingQuantityToConsume;
                        // Determine new props
                        const newQty = itemQty - consumeFromThis;

                        // Update Fridge Item
                        if (newQty === 0) {
                            await item.destroy();
                        } else {
                            item.quantity = newQty;
                            await item.save();
                        }

                        remainingQuantityToConsume = 0;
                    } else {
                        consumeFromThis = itemQty;
                        remainingQuantityToConsume -= itemQty;
                        await item.destroy();
                    }

                    // Distribute consumption record to members
                    const quantityPerUser = consumeFromThis / memberCount;

                    for (const member of members) {
                        await Consumption.create({
                            fridge_item_id: item.id,
                            quantity_consumed: quantityPerUser,
                            date_consumed: dateString,
                            group_id: plan.group_id,
                            user_id: member.id
                        });
                    }
                }
            }
        }

    } catch (error) {
        console.error('Error in processDailyConsumptions:', error);
        throw error;
    }
};

module.exports = { initCronJobs, processDailyConsumptions };
