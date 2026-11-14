import mongoose from 'mongoose';

const auditSchema = new mongoose.Schema({
  userId: { type: String, default: null, index: true },
  action: { type: String, required: true },
  entity: { type: String, default: null },
  entityId: { type: String, default: null },
  details: { type: mongoose.Schema.Types.Mixed, default: null },
  ip: { type: String, default: null },
  createdAt: { type: Date, default: Date.now },
});

export const AuditLog = mongoose.model('AuditLog', auditSchema);
