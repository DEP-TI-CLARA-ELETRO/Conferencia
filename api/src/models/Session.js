import mongoose from 'mongoose';
import { v4 as uuidv4 } from 'uuid';

const sessionSchema = new mongoose.Schema({
  _id: { type: String, default: () => uuidv4() },
  userId: { type: String, required: true, index: true },
  tokenHash: { type: String, required: true, unique: true },
  createdAt: { type: Date, default: Date.now },
  expiresAt: { type: Date, required: true },
  revokedAt: { type: Date, default: null },
  ip: { type: String, default: null },
  userAgent: { type: String, default: null },
});

export const Session = mongoose.model('Session', sessionSchema);
