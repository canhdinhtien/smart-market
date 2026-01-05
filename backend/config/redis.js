const redis = require('redis');
const dotenv = require('dotenv');

dotenv.config();

const redisConfig = {
  url: process.env.REDIS_URL         
};

const client = redis.createClient(redisConfig);

client.on('connect', () => {
  console.log('Connected to Redis');
});

client.on('error', (err) => {
  console.error('Redis error:', err);
});

client.connect();

module.exports = client;