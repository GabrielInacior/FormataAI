import { describe, it, expect, vi } from 'vitest';

vi.mock('../../src/core/logger', () => ({
  logger: {
    erro: vi.fn(),
  },
}));

import { errorMiddleware, AppError } from '../../src/middlewares/error.middleware';

function criarReqMock() {
  return {} as any;
}

function criarResMock() {
  const res: any = {};
  res.status = vi.fn().mockReturnValue(res);
  res.json = vi.fn().mockReturnValue(res);
  return res;
}

describe('errorMiddleware', () => {
  it('deve retornar 500 como status padrão', () => {
    const err: AppError = new Error('algo deu errado');
    const res = criarResMock();

    errorMiddleware(err, criarReqMock(), res, vi.fn());

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ erro: 'algo deu errado' }));
  });

  it('deve usar statusCode do erro se definido', () => {
    const err: AppError = new Error('não encontrado');
    err.statusCode = 404;
    const res = criarResMock();

    errorMiddleware(err, criarReqMock(), res, vi.fn());

    expect(res.status).toHaveBeenCalledWith(404);
  });

  it('deve incluir stack em ambiente development', () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';

    const err = new Error('erro dev');
    const res = criarResMock();

    errorMiddleware(err, criarReqMock(), res, vi.fn());

    const jsonCall = res.json.mock.calls[0][0];
    expect(jsonCall.stack).toBeDefined();

    process.env.NODE_ENV = originalEnv;
  });

  it('não deve incluir stack em ambiente production', () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';

    const err = new Error('erro prod');
    const res = criarResMock();

    errorMiddleware(err, criarReqMock(), res, vi.fn());

    const jsonCall = res.json.mock.calls[0][0];
    expect(jsonCall.stack).toBeUndefined();

    process.env.NODE_ENV = originalEnv;
  });

  it('deve usar mensagem padrão se erro não tiver mensagem', () => {
    const err: AppError = { name: 'Error', message: '' } as any;
    const res = criarResMock();

    errorMiddleware(err, criarReqMock(), res, vi.fn());

    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ erro: 'Erro interno do servidor' }));
  });
});
