import { Router, Request, Response, NextFunction } from 'express';
import fs from 'fs';
import path from 'path';
import { authMiddleware } from '../middlewares/auth.middleware';
import { upload } from '../middlewares/upload.middleware';
import { logger } from './logger';

type RouteHandler = (req: Request, res: Response, next: NextFunction) => void | Promise<void>;

interface Controller {
  [key: string]: RouteHandler;
}

interface ManifestRoute {
  method: string;
  path: string;
  handler: string;
  auth?: boolean;
  upload?: string;
}

interface ManifestModule {
  moduleName: string;
  controller: string;
  routes: ManifestRoute[];
}

interface Manifest {
  generatedAt: string;
  modules: ManifestModule[];
}

export function criarRouter(): Router {
  const router = Router();
  const manifestPath = path.join(process.cwd(), 'manifest.json');

  if (!fs.existsSync(manifestPath)) {
    logger.erro('ROUTER', 'manifest.json não encontrado! Execute: npm run manifest');
    return router;
  }

  const manifest: Manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf-8'));
  logger.info('ROUTER', `Carregando manifest.json (gerado em ${manifest.generatedAt})`);

  const modulesDir = path.join(__dirname, '..', 'modules');

  for (const mod of manifest.modules) {
    const controllerPath = path.join(modulesDir, mod.moduleName, mod.controller);
    let controller: Controller;

    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      controller = require(controllerPath);
    } catch (err) {
      logger.aviso('ROUTER', `Controller não encontrado para "${mod.moduleName}"`);
      continue;
    }

    for (const route of mod.routes) {
      const handlerFn = controller[route.handler];

      if (typeof handlerFn !== 'function') {
        logger.aviso('ROUTER', `Handler "${route.handler}" não encontrado em ${mod.controller}`);
        continue;
      }

      const fullPath = `/${mod.moduleName}${route.path}`;
      const method = route.method.toLowerCase() as 'get' | 'post' | 'put' | 'delete' | 'patch';

      const middlewares: RouteHandler[] = [];
      if (route.auth) {
        middlewares.push(authMiddleware);
      }
      if (route.upload) {
        middlewares.push(upload.single(route.upload) as unknown as RouteHandler);
      }

      router[method](fullPath, ...middlewares, handlerFn);
      logger.sucesso('ROUTER', `${route.method} /api${fullPath} → ${mod.controller}.${route.handler}${route.auth ? ' (Auth)' : ''}${route.upload ? ' (Upload)' : ''}`);
    }
  }

  return router;
}
