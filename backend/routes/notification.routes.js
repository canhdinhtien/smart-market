const express = require("express");
const router = express.Router();
const controller = require("../controllers/notification.controller");

/**
 * @openapi
 * tags:
 *   name: Notifications
 *   description: Push notification management
 */

/**
 * @openapi
 * /notifications/register-fcm:
 *   post:
 *     summary: Register a device FCM token
 *     tags: [Notifications]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - fcm_token
 *               - platform
 *             properties:
 *               fcm_token:
 *                 type: string
 *               platform:
 *                 type: string
 *                 enum: [android, ios, web]
 *               device_id:
 *                 type: string
 *                 description: Unique device identifier
 *     responses:
 *       200:
 *         description: Device registered successfully
 *       400:
 *         description: Invalid input
 */
router.post("/register-fcm", controller.registerDevice);

/**
 * @openapi
 * /notifications/send:
 *   post:
 *     summary: Send a notification to a specific user (Dev/Admin only)
 *     tags: [Notifications]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *               - title
 *               - body
 *             properties:
 *               userId:
 *                 type: integer
 *               title:
 *                 type: string
 *               body:
 *                 type: string
 *               data:
 *                 type: object
 *     responses:
 *       200:
 *         description: Notification sent (or processed)
 *       400:
 *         description: Invalid input
 */
router.post("/send", controller.sendToUser);

module.exports = router;
