import { describe, it, expect, vi } from 'vitest';

vi.mock('../../src/core/logger', () => ({
  logger: {
    requisicao: vi.fn(),
  },
}));

import { requestLoggerMiddleware } from '../../src/middlewares/request-logger.middleware';
import { logger } from '../../src/core/logger';

describe('requestLoggerMiddleware', () => {
  it('deve registrar listener no evento finish e chamar next', () => {
    const req = { method: 'GET', originalUrl: '/api/health' } as any;
    const res = { on: vi.fn() } as any;
    const next = vi.fn();

    requestLoggerMiddleware(req, res, next);

    expect(res.on).toHaveBeenCalledWith('finish', expect.any(Function));
    expect(next).toHaveBeenCalled();
  });

  it('deve chamar logger.requisicao quando finish dispara', () => {
    const req = { method: 'POST', originalUrl: '/api/auth/login' } as any;
    let finishCallback: Function = () => {};
    const res = {
      on: vi.fn((event: string, cb: Function) => { finishCallback = cb; }),
      statusCode: 200,
    } as any;
    const next = vi.fn();

    requestLoggerMiddleware(req, res, next);
    finishCallback();

    expect(logger.requisicao).toHaveBeenCalledWith('POST', '/api/auth/login', 200, expect.any(Number));
  });
});
