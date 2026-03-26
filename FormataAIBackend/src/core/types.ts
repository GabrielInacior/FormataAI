import { Request, Response, NextFunction } from 'express';

export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';

export interface RotaConfig {
  method: HttpMethod;
  path: string;
  handler: string;
  auth?: boolean;
  upload?: string;
}

export interface ModuloConfig {
  moduleName: string;
  controller: string;
  routes: RotaConfig[];
}

export type RouteHandler = (req: Request, res: Response, next: NextFunction) => void | Promise<void>;

/**
 * Define rotas de um controller exportando um array `rotas`.
 * Cada controller deve exportar:
 *   export const rotas: RotaConfig[] = [...]
 *   export async function meuHandler(req, res) { ... }
 */
