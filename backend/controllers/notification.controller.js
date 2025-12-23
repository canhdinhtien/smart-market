const { UserDevice } = require("../models");
const { sendFCM } = require("../services/fcm.service.js");


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
  const { user_id, title, body } = req.body;

  const devices = await UserDevice.findAll({
    where: {
      user_id,
      is_active: true,
    },
  });

  await Promise.all(
    devices.map(d =>
      sendFCM({
        token: d.fcm_token,
        title,
        body,
      })
    )
  );

  res.json({ message: "Notification sent" });
};
