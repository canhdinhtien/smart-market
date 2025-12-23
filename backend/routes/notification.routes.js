const express = require("express");
const router = express.Router();
const controller = require("../controllers/notification.controller");

router.post("/register-fcm", controller.registerDevice);
router.post("/send", controller.sendToUser);

module.exports = router;
