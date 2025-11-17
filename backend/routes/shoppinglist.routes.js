const express = require('express');
const controller = require('../controllers/shoppinglist.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.post('/', controller.createShoppingList);
router.put('/', controller.updateShoppingList);
router.delete('/', controller.deleteShoppingList);
router.post('/task', controller.createTasks);
router.get('/task', controller.getListOfTasks);
router.delete('/task', controller.deleteTask);
router.put('/task', controller.updateTask);

module.exports = router;
