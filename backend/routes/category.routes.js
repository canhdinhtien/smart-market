const express = require('express');
const controller = require('../controllers/category.controller.js');
const { verifyUser, verifyAdmin } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);
router.use(verifyAdmin);

/**
 * @openapi
 * tags:
 *   name: Categories
 *   description: Food category management
 */

/**
 * @openapi
 * /categories:
 *   post:
 *     summary: Create a new category
 *     tags: [Categories]
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
 *         description: Category created successfully
 *       400:
 *         description: Invalid input or category already exists
 */
router.post('/', controller.createCategory);

/**
 * @openapi
 * /categories:
 *   get:
 *     summary: Get all categories
 *     tags: [Categories]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of categories
 */
router.get('/', controller.getAllCategories);

/**
 * @openapi
 * /categories:
 *   put:
 *     summary: Update a category by name
 *     tags: [Categories]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - oldName
 *               - newName
 *             properties:
 *               oldName:
 *                 type: string
 *                 description: Current category name
 *               newName:
 *                 type: string
 *                 description: New category name
 *     responses:
 *       200:
 *         description: Category updated successfully
 *       404:
 *         description: Category not found
 */
router.put('/', controller.editCategoryByName);

/**
 * @openapi
 * /categories:
 *   delete:
 *     summary: Delete a category by name
 *     tags: [Categories]
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
 *       200:
 *         description: Category deleted successfully
 *       404:
 *         description: Category not found
 */
router.delete('/', controller.deleteCategoryByName);

module.exports = router;
