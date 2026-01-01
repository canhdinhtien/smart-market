const express = require('express');
const controller = require('../controllers/unit.controller.js');
const { verifyUser, verifyAdmin } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(verifyUser);
router.use(verifyAdmin);

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
 */
router.post('/', controller.createUnit);

/**
 * @openapi
 * /units:
 *   get:
 *     summary: Get all units
 *     tags: [Units]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of units
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
 */
router.put('/', controller.editUnitByName);

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
 */
router.delete('/', controller.deleteUnitByName);

module.exports = router;
