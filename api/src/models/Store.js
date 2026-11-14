import mongoose from 'mongoose';
import { nextSeq } from './Counter.js';

const storeSchema = new mongoose.Schema(
  {
    id: { type: Number, unique: true, index: true },
    code: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    active: { type: Boolean, default: true },
    connector: { type: String, default: 'manual' },
    externalCode: { type: String, default: null },
    businessUnit: { type: String, default: null },
  },
  { timestamps: { createdAt: true, updatedAt: false } },
);

storeSchema.index({ connector: 1, externalCode: 1 });

storeSchema.pre('save', async function assignId(next) {
  if (this.isNew && this.id == null) this.id = await nextSeq('stores');
  next();
});

export const Store = mongoose.model('Store', storeSchema);
