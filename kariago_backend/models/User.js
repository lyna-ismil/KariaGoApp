const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    cin: { 
        type: String, 
        required: true, 
        unique: true, 
        trim: true 
    },
    permis: { 
        type: String, 
        required: true, 
        trim: true 
    },
    num_phone: { 
        type: String, 
        required: true, 
        trim: true,
        match: /^[0-9]{8}$/ // Tunisian phone number format (8 digits)
    },
    email: { 
        type: String, 
        required: true, 
        unique: true, 
        trim: true 
    },
    password: { 
        type: String, 
        required: true 
    },
    facture: { 
        type: Number, 
        default: 0 
    },
    nbr_fois_allocation: { 
        type: Number, 
        default: 0 
    },
    blacklist: { 
        type: Boolean, 
        default: false 
    },
    iD_Booking: [
        { 
            type: mongoose.Schema.Types.ObjectId, 
            ref: 'Booking' 
        }
    ]
});

// ✅ Ensure email is indexed properly
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ cin: 1, num_phone: 1 });

const User = mongoose.model('User', userSchema);
module.exports = User;
