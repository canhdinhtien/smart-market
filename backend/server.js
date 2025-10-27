const app = require('./app.js');
const dotenv = require('dotenv');
dotenv.config();
const sequelize = require('./config/database.js');

const PORT = process.env.PORT || 5000;

async function startServer() {
  try {
    console.log('DATABASE_URL:', process.env.DATABASE_URL);
console.log('Type:', typeof process.env.DATABASE_URL);
    await sequelize.authenticate();
    console.log('Database connected successfully');

    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
    process.exit(1);
  }
}

startServer();