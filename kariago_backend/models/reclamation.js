const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const reclamationSchema = new mongoose.Schema({
    id_reclamation: {
        type: String,
        unique: true,
        required: true,
        default: uuidv4 // Auto-generate unique reclamation ID
    },
    id_user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true // ✅ Make id_user required
    },
    message: {
        type: String,
        required: true
    },
    date_created: {
        type: Date,
        default: Date.now
    }
});

const Reclamation = mongoose.model('Reclamation', reclamationSchema);

module.exports = Reclamation;
