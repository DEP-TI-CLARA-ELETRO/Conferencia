import mongoose from 'mongoose';
import { v4 as uuidv4 } from 'uuid';

const ocrRunSchema = new mongoose.Schema(
  {
    engine: { type: String, required: true },
    rawText: { type: String, default: null },
    parsed: { type: mongoose.Schema.Types.Mixed, default: {} },
    confidence: { type: Number, default: null },
    error: { type: String, default: null },
  },
  { _id: false },
);

const couponSchema = new mongoose.Schema(
  {
    _id: { type: String, default: () => uuidv4() },
    closingId: { type: String, required: true, index: true },
    storagePath: { type: String, required: true },
    filename: { type: String, required: true },
    contentType: { type: String, default: 'image/jpeg' },
    status: {
      type: String,
      enum: ['uploaded', 'ocr_pending', 'ocr_ready', 'confirmed', 'failed'],
      default: 'uploaded',
    },
    proposedValues: { type: mongoose.Schema.Types.Mixed, default: {} },
    confirmedValues: { type: mongoose.Schema.Types.Mixed, default: null },
    matchResult: { type: mongoose.Schema.Types.Mixed, default: null },
    ocrWarning: { type: String, default: null },
    ocrRuns: { type: [ocrRunSchema], default: [] },
    createdBy: { type: String, default: null },
    confirmedBy: { type: String, default: null },
    confirmedAt: { type: Date, default: null },
  },
  { timestamps: { createdAt: true, updatedAt: true } },
);

export const ClosingCoupon = mongoose.model('ClosingCoupon', couponSchema);
