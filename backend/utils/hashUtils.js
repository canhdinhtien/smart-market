const bcrypt = require('bcryptjs');

async function hashValue(value, options = {}) {
  const {
    saltRounds = 10,
    bcryptLib = bcrypt,
  } = options;

  const salt = await bcryptLib.genSalt(saltRounds);
  return bcryptLib.hash(value, salt);
}

async function compareValues(rawValue, hashedValue, options = {}) {
  const {
    bcryptLib = bcrypt,
  } = options;

  return bcryptLib.compare(rawValue, hashedValue);
}

module.exports = { hashValue, compareValues };
