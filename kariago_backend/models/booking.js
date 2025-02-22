const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid'); // ✅ Import uuid

const bookingSchema = new mongoose.Schema({
    id_booking: { 
        type: String, 
        unique: true, 
        required: true,
        default: uuidv4 // ✅ Generate unique booking ID
    },
    date_hour_booking: { 
        type: Date, 
        required: true 
    },
    date_hour_expire: { 
        type: Date, 
        required: true 
    },
    id_user: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true 
    },
    id_car: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'Car', 
        required: true 
    },
    current_Key_car: { 
        type: String 
    },
    image: { 
        type: String 
    },
    status: { 
        type: String, 
        enum: ['pending', 'confirmed', 'canceled'], 
        default: 'pending' 
    },
    contrat: { 
        type: String 
    },
    paiement: { 
        type: Number 
    },
    location_Before_Renting: { 
        type: String 
    },
    location_After_Renting: { 
        type: String 
    },
    estimated_Location: { 
        type: String 
    }
});

// ✅ Indexing for faster search
bookingSchema.index({ id_user: 1, id_car: 1 });

const Booking = mongoose.model('Booking', bookingSchema);
module.exports = Booking;
