import fs from 'node:fs';
import path from 'node:path';
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { config } from './config.js';
import { connectDb } from './db.js';
import { runSeed } from './seed.js';
import { errorHandler } from './middleware/error.js';
import { authRouter } from './routes/auth.js';
import { healthRouter } from './routes/health.js';
import { closingsRouter } from './routes/closings.js';
import { webpostoRouter } from './routes/webposto.js';

async function main() {
  await connectDb();
  fs.mkdirSync(config.couponsUploadDir, { recursive: true });
  await runSeed();

  const app = express();
  app.set('trust proxy', 1);
  app.use(
    cors({
      origin: config.corsOrigin === '*' ? true : config.corsOrigin,
      allowedHeaders: ['Origin', 'Content-Type', 'Authorization'],
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    }),
  );
  app.use(morgan('tiny'));
  app.use(express.json({ limit: '15mb' }));

  app.use('/health', healthRouter);
  app.use('/auth', authRouter);
  app.use('/closings', closingsRouter);
  app.use('/webposto', webpostoRouter);

  if (fs.existsSync(config.clientDist)) {
    app.use(express.static(config.clientDist));
    app.get('*', (req, res, next) => {
      if (req.path.startsWith('/auth') || req.path.startsWith('/closings') || req.path.startsWith('/webposto') || req.path.startsWith('/health')) {
        return next();
      }
      res.sendFile(path.join(config.clientDist, 'index.html'));
    });
  }

  app.use(errorHandler);

  app.listen(config.port, () => {
    console.log(`API em http://localhost:${config.port}`);
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
