import { Request, Response, NextFunction } from 'express';
import { logger } from '../core/logger';

/**
 * Middleware que loga todas as requisições HTTP com cores.
 * Registra: método, path, status code e duração em ms.
 */
export function requestLoggerMiddleware(req: Request, res: Response, next: NextFunction): void {
  const inicio = Date.now();

  res.on('finish', () => {
    const duracao = Date.now() - inicio;
    logger.requisicao(req.method, req.originalUrl, res.statusCode, duracao);
  });

  next();
}
