const express = require('express');
const controller = require('../controllers/unit.controller.js');
const { verifyUser, verifyAdmin } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);

/**
 * @openapi
 * tags:
 *   name: Units
 *   description: Measurement unit management
 */

/**
 * @openapi
 * /units:
 *   post:
 *     summary: Create a new unit
 *     tags: [Units]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - unitName
 *             properties:
 *               unitName:
 *                 type: string
 *     responses:
 *       201:
 *         description: Unit created successfully
 *       400:
 *         description: Invalid input or unit already exists
 *       403:
 *         description: Forbidden - Admins only
 */
router.post('/', verifyAdmin, controller.createUnit);

/**
 * @openapi
 * /units:
 *   get:
 *     summary: Get all units
 *     tags: [Units]
 *     security:
 *       - bearerAuth: []
 *     parameters:
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
 *         description: Filter by unit name
 *     responses:
 *       200:
 *         description: List of units
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 units:
 *                   type: array
 *                   items:
 *                     type: object
 *                 total:
 *                   type: integer
 *                 page:
 *                   type: integer
 *                 totalPages:
 *                   type: integer
 */
router.get('/', controller.getAllUnits);

/**
 * @openapi
 * /units:
 *   put:
 *     summary: Update a unit by name
 *     tags: [Units]
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
 *                 description: Current unit name
 *               newName:
 *                 type: string
 *                 description: New unit name
 *     responses:
 *       200:
 *         description: Unit updated successfully
 *       404:
 *         description: Unit not found
 *       403:
 *         description: Forbidden - Admins only
 */
router.put('/', verifyAdmin, controller.editUnitByName);

/**
 * @openapi
 * /units:
 *   delete:
 *     summary: Delete a unit by name
 *     tags: [Units]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - unitName
 *             properties:
 *               unitName:
 *                 type: string
 *     responses:
 *       200:
 *         description: Unit deleted successfully
 *       404:
 *         description: Unit not found
 *       403:
 *         description: Forbidden - Admins only
 */
router.delete('/', verifyAdmin, controller.deleteUnitByName);

module.exports = router;
