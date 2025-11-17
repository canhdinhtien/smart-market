const crypto = require('crypto');

function generateVerificationCode(length = 6) {
  const randomBytes = crypto.randomBytes(length);
  const code = randomBytes.toString('base64').slice(0, length);
  return code;
}

module.exports = { generateVerificationCode };
