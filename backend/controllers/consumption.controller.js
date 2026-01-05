const consumptionService = require('../services/consumption.service');
const groupService = require('../services/group.service');

exports.getMyStats = async (req, res) => {
    try {
        const userId = req.user.id;
        const stats = await consumptionService.getUserConsumptionStats(userId);
        res.status(200).json(stats);
    } catch (error) {
        console.error('Error getting my stats:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.getGroupStats = async (req, res) => {
    try {
        const userId = req.user.id;
        const groupId = parseInt(req.params.groupId);

        const group = await groupService.getGroupById(groupId);
        if (!group) return res.status(404).json({ message: 'Group not found' });

        const isMember = await groupService.isMember(groupId, userId);
        if (!isMember && !req.user.is_admin) {
            return res.status(403).json({ message: 'Access denied' });
        }

        const stats = await consumptionService.getGroupConsumptionStats(groupId);
        res.status(200).json(stats);
    } catch (error) {
        console.error('Error getting group stats:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.getAllStats = async (req, res) => {
    try {
        if (!req.user.is_admin) {
            return res.status(403).json({ message: 'Access denied. Admin only.' });
        }

        const stats = await consumptionService.getAllConsumptionStats();
        res.status(200).json(stats);
    } catch (error) {
        console.error('Error getting all stats:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};
