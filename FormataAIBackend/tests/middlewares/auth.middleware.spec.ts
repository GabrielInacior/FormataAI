import { describe, it, expect, vi } from 'vitest';
import { authMiddleware } from '../../src/middlewares/auth.middleware';

// Mock do jsonwebtoken
vi.mock('jsonwebtoken', () => ({
  default: {
    verify: vi.fn(),
  },
}));

import jwt from 'jsonwebtoken';

function criarReqMock(authorization?: string) {
  return {
    headers: { authorization },
  } as any;
}

function criarResMock() {
  const res: any = {};
  res.status = vi.fn().mockReturnValue(res);
  res.json = vi.fn().mockReturnValue(res);
  return res;
}

describe('authMiddleware', () => {
  it('deve retornar 401 se não houver header authorization', () => {
    const req = criarReqMock();
    const res = criarResMock();
    const next = vi.fn();

    authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ erro: 'Token não fornecido' });
    expect(next).not.toHaveBeenCalled();
  });

  it('deve retornar 401 se formato do token for inválido', () => {
    const req = criarReqMock('InvalidFormat token123');
    const res = criarResMock();
    const next = vi.fn();

    authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ erro: 'Formato de token inválido' });
  });

  it('deve retornar 401 se token tiver apenas uma parte', () => {
    const req = criarReqMock('tokenSemBearer');
    const res = criarResMock();
    const next = vi.fn();

    authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  it('deve chamar next e definir req.usuario se token for válido', () => {
    const payload = { id: 'user-123', email: 'test@test.com' };
    vi.mocked(jwt.verify).mockReturnValue(payload as any);

    const req = criarReqMock('Bearer validtoken');
    const res = criarResMock();
    const next = vi.fn();

    authMiddleware(req, res, next);

    expect(req.usuario).toEqual(payload);
    expect(next).toHaveBeenCalled();
  });

  it('deve retornar 401 se jwt.verify lançar erro', () => {
    vi.mocked(jwt.verify).mockImplementation(() => {
      throw new Error('token inválido');
    });

    const req = criarReqMock('Bearer invalidtoken');
    const res = criarResMock();
    const next = vi.fn();

    authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ erro: 'Token inválido ou expirado' });
    expect(next).not.toHaveBeenCalled();
  });
});
