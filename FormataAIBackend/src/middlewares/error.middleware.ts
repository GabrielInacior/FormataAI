import { Request, Response, NextFunction } from 'express';
import { logger } from '../core/logger';

export interface AppError extends Error {
  statusCode?: number;
}

export function errorMiddleware(err: AppError, _req: Request, res: Response, _next: NextFunction): void {
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Erro interno do servidor';

  logger.erro('ERRO', `${statusCode} - ${message}`, err);

  res.status(statusCode).json({
    erro: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
}
