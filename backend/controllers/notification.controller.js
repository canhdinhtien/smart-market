const NotificationService = require("../services/notification.service");


exports.registerDevice = async (req, res) => {
  const { fcm_token, platform, device_id } = req.body;
  const user_id = req.user.id;

  try {
    await NotificationService.registerDevice(user_id, fcm_token, platform, device_id);
    res.json({ message: "Device registered" });
  } catch (error) {
    console.error('Error registering device:', error);
    res.status(500).json({ message: "Error registering device" });
  }
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
