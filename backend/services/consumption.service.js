const Consumption = require('../models/Consumption');
const Food = require('../models/Food');
const FridgeItem = require('../models/FridgeItem');
const Unit = require('../models/Unit');
const sequelize = require('../config/database');

const ConsumptionService = {
    async getUserConsumptionStats(userId) {
        try {
            const stats = await Consumption.findAll({
                attributes: [
                    'fridge_item_id',
                    [sequelize.fn('SUM', sequelize.col('quantity_consumed')), 'total_quantity']
                ],
                where: { user_id: userId },
                include: [
                    {
                        model: FridgeItem,
                        paranoid: false,
                        include: [{
                            model: Food,
                            attributes: ['name', 'image_url'],
                            include: [{ model: Unit, attributes: ['name'] }]
                        }]
                    }
                ],
                group: ['fridge_item_id', 'FridgeItem.id', 'FridgeItem.Food.id', 'FridgeItem.Food.Unit.id'],
                order: [[sequelize.fn('SUM', sequelize.col('quantity_consumed')), 'DESC']]
            });

            const aggregated = {};
            stats.forEach(stat => {
                const food = stat.FridgeItem?.Food;
                if (food) {
                    const unitName = food.Unit ? food.Unit.name : 'Unknown';
                    const key = `${food.name}_${unitName}`; // Composite key

                    if (!aggregated[key]) {
                        aggregated[key] = {
                            name: food.name,
                            unit: unitName,
                            image_url: food.image_url,
                            total_quantity: 0
                        };
                    }
                    aggregated[key].total_quantity += parseFloat(stat.dataValues.total_quantity);
                }
            });

            return Object.values(aggregated).sort((a, b) => b.total_quantity - a.total_quantity);

        } catch (error) {
            throw error;
        }
    },

    async getGroupConsumptionStats(groupId) {
        try {
            const stats = await Consumption.findAll({
                attributes: [
                    'fridge_item_id',
                    [sequelize.fn('SUM', sequelize.col('quantity_consumed')), 'total_quantity']
                ],
                where: { group_id: groupId },
                include: [
                    {
                        model: FridgeItem,
                        paranoid: false,
                        include: [{
                            model: Food,
                            attributes: ['name', 'image_url'],
                            include: [{ model: Unit, attributes: ['name'] }]
                        }]
                    }
                ],
                group: ['fridge_item_id', 'FridgeItem.id', 'FridgeItem.Food.id', 'FridgeItem.Food.Unit.id'],
                order: [[sequelize.fn('SUM', sequelize.col('quantity_consumed')), 'DESC']]
            });

            const aggregated = {};
            stats.forEach(stat => {
                const food = stat.FridgeItem?.Food;
                if (food) {
                    const unitName = food.Unit ? food.Unit.name : 'Unknown';
                    const key = `${food.name}_${unitName}`;

                    if (!aggregated[key]) {
                        aggregated[key] = {
                            name: food.name,
                            unit: unitName,
                            image_url: food.image_url,
                            total_quantity: 0
                        };
                    }
                    aggregated[key].total_quantity += parseFloat(stat.dataValues.total_quantity);
                }
            });

            return Object.values(aggregated).sort((a, b) => b.total_quantity - a.total_quantity);
        } catch (error) {
            throw error;
        }
    },

    async getAllConsumptionStats() {
        try {
            const stats = await Consumption.findAll({
                attributes: [
                    'fridge_item_id',
                    [sequelize.fn('SUM', sequelize.col('quantity_consumed')), 'total_quantity']
                ],
                include: [
                    {
                        model: FridgeItem,
                        paranoid: false,
                        include: [{
                            model: Food,
                            attributes: ['name', 'image_url'],
                            include: [{ model: Unit, attributes: ['name'] }]
                        }]
                    }
                ],
                group: ['fridge_item_id', 'FridgeItem.id', 'FridgeItem.Food.id', 'FridgeItem.Food.Unit.id'],
                order: [[sequelize.fn('SUM', sequelize.col('quantity_consumed')), 'DESC']]
            });

            const aggregated = {};
            stats.forEach(stat => {
                const food = stat.FridgeItem?.Food;
                if (food) {
                    const unitName = food.Unit ? food.Unit.name : 'Unknown';
                    const key = `${food.name}_${unitName}`;

                    if (!aggregated[key]) {
                        aggregated[key] = {
                            name: food.name,
                            unit: unitName,
                            image_url: food.image_url,
                            total_quantity: 0
                        };
                    }
                    aggregated[key].total_quantity += parseFloat(stat.dataValues.total_quantity);
                }
            });

            return Object.values(aggregated).sort((a, b) => b.total_quantity - a.total_quantity);
        } catch (error) {
            throw error;
        }
    }
};

module.exports = ConsumptionService;
