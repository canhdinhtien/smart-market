const cron = require('node-cron');
const { Op } = require('sequelize');
const FridgeItem = require('../models/FridgeItem');
const Food = require('../models/Food');
const NotificationService = require('./notification.service');
const dotenv = require('dotenv');
dotenv.config();

const initCronJobs = () => {
    // Schedule task to run every day at 8:00 AM
    cron.schedule(process.env.EXPIRY_CHECK_TIME, async () => {
        console.log('Running daily food expiry check...');
        await checkExpiringItems();
    });

    // Schedule task to run every day at 00:01 AM for consumption processing

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


const checkExpiringItems = async () => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const endOfToday = new Date(today);
        endOfToday.setHours(23, 59, 59, 999);

        const startOfTomorrow = new Date(today);
        startOfTomorrow.setDate(today.getDate() + 1);

        const threeDaysLater = new Date(today);
        threeDaysLater.setDate(today.getDate() + 3);
        threeDaysLater.setHours(23, 59, 59, 999);

        console.log(`Checking expiry for Today: ${today.toISOString()} - ${endOfToday.toISOString()}`);
        console.log(`Checking expiry for Soon: ${startOfTomorrow.toISOString()} - ${threeDaysLater.toISOString()}`);

        // 1. Check for items expiring TODAY (Urgent)
        const expiringToday = await FridgeItem.findAll({
            where: {
                expiry_date: {
                    [Op.between]: [today, endOfToday]
                },
                quantity: { [Op.gt]: 0 } // Only check items with quantity > 0
            },
            include: [{ model: Food, attributes: ['name'] }]
        });

        // 2. Check for items expiring SOON (Tomorrow -> 3 days)
        const expiringSoon = await FridgeItem.findAll({
            where: {
                expiry_date: {
                    [Op.between]: [startOfTomorrow, threeDaysLater]
                },
                quantity: { [Op.gt]: 0 }
            },
            include: [{ model: Food, attributes: ['name'] }]
        });

        // Helper to group and send
        const processAndSend = async (items, type) => {
            if (items.length === 0) return;

            const itemsByGroup = {};
            items.forEach(item => {
                if (!itemsByGroup[item.group_id]) {
                    itemsByGroup[item.group_id] = [];
                }
                itemsByGroup[item.group_id].push(item);
            });

            for (const groupId in itemsByGroup) {
                const groupItems = itemsByGroup[groupId];
                const itemNames = groupItems.slice(0, 3).map(i => i.Food ? i.Food.name : 'Unknown Item').join(', ');
                const count = groupItems.length;
                const remaining = count > 3 ? ` and ${count - 3} others` : '';

                let title = '';
                let body = '';

                if (type === 'TODAY') {
                    title = '🚨 Urgent: Food Expiring Today!';
                    body = `Hurry! ${count} item(s) are expiring TODAY: ${itemNames}${remaining}. Use them now!`;
                } else {
                    title = '⚠️ Food Expiry Warning';
                    body = `Heads up: ${count} item(s) are expiring soon: ${itemNames}${remaining}. Plan your meals!`;
                }

                await NotificationService.sendToGroup(
                    parseInt(groupId),
                    title,
                    body,
                    { type: 'FOOD_EXPIRY', subtype: type, count: count }
                );
            }
            console.log(`Sent ${type} expiry notifications to ${Object.keys(itemsByGroup).length} groups.`);
        };

        if (expiringToday.length === 0 && expiringSoon.length === 0) {
            console.log('No expiring items found.');
        } else {
            await processAndSend(expiringToday, 'TODAY');
            await processAndSend(expiringSoon, 'SOON');
        }

    } catch (error) {
        console.error('Error in checkExpiringItems:', error);
    }
};

module.exports = { initCronJobs, processDailyConsumptions, checkExpiringItems };
