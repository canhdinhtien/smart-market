const express = require('express');
const controller = require('../controllers/shoppinglist.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

router.get('/', controller.getAllShoppingLists);
router.get('/:id', controller.getShoppingListById);
router.post('/', controller.createShoppingList);
router.put('/:id', controller.updateShoppingList);
router.delete('/:id', controller.deleteShoppingList);

router.post('/:id/tasks', controller.createTasks);
router.get('/:id/tasks', controller.getListOfTasks);
router.put('/tasks/:taskId', controller.updateTask);
router.delete('/tasks/:taskId', controller.deleteTask);

module.exports = router;
