const crypto = require('crypto');

function generateVerificationCode(length = 6) {
  const max = 10 ** length;
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  return (array[0] % max).toString().padStart(length, '0');
}

module.exports = { generateVerificationCode };
