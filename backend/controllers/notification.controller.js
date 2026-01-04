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
  const { title, body, data } = req.body;
  const userId = req.body.userId || req.body.user_id;

  if (!userId) {
    return res.status(400).json({ message: "userId is required" });
  }

  try {
    await NotificationService.sendToUser(userId, title, body, data);
    res.json({ message: "Notification sent" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error sending notification" });
  }
};
