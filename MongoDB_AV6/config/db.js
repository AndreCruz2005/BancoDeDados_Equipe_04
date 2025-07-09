const mongoose = require('mongoose');

mongoose.connect('mongodb://localhost:25000/sportsDB')
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.error('MongoDB connection error:', err));
