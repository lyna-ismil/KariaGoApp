const express = require('express');
const mongoose = require('mongoose');
const Reclamation = require('../models/reclamation');
const User = require('../models/user'); // ✅ Import User model

const router = express.Router();

// ✅ Submit a new reclamation
router.post('/', async (req, res) => {
    try {
        const { id_user, message } = req.body;

        // ✅ Ensure id_user is provided
        if (!id_user || !mongoose.Types.ObjectId.isValid(id_user)) {
            return res.status(400).json({ message: "Invalid or missing user ID" });
        }

        // ✅ Check if the user exists
        const userExists = await User.findById(id_user);
        if (!userExists) {
            return res.status(404).json({ message: "User not found" });
        }

        const newReclamation = new Reclamation({
            id_user: new mongoose.Types.ObjectId(id_user),
            message
        });

        await newReclamation.save();
        res.status(201).json({ message: "Reclamation submitted successfully", reclamation: newReclamation });

    } catch (err) {
        console.error("🔥 Error:", err.message);
        res.status(500).json({ error: err.message });
    }
});

// ✅ Get all reclamations (populate user details)
router.get('/', async (req, res) => {
    try {
        const reclamations = await Reclamation.find()
            .populate('id_user', 'cin num_phone email'); // ✅ Populate user details

        res.json(reclamations);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
