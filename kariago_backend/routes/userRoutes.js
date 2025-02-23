const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/user');
const nodemailer = require('nodemailer');
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

// Protect Profile Update Route
router.put("/:id", authMiddleware, async (req, res) => {
    try {
        const user = await User.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!user) return res.status(404).json({ message: "User not found" });

        res.json({ message: "Profile updated successfully", user });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Secure Password Reset (Prevent Email Enumeration)
router.post('/forgot-password', async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findOne({ email });

        // Always return the same response, even if email does not exist
        if (!user) {
            return res.json({ message: "If an account exists, a password reset link has been sent." });
        }

        // Create Reset Token
        const resetToken = Math.floor(100000 + Math.random() * 900000).toString();
        user.resetToken = resetToken;
        await user.save();

        // Send Email with Reset Token
        let transporter = nodemailer.createTransport({
            service: "gmail",
            auth: {
                user: "dhiadriss@gmail.com", 
                pass: "uljq jtal pcxp uufe" //  App Password
            }
        });

        await transporter.sendMail({
            from: "noreply@kariago.com",
            to: email,
            subject: "Password Reset Code",
            text: `Your password reset code is: ${resetToken}`,
        });

        res.json({ message: "If an account exists, a password reset link has been sent." });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Signup (Register)
router.post('/signup', async (req, res) => {
    try {
        const { cin, permis, num_phone, email, password } = req.body;

        // Check for missing fields
        if (!cin || !permis || !num_phone || !email || !password) {
            return res.status(400).json({ message: "All fields are required" });
        }

        // Check if user already exists
        let user = await User.findOne({ email });
        if (user) {
            return res.status(400).json({ message: "User already exists with this email" });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create new user
        user = new User({ cin, permis, num_phone, email, password: hashedPassword });

        await user.save();
        res.status(201).json({ message: "User registered successfully", user });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Login (Generate Token)
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Check if user exists
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: "Invalid credentials" });
        }

        // Compare passwords
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: "Invalid credentials" });
        }

        // Generate JWT Token
        const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });

        res.json({ token, user });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

//  Protect Getting All Users
router.get('/', authMiddleware, async (req, res) => {
    try {
        const users = await User.find({}, { password: 0 }); // Exclude passwords for security
        res.json(users);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

//  Protect Getting Single User
router.get('/:id', authMiddleware, async (req, res) => {
    try {
        const user = await User.findById(req.params.id, { password: 0 });
        if (!user) return res.status(404).json({ message: "User not found" });

        res.json(user);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});
module.exports = router;
