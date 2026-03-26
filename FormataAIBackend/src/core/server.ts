import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { env } from './env';
import { criarRouter } from './router';
import { logger } from './logger';
import { iniciarCronJobs } from './cron';
import { errorMiddleware } from '../middlewares/error.middleware';
import { requestLoggerMiddleware } from '../middlewares/request-logger.middleware';

export function criarServidor() {
  const app = express();

  // Confia no proxy reverso (nginx)
  app.set('trust proxy', 1);

  // Segurança
  app.use(helmet());
  app.use(cors());

  // Rate limiting
  app.use(rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 100,
    message: { erro: 'Muitas requisições. Tente novamente mais tarde.' },
  }));

  // Body parsing
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));

  // Logger de requisições (colorido)
  app.use(requestLoggerMiddleware);

  // Health check
  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  // Rotas dos módulos (auto-registradas via manifest.json)
  const router = criarRouter();
  app.use('/api', router);

  // Middleware de erros (deve ser o último)
  app.use(errorMiddleware);

  return app;
}

export function iniciarServidor() {
  const app = criarServidor();

  app.listen(env.PORT, () => {
    logger.banner(env.PORT, env.NODE_ENV);
  });

  // Iniciar jobs agendados
  iniciarCronJobs();

  return app;
}
