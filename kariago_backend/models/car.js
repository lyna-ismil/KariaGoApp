const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid'); // ✅ Import uuid

const diagnostiqueVidangeSchema = new mongoose.Schema({
    vidange1: { type: Number, default: 0 },
    vidange2: { type: Number, default: 0 },
    vidange3: { type: Number, default: 0 }
}, { _id: false });

const CarSchema = new mongoose.Schema({
    id_car: { 
        type: String, 
        unique: true, 
        required: true,
        default: uuidv4 // ✅ Generate unique ID
    },
    matricule: { type: String, required: true, unique: true, trim: true },
    marque: { type: String, required: true, trim: true },
    panne: { type: String, required: true, trim: true },
    panne_ia: { type: String, required: true, trim: true },
    location: { type: String, required: true, trim: true },
    visite_technique: { type: Date, required: true, default: null },
    car_work: { type: Boolean, default: true },
    date_assurance: { type: Date, required: true, default: null },
    vignette: { type: Date, required: true, default: null },
    diagnostique_vidange: diagnostiqueVidangeSchema
});

const Car = mongoose.model('Car', CarSchema);

module.exports = Car;
