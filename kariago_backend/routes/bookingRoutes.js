const express = require('express');
const mongoose = require('mongoose');
const Booking = require('../models/booking');
const User = require('../models/user'); // Import User model
const Car = require('../models/car'); //  Import Car model
const { v4: uuidv4 } = require('uuid'); // ✅ Import uuid

const router = express.Router();

//  Create a new booking (Ensure User and Car exist)
router.post('/', async (req, res) => {
    try {
        const { id_user, id_car, date_hour_booking, date_hour_expire, current_Key_car, status, contrat, paiement } = req.body;

        //  Convert string ID to ObjectId
        if (!mongoose.Types.ObjectId.isValid(id_user) || !mongoose.Types.ObjectId.isValid(id_car)) {
            return res.status(400).json({ message: "Invalid user or car ID format" });
        }

        //  Check if User exists
        const userExists = await User.findById(id_user);
        if (!userExists) {
            return res.status(404).json({ message: "User not found" });
        }

        //  Check if Car exists
        const carExists = await Car.findById(id_car);
        if (!carExists) {
            return res.status(404).json({ message: "Car not found" });
        }

        //  Create new booking
        const newBooking = new Booking({
            id_booking: uuidv4(), // Auto-generate unique booking ID
            id_user: new mongoose.Types.ObjectId(id_user),
            id_car: new mongoose.Types.ObjectId(id_car),
            date_hour_booking,
            date_hour_expire,
            current_Key_car,
            status,
            contrat,
            paiement
        });

        await newBooking.save();
        res.status(201).json({ message: "Booking created successfully", booking: newBooking });

    } catch (err) {
        console.error(" Error:", err.message);
        res.status(500).json({ error: err.message });
    }
});

//  Get all bookings (Populate User and Car details)
router.get('/', async (req, res) => {
    try {
        const bookings = await Booking.find()
            .populate('id_user', 'cin num_phone email') // ✅ Populate user details
            .populate('id_car', 'matricule marque location'); // ✅ Populate car details

        res.json(bookings);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
