import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mocks
vi.mock('../../../src/core/logger', () => ({
  logger: { erro: vi.fn() },
}));

vi.mock('../../../src/database/prisma', () => ({
  default: {},
}));

vi.mock('../../../src/modules/usuarios/usuarios.repository', () => ({
  buscarUsuarioPorEmail: vi.fn(),
  buscarUsuarioPorId: vi.fn(),
  buscarUsuarioPorGoogleId: vi.fn(),
  criarUsuario: vi.fn(),
  atualizarUsuario: vi.fn(),
  deletarUsuario: vi.fn(),
}));

vi.mock('bcryptjs', () => ({
  default: {
    hash: vi.fn().mockResolvedValue('hashed_senha'),
    compare: vi.fn(),
  },
}));

vi.mock('jsonwebtoken', () => ({
  default: {
    sign: vi.fn().mockReturnValue('jwt_token_mock'),
  },
}));

const verifyIdTokenMock = vi.hoisted(() => vi.fn());
vi.mock('google-auth-library', () => ({
  OAuth2Client: class {
    verifyIdToken = verifyIdTokenMock;
  },
}));

import * as authController from '../../../src/modules/auth/auth.controller';
import * as usuariosRepository from '../../../src/modules/usuarios/usuarios.repository';
import bcrypt from 'bcryptjs';

function criarReqMock(body: any = {}, usuario?: any) {
  return { body, usuario } as any;
}

function criarResMock() {
  const res: any = {};
  res.status = vi.fn().mockReturnValue(res);
  res.json = vi.fn().mockReturnValue(res);
  res.send = vi.fn().mockReturnValue(res);
  return res;
}

const usuarioMock = {
  id: 'user-1',
  nome: 'Test',
  email: 'test@test.com',
  senha: 'hashed',
  fotoUrl: null,
  provedor: 'EMAIL',
  googleId: null,
};

describe('auth.controller', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('rotas', () => {
    it('deve exportar 5 rotas', () => {
      expect(authController.rotas).toHaveLength(5);
    });

    it('rotas públicas devem ter auth: false', () => {
      const publicas = authController.rotas.filter((r) => !r.auth);
      expect(publicas).toHaveLength(3);
      expect(publicas.map((r) => r.path)).toEqual(
        expect.arrayContaining(['/registrar', '/login', '/google']),
      );
    });

    it('rotas protegidas devem ter auth: true', () => {
      const protegidas = authController.rotas.filter((r) => r.auth);
      expect(protegidas).toHaveLength(2);
      expect(protegidas.map((r) => r.path)).toEqual(
        expect.arrayContaining(['/alterar-senha', '/deletar-conta']),
      );
    });
  });

  describe('registrar', () => {
    it('deve retornar 400 se faltar campos obrigatórios', async () => {
      const res = criarResMock();
      await authController.registrar(criarReqMock({}), res);
      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('deve retornar 409 se email já existir', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorEmail).mockResolvedValueOnce(usuarioMock as any);

      const res = criarResMock();
      await authController.registrar(
        criarReqMock({ nome: 'Test', email: 'test@test.com', senha: '123456' }),
        res,
      );
      expect(res.status).toHaveBeenCalledWith(409);
    });

    it('deve criar usuário e retornar 201 com token', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorEmail).mockResolvedValueOnce(null);
      vi.mocked(usuariosRepository.criarUsuario).mockResolvedValueOnce(usuarioMock as any);

      const res = criarResMock();
      await authController.registrar(
        criarReqMock({ nome: 'Test', email: 'test@test.com', senha: '123456' }),
        res,
      );

      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          token: 'jwt_token_mock',
          usuario: expect.objectContaining({ id: 'user-1', provedor: 'EMAIL' }),
        }),
      );
    });

    it('deve retornar 500 em caso de erro', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorEmail).mockRejectedValueOnce(new Error('db'));

      const res = criarResMock();
      await authController.registrar(
        criarReqMock({ nome: 'Test', email: 'test@test.com', senha: '123' }),
        res,
      );
      expect(res.status).toHaveBeenCalledWith(500);
    });
  });

  describe('login', () => {
    it('deve retornar 400 se faltar campos', async () => {
      const res = criarResMock();
      await authController.login(criarReqMock({}), res);
      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('deve retornar 401 se usuário não existir', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorEmail).mockResolvedValueOnce(null);

      const res = criarResMock();
      await authController.login(criarReqMock({ email: 'x@x.com', senha: '123' }), res);
      expect(res.status).toHaveBeenCalledWith(401);
    });

    it('deve retornar 401 se usuário não tiver senha (conta Google)', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorEmail).mockResolvedValueOnce({
        ...usuarioMock,
        senha: null,
        provedor: 'GOOGLE',
      } as any);

      const res = criarResMock();
      await authController.login(criarReqMock({ email: 'x@x.com', senha: '123' }), res);
      expect(res.status).toHaveBeenCalledWith(401);
    });

    it('deve retornar 401 se senha for inválida', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorEmail).mockResolvedValueOnce(usuarioMock as any);
      vi.mocked(bcrypt.compare).mockResolvedValueOnce(false as never);

      const res = criarResMock();
      await authController.login(criarReqMock({ email: 'x@x.com', senha: 'wrong' }), res);
      expect(res.status).toHaveBeenCalledWith(401);
    });

    it('deve retornar token se credenciais forem válidas', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorEmail).mockResolvedValueOnce(usuarioMock as any);
      vi.mocked(bcrypt.compare).mockResolvedValueOnce(true as never);

      const res = criarResMock();
      await authController.login(criarReqMock({ email: 'x@x.com', senha: 'correct' }), res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          token: 'jwt_token_mock',
          usuario: expect.objectContaining({ id: 'user-1' }),
        }),
      );
    });

    it('deve retornar 500 em caso de erro', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorEmail).mockRejectedValueOnce(new Error('fail'));

      const res = criarResMock();
      await authController.login(criarReqMock({ email: 'x@x.com', senha: '123' }), res);
      expect(res.status).toHaveBeenCalledWith(500);
    });
  });

  describe('googleAuth', () => {
    it('deve retornar 400 se idToken não for enviado', async () => {
      const res = criarResMock();
      await authController.googleAuth(criarReqMock({}), res);
      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('deve retornar 401 se token do Google for inválido', async () => {
      verifyIdTokenMock.mockResolvedValueOnce({ getPayload: () => null });

      const res = criarResMock();
      await authController.googleAuth(criarReqMock({ idToken: 'bad-token' }), res);
      expect(res.status).toHaveBeenCalledWith(401);
    });

    it('deve retornar token para usuário Google existente', async () => {
      verifyIdTokenMock.mockResolvedValueOnce({
        getPayload: () => ({ sub: 'google-123', email: 'g@test.com', name: 'G User', picture: 'url' }),
      });
      vi.mocked(usuariosRepository.buscarUsuarioPorGoogleId).mockResolvedValueOnce(usuarioMock as any);

      const res = criarResMock();
      await authController.googleAuth(criarReqMock({ idToken: 'valid-token' }), res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ token: 'jwt_token_mock' }),
      );
    });

    it('deve vincular Google a conta existente por email', async () => {
      verifyIdTokenMock.mockResolvedValueOnce({
        getPayload: () => ({ sub: 'google-123', email: 'test@test.com', name: 'Test', picture: 'url' }),
      });
      vi.mocked(usuariosRepository.buscarUsuarioPorGoogleId).mockResolvedValueOnce(null);
      vi.mocked(usuariosRepository.buscarUsuarioPorEmail).mockResolvedValueOnce(usuarioMock as any);
      vi.mocked(usuariosRepository.atualizarUsuario).mockResolvedValueOnce({
        ...usuarioMock,
        googleId: 'google-123',
        provedor: 'GOOGLE',
      } as any);

      const res = criarResMock();
      await authController.googleAuth(criarReqMock({ idToken: 'valid-token' }), res);

      expect(usuariosRepository.atualizarUsuario).toHaveBeenCalled();
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ token: 'jwt_token_mock' }),
      );
    });

    it('deve criar conta nova via Google', async () => {
      verifyIdTokenMock.mockResolvedValueOnce({
        getPayload: () => ({ sub: 'google-new', email: 'new@test.com', name: 'New User', picture: 'pic' }),
      });
      vi.mocked(usuariosRepository.buscarUsuarioPorGoogleId).mockResolvedValueOnce(null);
      vi.mocked(usuariosRepository.buscarUsuarioPorEmail).mockResolvedValueOnce(null);
      vi.mocked(usuariosRepository.criarUsuario).mockResolvedValueOnce({
        ...usuarioMock,
        id: 'new-user',
        email: 'new@test.com',
        googleId: 'google-new',
        provedor: 'GOOGLE',
      } as any);

      const res = criarResMock();
      await authController.googleAuth(criarReqMock({ idToken: 'valid-token' }), res);

      expect(usuariosRepository.criarUsuario).toHaveBeenCalledWith(
        expect.objectContaining({ googleId: 'google-new', provedor: 'GOOGLE' }),
      );
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ token: 'jwt_token_mock' }),
      );
    });

    it('deve retornar 401 em caso de erro na verificação', async () => {
      verifyIdTokenMock.mockRejectedValueOnce(new Error('google error'));

      const res = criarResMock();
      await authController.googleAuth(criarReqMock({ idToken: 'bad' }), res);
      expect(res.status).toHaveBeenCalledWith(401);
    });
  });

  describe('alterarSenha', () => {
    it('deve retornar 400 se novaSenha não for enviada', async () => {
      const res = criarResMock();
      await authController.alterarSenha(criarReqMock({}, { id: 'user-1' }), res);
      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('deve retornar 404 se usuário não existir', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce(null);

      const res = criarResMock();
      await authController.alterarSenha(
        criarReqMock({ novaSenha: 'nova123' }, { id: 'user-1' }),
        res,
      );
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('deve exigir senha atual se usuário tiver senha', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce(usuarioMock as any);

      const res = criarResMock();
      await authController.alterarSenha(
        criarReqMock({ novaSenha: 'nova123' }, { id: 'user-1' }),
        res,
      );
      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('deve retornar 401 se senha atual estiver incorreta', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce(usuarioMock as any);
      vi.mocked(bcrypt.compare).mockResolvedValueOnce(false as never);

      const res = criarResMock();
      await authController.alterarSenha(
        criarReqMock({ senhaAtual: 'wrong', novaSenha: 'nova123' }, { id: 'user-1' }),
        res,
      );
      expect(res.status).toHaveBeenCalledWith(401);
    });

    it('deve alterar senha com sucesso', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce(usuarioMock as any);
      vi.mocked(bcrypt.compare).mockResolvedValueOnce(true as never);
      vi.mocked(usuariosRepository.atualizarUsuario).mockResolvedValueOnce(usuarioMock as any);

      const res = criarResMock();
      await authController.alterarSenha(
        criarReqMock({ senhaAtual: 'correct', novaSenha: 'nova123' }, { id: 'user-1' }),
        res,
      );

      expect(res.json).toHaveBeenCalledWith({ mensagem: 'Senha alterada com sucesso' });
    });

    it('deve permitir criar senha para conta Google (sem senha atual)', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce({
        ...usuarioMock,
        senha: null,
        provedor: 'GOOGLE',
      } as any);
      vi.mocked(usuariosRepository.atualizarUsuario).mockResolvedValueOnce(usuarioMock as any);

      const res = criarResMock();
      await authController.alterarSenha(
        criarReqMock({ novaSenha: 'nova123' }, { id: 'user-1' }),
        res,
      );

      expect(res.json).toHaveBeenCalledWith({ mensagem: 'Senha alterada com sucesso' });
    });

    it('deve retornar 500 em caso de erro', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockRejectedValueOnce(new Error('db'));

      const res = criarResMock();
      await authController.alterarSenha(
        criarReqMock({ novaSenha: 'nova' }, { id: 'user-1' }),
        res,
      );
      expect(res.status).toHaveBeenCalledWith(500);
    });
  });

  describe('deletarConta', () => {
    it('deve deletar conta e retornar 204', async () => {
      vi.mocked(usuariosRepository.deletarUsuario).mockResolvedValueOnce(usuarioMock as any);

      const res = criarResMock();
      await authController.deletarConta(criarReqMock({}, { id: 'user-1' }), res);

      expect(usuariosRepository.deletarUsuario).toHaveBeenCalledWith('user-1');
      expect(res.status).toHaveBeenCalledWith(204);
      expect(res.send).toHaveBeenCalled();
    });

    it('deve retornar 500 em caso de erro', async () => {
      vi.mocked(usuariosRepository.deletarUsuario).mockRejectedValueOnce(new Error('db'));

      const res = criarResMock();
      await authController.deletarConta(criarReqMock({}, { id: 'user-1' }), res);
      expect(res.status).toHaveBeenCalledWith(500);
    });
  });
});
