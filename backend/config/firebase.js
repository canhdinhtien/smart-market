const admin = require("firebase-admin");
const serviceAccount = require("../../backend-firebase.json"); //replace with your actual path

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

module.exports = admin;
