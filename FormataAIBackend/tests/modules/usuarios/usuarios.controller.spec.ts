import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../../src/core/logger', () => ({
  logger: { erro: vi.fn() },
}));

vi.mock('../../../src/modules/usuarios/usuarios.repository', () => ({
  buscarUsuarioPorId: vi.fn(),
  atualizarUsuario: vi.fn(),
}));

import * as usuariosController from '../../../src/modules/usuarios/usuarios.controller';
import * as usuariosRepository from '../../../src/modules/usuarios/usuarios.repository';

function criarReqMock(overrides: any = {}) {
  return {
    usuario: { id: 'user-1', email: 'test@test.com' },
    body: {},
    ...overrides,
  } as any;
}

function criarResMock() {
  const res: any = {};
  res.status = vi.fn().mockReturnValue(res);
  res.json = vi.fn().mockReturnValue(res);
  return res;
}

const usuarioMock = {
  id: 'user-1',
  nome: 'Test',
  email: 'test@test.com',
  senha: 'hashed',
  fotoUrl: null,
  provedor: 'EMAIL',
  ativo: true,
  consultasUsadas: 5,
  limiteConsultas: 50,
  plano: 'GRATUITO',
};

describe('usuarios.controller', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('rotas', () => {
    it('deve exportar 3 rotas', () => {
      expect(usuariosController.rotas).toHaveLength(3);
    });

    it('todas rotas devem ter auth: true', () => {
      usuariosController.rotas.forEach((rota) => {
        expect(rota.auth).toBe(true);
      });
    });
  });

  describe('buscarPerfil', () => {
    it('deve retornar perfil sem senha', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce(usuarioMock as any);

      const res = criarResMock();
      await usuariosController.buscarPerfil(criarReqMock(), res);

      const jsonData = res.json.mock.calls[0][0];
      expect(jsonData.id).toBe('user-1');
      expect(jsonData.fotoUrl).toBeNull();
      expect(jsonData.provedor).toBe('EMAIL');
      expect(jsonData.senha).toBeUndefined();
    });

    it('deve retornar 404 se usuário não encontrado', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce(null);

      const res = criarResMock();
      await usuariosController.buscarPerfil(criarReqMock(), res);
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('deve retornar 500 em caso de erro', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockRejectedValueOnce(new Error('db'));

      const res = criarResMock();
      await usuariosController.buscarPerfil(criarReqMock(), res);
      expect(res.status).toHaveBeenCalledWith(500);
    });
  });

  describe('atualizarPerfil', () => {
    it('deve atualizar e retornar perfil sem senha', async () => {
      vi.mocked(usuariosRepository.atualizarUsuario).mockResolvedValueOnce({
        ...usuarioMock,
        nome: 'Novo Nome',
      } as any);

      const res = criarResMock();
      await usuariosController.atualizarPerfil(
        criarReqMock({ body: { nome: 'Novo Nome' } }),
        res,
      );

      const jsonData = res.json.mock.calls[0][0];
      expect(jsonData.nome).toBe('Novo Nome');
      expect(jsonData.senha).toBeUndefined();
    });

    it('deve permitir atualizar fotoUrl', async () => {
      vi.mocked(usuariosRepository.atualizarUsuario).mockResolvedValueOnce({
        ...usuarioMock,
        fotoUrl: 'https://example.com/foto.jpg',
      } as any);

      const res = criarResMock();
      await usuariosController.atualizarPerfil(
        criarReqMock({ body: { fotoUrl: 'https://example.com/foto.jpg' } }),
        res,
      );

      expect(usuariosRepository.atualizarUsuario).toHaveBeenCalledWith(
        'user-1',
        expect.objectContaining({ fotoUrl: 'https://example.com/foto.jpg' }),
      );
    });

    it('deve retornar 500 em caso de erro', async () => {
      vi.mocked(usuariosRepository.atualizarUsuario).mockRejectedValueOnce(new Error('db'));

      const res = criarResMock();
      await usuariosController.atualizarPerfil(criarReqMock(), res);
      expect(res.status).toHaveBeenCalledWith(500);
    });
  });

  describe('estatisticas', () => {
    it('deve retornar estatísticas do usuário', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce(usuarioMock as any);

      const res = criarResMock();
      await usuariosController.estatisticas(criarReqMock(), res);

      expect(res.json).toHaveBeenCalledWith({
        consultasUsadas: 5,
        limiteConsultas: 50,
        consultasRestantes: 45,
        plano: 'GRATUITO',
      });
    });

    it('deve retornar 404 se usuário não encontrado', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce(null);

      const res = criarResMock();
      await usuariosController.estatisticas(criarReqMock(), res);
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('deve retornar 500 em caso de erro', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockRejectedValueOnce(new Error('db'));

      const res = criarResMock();
      await usuariosController.estatisticas(criarReqMock(), res);
      expect(res.status).toHaveBeenCalledWith(500);
    });
  });
});
