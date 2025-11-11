const express = require('express');
const cors = require('cors');
const routes = require('./routes/index.js');
const errorHandler = require('./middleware/error.middleware.js');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/api', routes);

app.use(errorHandler);

module.exports = app;
