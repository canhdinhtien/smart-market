const admin = require("../config/firebase");

/**
 * Send an FCM notification
 * @param {object} params
 * @param {string} params.token - The FCM registration token
 * @param {string} params.title - Notification title
 * @param {string} params.body - Notification body
 * @param {object} [params.data] - Optional data payload
 * @returns {Promise<void>}
 * @throws {Error} - Throws error if sending fails
 */
const sendFCM = async ({ token, title, body, data }) => {
    try {
        const message = {
            token,
            notification: { title, body },
        };

        if (data) {
            message.data = data;
        }

        await admin.messaging().send(message);
    } catch (err) {
        // If it's an invalid token error, rethrow with a specific code or message
        // so the caller can decide to remove the token.
        if (err.code === "messaging/registration-token-not-registered" ||
            err.code === "messaging/invalid-registration-token") {
            const error = new Error("Invalid FCM Token");
            error.code = "INVALID_FCM_TOKEN";
            throw error;
        }
        throw err;
    }
};

/**
 * Send a multicast FCM notification to multiple tokens
 * @param {object} params
 * @param {string[]} params.tokens - Array of FCM registration tokens
 * @param {string} params.title - Notification title
 * @param {string} params.body - Notification body
 * @param {object} [params.data] - Optional data payload
 * @returns {Promise<import("firebase-admin").messaging.BatchResponse>}
 */
const sendMulticastFCM = async ({ tokens, title, body, data }) => {
    if (!tokens || tokens.length === 0) return { failureCount: 0, responses: [], successCount: 0 };

    const message = {
        tokens,
        notification: { title, body },
    };

    if (data) {
        message.data = data;
    }

    return await admin.messaging().sendEachForMulticast(message);
};

module.exports = { sendFCM, sendMulticastFCM };
