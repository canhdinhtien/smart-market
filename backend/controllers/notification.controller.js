const { UserDevice } = require("../models");
const { sendFCM } = require("../services/fcm.service.js"); // Keeping for registerDevice if needed, but sendToUser uses NotificationService
const NotificationService = require("../services/notification.service");


exports.registerDevice = async (req, res) => {
  const { user_id, fcm_token, platform, device_id } = req.body;

  const [device] = await UserDevice.findOrCreate({
    where: { fcm_token },
    defaults: {
      user_id,
      platform,
      device_id,
    },
  });

  // nếu token đã tồn tại nhưng user khác → update
  if (device.user_id !== user_id) {
    device.user_id = user_id;
    device.is_active = true;
    await device.save();
  }

  res.json({ message: "Device registered" });
};



exports.sendToUser = async (req, res) => {
  const { user_id, title, body, data } = req.body;

  try {
    await NotificationService.sendToUser(user_id, title, body, data);
    res.json({ message: "Notification sent" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error sending notification" });
  }
};
