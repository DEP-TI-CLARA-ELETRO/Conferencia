import mongoose from 'mongoose';
import { v4 as uuidv4 } from 'uuid';

const cashClosingSchema = new mongoose.Schema(
  {
    _id: { type: String, default: () => uuidv4() },
    storeId: { type: Number, required: true, index: true },
    connector: { type: String, default: 'webposto' },
    externalCodigo: { type: Number, default: null },
    externalCaixaCodigo: { type: Number, required: true },
    movementDate: { type: String, required: true }, // yyyy-MM-dd
    shiftCode: { type: Number, default: null },
    shiftLabel: { type: String, default: null },
    pdvCode: { type: Number, default: null },
    employeeCode: { type: Number, default: null },
    openedAt: { type: Date, default: null },
    closedAt: { type: Date, default: null },
    closed: { type: Boolean, default: false },
    consolidated: { type: Boolean, default: false },
    blocked: { type: Boolean, default: false },
    apurado: { type: Number, default: null },
    diferenca: { type: Number, default: null },
    stage: { type: String, default: 'pdv_imported' },
    paymentBreakdown: { type: mongoose.Schema.Types.Mixed, default: {} },
    rawCaixa: { type: mongoose.Schema.Types.Mixed, default: null },
    rawApresentado: { type: mongoose.Schema.Types.Mixed, default: null },
    syncedAt: { type: Date, default: null },
  },
  { timestamps: true },
);

cashClosingSchema.index(
  { storeId: 1, connector: 1, externalCaixaCodigo: 1, movementDate: 1, shiftCode: 1 },
  { unique: true },
);

export const CashClosing = mongoose.model('CashClosing', cashClosingSchema);
