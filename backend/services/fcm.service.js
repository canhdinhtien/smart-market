const admin = require("../config/firebase");
const { UserDevice } = require("../models");

const sendFCM = async ({ token, title, body }) => {
  try {
    await admin.messaging().send({
      token,
      notification: { title, body },
    });
  } catch (err) {
    if (err.code === "messaging/registration-token-not-registered") {
      await UserDevice.update(
        { is_active: false },
        { where: { fcm_token: token } }
      );
    }
  }
};

module.exports = { sendFCM };
