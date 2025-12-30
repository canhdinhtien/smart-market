const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger.js');
const routes = require('./routes/index.js');
const errorHandler = require('./middleware/error.middleware.js');

const app = express();

app.use(cors());
app.use(express.json());
app.use(cookieParser());

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.use('/api', routes);

app.use(errorHandler);

module.exports = app;
