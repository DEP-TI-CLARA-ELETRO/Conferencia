import mongoose from 'mongoose';

const roleSchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  permissions: [{ type: String }],
});

export const Role = mongoose.model('Role', roleSchema);
