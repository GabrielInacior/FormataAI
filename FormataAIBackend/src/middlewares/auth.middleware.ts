import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../core/env';
import { logger } from '../core/logger';

export interface TokenPayload {
  id: string;
  email: string;
}

declare global {
  namespace Express {
    interface Request {
      usuario?: TokenPayload;
    }
  }
}

export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    logger.aviso('AUTH', `401 Token não fornecido — ${req.method} ${req.originalUrl}`);
    res.status(401).json({ erro: 'Token não fornecido' });
    return;
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    logger.aviso('AUTH', `401 Formato inválido — ${req.method} ${req.originalUrl}`);
    res.status(401).json({ erro: 'Formato de token inválido' });
    return;
  }

  const token = parts[1];

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET) as TokenPayload;
    req.usuario = decoded;
    next();
  } catch (err) {
    logger.aviso('AUTH', `401 Token inválido/expirado — ${req.method} ${req.originalUrl} — ${(err as Error).message}`);
    res.status(401).json({ erro: 'Token inválido ou expirado' });
  }
}
