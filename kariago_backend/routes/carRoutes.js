const express = require('express');
const Car = require('../models/car');

const router = express.Router();
// ✅ Add a new car
router.post('/', async (req, res) => {
    try {
        const { matricule, marque, panne, panne_ia, location, visite_technique, car_work, date_assurance, vignette } = req.body;

        // Check if car already exists
        const existingCar = await Car.findOne({ matricule });
        if (existingCar) {
            return res.status(400).json({ message: "Car with this matricule already exists" });
        }

        const newCar = new Car({
            matricule,
            marque,
            panne,
            panne_ia,
            location,
            visite_technique,
            car_work,
            date_assurance,
            vignette
        });

        await newCar.save();
        res.status(201).json({ message: "Car added successfully", car: newCar });

    } catch (err) {
        console.error("🔥 Error:", err.message);
        res.status(500).json({ error: err.message });
    }
});

// Get all cars
router.get('/', async (req, res) => {
    try {
        const cars = await Car.find();
        res.json(cars);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get a single car
router.get('/:id', async (req, res) => {
    try {
        const car = await Car.findById(req.params.id);
        if (!car) return res.status(404).json({ message: "Car not found" });
        res.json(car);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
