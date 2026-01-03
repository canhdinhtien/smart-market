const express = require('express');
const controller = require('../controllers/shoppinglist.controller.js');
const { verifyUser } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

/**
 * @openapi
 * tags:
 *   name: ShoppingLists
 *   description: Shopping list and task management
 */

/**
 * @openapi
 * /shopping:
 *   get:
 *     summary: Get all shopping lists
 *     tags: [ShoppingLists]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: group_id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID to get shopping lists from
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Items per page
 *       - in: query
 *         name: name
 *         schema:
 *           type: string
 *         description: Filter by list name
 *     responses:
 *       200:
 *         description: List of shopping lists with tasks and details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 lists:
 *                   type: array
 *                   items:
 *                     type: object
 *                 total:
 *                   type: integer
 *                 page:
 *                   type: integer
 *                 totalPages:
 *                   type: integer
 *       400:
 *         description: Group ID is required
 */
router.get('/', controller.getAllShoppingLists);

/**
 * @openapi
 * /shopping/{id}:
 *   get:
 *     summary: Get a shopping list by ID
 *     tags: [ShoppingLists]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Shopping list ID
 *     responses:
 *       200:
 *         description: Shopping list details including tasks
 *       404:
 *         description: Shopping list not found
 */
router.get('/:id', controller.getShoppingListById);

/**
 * @openapi
 * /shopping:
 *   post:
 *     summary: Create a new shopping list
 *     tags: [ShoppingLists]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *             properties:
 *               name:
 *                 type: string
 *     responses:
 *       201:
 *         description: Shopping list created successfully
 *       400:
 *         description: Invalid input
 */
router.post('/', controller.createShoppingList);

/**
 * @openapi
 * /shopping/{id}:
 *   put:
 *     summary: Update a shopping list
 *     tags: [ShoppingLists]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Shopping list ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *     responses:
 *       200:
 *         description: Shopping list updated successfully
 *       404:
 *         description: Shopping list not found
 */
router.put('/:id', controller.updateShoppingList);

/**
 * @openapi
 * /shopping/{id}:
 *   delete:
 *     summary: Delete a shopping list
 *     tags: [ShoppingLists]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Shopping list ID
 *     responses:
 *       200:
 *         description: Shopping list deleted successfully
 *       404:
 *         description: Shopping list not found
 */
router.delete('/:id', controller.deleteShoppingList);

/**
 * @openapi
 * /shopping/{id}/tasks:
 *   post:
 *     summary: Create tasks in a shopping list
 *     tags: [ShoppingLists]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Shopping list ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - tasks
 *             properties:
 *               tasks:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     name:
 *                       type: string
 *                     quantity:
 *                       type: number
 *     responses:
 *       201:
 *         description: Tasks created successfully
 *       404:
 *         description: Shopping list not found
 */
router.post('/:id/tasks', controller.createTasks);

/**
 * @openapi
 * /shopping/{id}/tasks:
 *   get:
 *     summary: Get all tasks in a shopping list
 *     tags: [ShoppingLists]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Shopping list ID
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Items per page
 *       - in: query
 *         name: name
 *         schema:
 *           type: string
 *         description: Filter by task name
 *       - in: query
 *         name: is_purchased
 *         schema:
 *           type: boolean
 *         description: Filter by purchase status
 *     responses:
 *       200:
 *         description: List of tasks
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 tasks:
 *                   type: array
 *                   items:
 *                     type: object
 *                 total:
 *                   type: integer
 *                 page:
 *                   type: integer
 *                 totalPages:
 *                   type: integer
 *       404:
 *         description: Shopping list not found
 */
router.get('/:id/tasks', controller.getListOfTasks);

/**
 * @openapi
 * /shopping/tasks/{taskId}:
 *   put:
 *     summary: Update a task
 *     tags: [ShoppingLists]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *         description: Task ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               quantity:
 *                 type: number
 *               is_purchased:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Task updated successfully
 *       404:
 *         description: Task not found
 */
router.put('/tasks/:taskId', controller.updateTask);

/**
 * @openapi
 * /shopping/tasks/{taskId}:
 *   delete:
 *     summary: Delete a task
 *     tags: [ShoppingLists]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *         description: Task ID
 *     responses:
 *       200:
 *         description: Task deleted successfully
 *       404:
 *         description: Task not found
 */
router.delete('/tasks/:taskId', controller.deleteTask);

module.exports = router;
