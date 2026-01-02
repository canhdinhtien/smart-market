const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger.js');
const routes = require('./routes/index.js');
const errorHandler = require('./middleware/error.middleware.js');
const { contextMiddleware } = require('./middleware/context.middleware');

const app = express();


app.use(contextMiddleware);
app.use(cors());
app.use(express.json());
app.use(cookieParser());

const swaggerOptions = {
    swaggerOptions: {
        responseInterceptor: function (response) {
            if (response.url.endsWith('/users/login') && response.status === 200) {
                try {
                    const body = JSON.parse(response.text);
                    if (body.accessToken) {
                        const token = body.accessToken;
                        // 'bearerAuth' must match the security scheme name in swagger config
                        ui.preauthorizeApiKey('bearerAuth', token);
                    }
                } catch (e) {
                    console.error('Failed to auto-authorize in Swagger UI', e);
                }
            }
            return response;
        }
    }
};

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, swaggerOptions));

app.use('/api', routes);

app.use(errorHandler);

module.exports = app;
