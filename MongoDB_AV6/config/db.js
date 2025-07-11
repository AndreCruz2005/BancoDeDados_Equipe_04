require('dotenv').config(); 
const mongoose = require("mongoose");

mongoose
    .connect(process.env.DATABASE_URI)
    .then(() => console.log("MongoDB connected"))
    .catch((err) => console.error("MongoDB connection error:", err));

module.exports = mongoose;
