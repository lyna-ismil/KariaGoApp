const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/user');
const nodemailer = require('nodemailer');


const router = express.Router();
// Send Password Reset Email
router.post('/forgot-password', async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findOne({ email });

        if (!user) {
            return res.status(404).json({ message: "User not found." });
        }

        // Create Reset Token (For now, just a random code)
        const resetToken = Math.floor(100000 + Math.random() * 900000).toString();

        // Save Reset Token in Database (Optional)
        user.resetToken = resetToken;
        await user.save();

        // Send Email with Reset Token
        let transporter = nodemailer.createTransport({
            service: "gmail",
            auth: {
                user: "dhiadriss@gmail.com", //  Change this
                pass: "uljq jtal pcxp uufe" //  Change this
            }
        });

        await transporter.sendMail({
            from: "noreply@kariago.com",
            to: email,
            subject: "Password Reset Code",
            text: `Your password reset code is: ${resetToken}`,
        });

        res.json({ message: "Password reset email sent!" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Update User Profile
router.put('/:id', async (req, res) => {
  try {
      const { fullName, num_phone, email, profile_picture } = req.body;
      const userId = req.params.id;

      // Ensure that restricted fields are not modified
      const updateData = { fullName, num_phone, email, profile_picture };

      const user = await User.findByIdAndUpdate(userId, updateData, { new: true });
      if (!user) return res.status(404).json({ message: "User not found" });

      res.json({ message: "Profile updated successfully", user });
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

      //  Ensure email is not empty or null
      if (!email.trim()) {
          return res.status(400).json({ message: "Email cannot be empty" });
      }

      //  Check if user already exists
      let user = await User.findOne({ email });
      if (user) {
          return res.status(400).json({ message: "User already exists with this email" });
      }

      //  Hash password
      const hashedPassword = await bcrypt.hash(password, 10);

      //  Create new user
      user = new User({ cin, permis, num_phone, email, password: hashedPassword });

      await user.save();
      res.status(201).json({ message: "User registered successfully", user });

  } catch (err) {
      console.error(" Error:", err.message);
      res.status(500).json({ error: err.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
      const { email, password } = req.body;
      
      // Debug: Check if user exists
      const user = await User.findOne({ email });
      if (!user) {
          console.log(" User not found:", email);
          return res.status(400).json({ message: "Invalid credentials" });
      }

      console.log(" User found:", user);

      // Debug: Compare passwords
      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) {
          console.log(" Password mismatch");
          return res.status(400).json({ message: "Invalid credentials" });
      }

      // Generate JWT Token
      const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });

      console.log("Login Successful");
      res.json({ token, user });

  } catch (err) {
      console.error(" Error:", err.message);
      res.status(500).json({ error: err.message });
  }
});

//  Get all users (Add a debug message)
router.get('/', async (req, res) => {
  try {
      console.log(" GET /api/users request received"); // Debugging log
      const users = await User.find({}, { password: 0 }); // Exclude passwords for security
      res.json(users);
  } catch (err) {
      console.error(" Error:", err.message);
      res.status(500).json({ error: err.message });
  }
});

//  Get a single user by ID
router.get('/:id', async (req, res) => {
  try {
      const user = await User.findById(req.params.id, { password: 0 });
      if (!user) return res.status(404).json({ message: "User not found" });

      res.json(user);
  } catch (err) {
      console.error("Error:", err.message);
      res.status(500).json({ error: err.message });
  }
});


module.exports = router;
