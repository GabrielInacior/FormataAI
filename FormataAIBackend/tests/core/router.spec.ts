import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/core/logger', () => ({
  logger: {
    info: vi.fn(),
    erro: vi.fn(),
    aviso: vi.fn(),
    sucesso: vi.fn(),
  },
}));

vi.mock('../../src/middlewares/auth.middleware', () => ({
  authMiddleware: vi.fn((_req: any, _res: any, next: any) => next()),
}));

vi.mock('../../src/middlewares/upload.middleware', () => ({
  upload: {
    single: vi.fn(() => (_req: any, _res: any, next: any) => next()),
  },
}));

import fs from 'fs';
import path from 'path';
import { logger } from '../../src/core/logger';

describe('router', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.resetModules();
  });

  it('deve retornar router vazio se manifest.json não existir', async () => {
    vi.spyOn(fs, 'existsSync').mockReturnValueOnce(false);

    const { criarRouter } = await import('../../src/core/router');
    const router = criarRouter();

    expect(router).toBeDefined();
    expect(logger.erro).toHaveBeenCalledWith('ROUTER', expect.stringContaining('manifest.json'));

    vi.restoreAllMocks();
  });

  it('deve carregar rotas do manifest.json com sucesso', async () => {
    const manifest = {
      generatedAt: '2024-01-01T00:00:00.000Z',
      modules: [
        {
          moduleName: 'auth',
          controller: 'auth.controller',
          routes: [
            { method: 'POST', path: '/login', handler: 'login', auth: false },
            { method: 'POST', path: '/registrar', handler: 'registrar', auth: false },
          ],
        },
      ],
    };

    vi.spyOn(fs, 'existsSync').mockReturnValueOnce(true);
    vi.spyOn(fs, 'readFileSync').mockReturnValueOnce(JSON.stringify(manifest));

    // Mock require para controller
    const mockController = {
      login: vi.fn(),
      registrar: vi.fn(),
    };

    // Precisamos interceptar o require dinâmico
    const originalRequire = Module.prototype.require;
    const requireSpy = vi.spyOn(Module.prototype, 'require');

    // Use implementation that returns mock for controller paths
    requireSpy.mockImplementation(function (this: any, id: string) {
      if (id.includes('auth.controller')) {
        return mockController;
      }
      return originalRequire.call(this, id);
    });

    const { criarRouter } = await import('../../src/core/router');
    const router = criarRouter();

    expect(router).toBeDefined();
    expect(logger.info).toHaveBeenCalledWith('ROUTER', expect.stringContaining('manifest.json'));
    expect(logger.sucesso).toHaveBeenCalled();

    vi.restoreAllMocks();
  });

  it('deve avisar quando controller não é encontrado', async () => {
    const manifest = {
      generatedAt: '2024-01-01T00:00:00.000Z',
      modules: [
        {
          moduleName: 'inexistente',
          controller: 'inexistente.controller',
          routes: [
            { method: 'GET', path: '/', handler: 'listar', auth: true },
          ],
        },
      ],
    };

    vi.spyOn(fs, 'existsSync').mockReturnValueOnce(true);
    vi.spyOn(fs, 'readFileSync').mockReturnValueOnce(JSON.stringify(manifest));

    const originalRequire = Module.prototype.require;
    const requireSpy = vi.spyOn(Module.prototype, 'require');
    requireSpy.mockImplementation(function (this: any, id: string) {
      if (id.includes('inexistente.controller')) {
        throw new Error('MODULE_NOT_FOUND');
      }
      return originalRequire.call(this, id);
    });

    const { criarRouter } = await import('../../src/core/router');
    const router = criarRouter();

    expect(router).toBeDefined();
    expect(logger.aviso).toHaveBeenCalledWith('ROUTER', expect.stringContaining('inexistente'));

    vi.restoreAllMocks();
  });

  it('deve avisar quando handler não é uma função', async () => {
    const manifest = {
      generatedAt: '2024-01-01T00:00:00.000Z',
      modules: [
        {
          moduleName: 'test',
          controller: 'test.controller',
          routes: [
            { method: 'GET', path: '/', handler: 'handlerInexistente', auth: false },
          ],
        },
      ],
    };

    vi.spyOn(fs, 'existsSync').mockReturnValueOnce(true);
    vi.spyOn(fs, 'readFileSync').mockReturnValueOnce(JSON.stringify(manifest));

    const mockController = {
      // handlerInexistente is NOT defined — so it's undefined, not a function
    };

    const originalRequire = Module.prototype.require;
    const requireSpy = vi.spyOn(Module.prototype, 'require');
    requireSpy.mockImplementation(function (this: any, id: string) {
      if (id.includes('test.controller')) {
        return mockController;
      }
      return originalRequire.call(this, id);
    });

    const { criarRouter } = await import('../../src/core/router');
    const router = criarRouter();

    expect(router).toBeDefined();
    expect(logger.aviso).toHaveBeenCalledWith('ROUTER', expect.stringContaining('handlerInexistente'));

    vi.restoreAllMocks();
  });

  it('deve registrar middleware de auth e upload quando configurado', async () => {
    const manifest = {
      generatedAt: '2024-01-01T00:00:00.000Z',
      modules: [
        {
          moduleName: 'ia',
          controller: 'ia.controller',
          routes: [
            { method: 'POST', path: '/processar', handler: 'processar', auth: true, upload: 'audio' },
          ],
        },
      ],
    };

    vi.spyOn(fs, 'existsSync').mockReturnValueOnce(true);
    vi.spyOn(fs, 'readFileSync').mockReturnValueOnce(JSON.stringify(manifest));

    const mockController = {
      processar: vi.fn(),
    };

    const originalRequire = Module.prototype.require;
    const requireSpy = vi.spyOn(Module.prototype, 'require');
    requireSpy.mockImplementation(function (this: any, id: string) {
      if (id.includes('ia.controller')) {
        return mockController;
      }
      return originalRequire.call(this, id);
    });

    const { criarRouter } = await import('../../src/core/router');
    const router = criarRouter();

    expect(router).toBeDefined();
    expect(logger.sucesso).toHaveBeenCalledWith(
      'ROUTER',
      expect.stringContaining('(Auth)'),
    );
    expect(logger.sucesso).toHaveBeenCalledWith(
      'ROUTER',
      expect.stringContaining('(Upload)'),
    );

    vi.restoreAllMocks();
  });
});

// Need Module for require spy
import Module from 'module';
