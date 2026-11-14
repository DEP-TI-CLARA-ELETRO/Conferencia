import mongoose from 'mongoose';
import { v4 as uuidv4 } from 'uuid';

const userRoleSchema = new mongoose.Schema(
  {
    roleCode: { type: String, required: true },
    storeId: { type: Number, default: null },
  },
  { _id: false },
);

const userSchema = new mongoose.Schema(
  {
    _id: { type: String, default: () => uuidv4() },
    email: { type: String, required: true, unique: true, lowercase: true },
    name: { type: String, required: true },
    registration: { type: String, default: null },
    passwordHash: { type: String, required: true },
    active: { type: Boolean, default: true },
    lastLoginAt: { type: Date, default: null },
    roles: { type: [userRoleSchema], default: [] },
  },
  { timestamps: { createdAt: true, updatedAt: false } },
);

export const User = mongoose.model('User', userSchema);
