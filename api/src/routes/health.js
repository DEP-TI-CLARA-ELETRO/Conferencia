import { Router } from 'express';
import mongoose from 'mongoose';

export const healthRouter = Router();

healthRouter.get('/', (_req, res) => {
  const db = mongoose.connection.readyState === 1 ? 'up' : 'down';
  res.json({ status: db === 'up' ? 'ok' : 'degraded', db });
});
