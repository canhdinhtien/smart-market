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

    console.log('Cron jobs initialized.');
};

module.exports = { initCronJobs };
