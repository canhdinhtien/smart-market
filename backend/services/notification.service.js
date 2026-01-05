const { UserDevice, GroupMember, User } = require("../models");
const { sendFCM, sendMulticastFCM } = require("../utils/fcmUtils");
const { Op } = require("sequelize");

/**
 * Send a notification to a specific user
 * @param {number} userId - The ID of the user to notify
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} [data] - Optional data payload
 */
const sendToUser = async (userId, title, body, data = {}) => {
    try {
        if (!userId) {
            console.error("sendToUser called with missing userId");
            return;
        }

        const devices = await UserDevice.findAll({
            where: {
                user_id: userId,
                is_active: true,
            },
        });

        if (!devices.length) return;

        const tokens = devices.map(d => d.fcm_token);
        const response = await sendMulticastFCM({
            tokens,
            title,
            body,
            data: data || {},
        });

        if (response.failureCount > 0) {
            const failedTokens = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    const errCode = resp.error.code;
                    if (errCode === "messaging/registration-token-not-registered" ||
                        errCode === "messaging/invalid-registration-token" ||
                        errCode === "messaging/mismatched-credential") {
                        failedTokens.push(tokens[idx]);
                    } else {
                        console.error(`Failed to send to user ${userId} device:`, resp.error);
                    }
                }
            });

            if (failedTokens.length > 0) {
                console.warn(`Deactivating ${failedTokens.length} invalid tokens for user ${userId}`);
                await UserDevice.update(
                    { is_active: false },
                    { where: { fcm_token: { [Op.in]: failedTokens } } }
                );
            }
        }
    } catch (error) {
        console.error(`Error sending notification to user ${userId}:`, error);
    }
};

/**
 * Send a notification to all members of a group, optionally excluding one user (e.g. the sender)
 * @param {number} groupId - The ID of the group
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} [data] - Optional data payload
 * @param {number} [excludeUserId] - User ID to exclude from notification
 */
const sendToGroup = async (groupId, title, body, data = {}, excludeUserId = null) => {
    try {
        // Find all members of the group
        const members = await GroupMember.findAll({
            where: {
                group_id: groupId,
                ...(excludeUserId ? { user_id: { [Op.ne]: excludeUserId } } : {})
            },
            attributes: ['user_id']
        });

        const Group = require('../models/Group');
        const group = await Group.findByPk(groupId);
        if (!group) return;

        const memberIds = members.map(m => m.user_id);

        // Add admin if not already in list and not excluded
        if (group.admin_user_id && !memberIds.includes(group.admin_user_id)) {
            memberIds.push(group.admin_user_id);
        }

        // Filter out excluded user if it wasn't filtered by database query (e.g. admin)
        const finalUserIds = memberIds.filter(id => id !== excludeUserId);
        const uniqueUserIds = [...new Set(finalUserIds)];

        if (uniqueUserIds.length === 0) return;

        // OPTIMIZATION: Fetch all active devices for all users in one go
        const devices = await UserDevice.findAll({
            where: {
                user_id: { [Op.in]: uniqueUserIds },
                is_active: true
            }
        });

        if (!devices.length) return;

        const tokens = devices.map(d => d.fcm_token);

        // Firebase limit is 500 tokens per batch. 
        // Simple chunking implementation
        const chunkSize = 500;
        for (let i = 0; i < tokens.length; i += chunkSize) {
            const batchTokens = tokens.slice(i, i + chunkSize);

            const response = await sendMulticastFCM({
                tokens: batchTokens,
                title,
                body,
                data: data || {},
            });

            if (response.failureCount > 0) {
                const failedTokens = [];
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        const errCode = resp.error.code;
                        if (errCode === "messaging/registration-token-not-registered" ||
                            errCode === "messaging/invalid-registration-token" ||
                            errCode === "messaging/mismatched-credential") { // Handle mismatched sender ID
                            failedTokens.push(batchTokens[idx]);
                        }
                    }
                });

                if (failedTokens.length > 0) {
                    await UserDevice.update(
                        { is_active: false },
                        { where: { fcm_token: { [Op.in]: failedTokens } } }
                    );
                }
            }
        }

    } catch (error) {
        console.error(`Error sending notification to group ${groupId}:`, error);
    }
};


/**
 * Register or update a user device for push notifications
 * @param {number} userId 
 * @param {string} token 
 * @param {string} platform 
 * @param {string} deviceId 
 */
const registerDevice = async (userId, token, platform, deviceId) => {
    const [device] = await UserDevice.findOrCreate({
        where: { fcm_token: token },
        defaults: {
            user_id: userId,
            platform,
            device_id: deviceId,
        },
    });

    // If token exists but for a different user, update it
    if (device.user_id !== userId) {
        device.user_id = userId;
        device.is_active = true;
        await device.save();
    }

    return device;
};

module.exports = {
    sendToUser,
    sendToGroup,
    registerDevice,
};
