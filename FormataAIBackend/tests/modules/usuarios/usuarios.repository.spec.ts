import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock do prisma
vi.mock('../../../src/database/prisma', () => ({
  default: {
    usuario: {
      create: vi.fn(),
      findUnique: vi.fn(),
      update: vi.fn(),
      updateMany: vi.fn(),
      delete: vi.fn(),
    },
  },
}));

import prisma from '../../../src/database/prisma';
import * as repo from '../../../src/modules/usuarios/usuarios.repository';

describe('usuarios.repository', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('criarUsuario', () => {
    it('deve chamar prisma.usuario.create com dados corretos', async () => {
      const dados = { nome: 'Test', email: 'test@test.com', senha: 'hash' };
      vi.mocked(prisma.usuario.create).mockResolvedValueOnce({ id: '1', ...dados } as any);

      const result = await repo.criarUsuario(dados);

      expect(prisma.usuario.create).toHaveBeenCalledWith({ data: dados });
      expect(result.id).toBe('1');
    });
  });

  describe('buscarUsuarioPorEmail', () => {
    it('deve buscar por email', async () => {
      vi.mocked(prisma.usuario.findUnique).mockResolvedValueOnce({ id: '1' } as any);

      const result = await repo.buscarUsuarioPorEmail('test@test.com');

      expect(prisma.usuario.findUnique).toHaveBeenCalledWith({ where: { email: 'test@test.com' } });
      expect(result?.id).toBe('1');
    });

    it('deve retornar null se não encontrar', async () => {
      vi.mocked(prisma.usuario.findUnique).mockResolvedValueOnce(null);

      const result = await repo.buscarUsuarioPorEmail('nope@test.com');

      expect(result).toBeNull();
    });
  });

  describe('buscarUsuarioPorId', () => {
    it('deve buscar por id', async () => {
      vi.mocked(prisma.usuario.findUnique).mockResolvedValueOnce({ id: '123' } as any);

      const result = await repo.buscarUsuarioPorId('123');

      expect(prisma.usuario.findUnique).toHaveBeenCalledWith({ where: { id: '123' } });
      expect(result?.id).toBe('123');
    });
  });

  describe('buscarUsuarioPorGoogleId', () => {
    it('deve buscar por googleId', async () => {
      vi.mocked(prisma.usuario.findUnique).mockResolvedValueOnce({ id: '1', googleId: 'g-123' } as any);

      const result = await repo.buscarUsuarioPorGoogleId('g-123');

      expect(prisma.usuario.findUnique).toHaveBeenCalledWith({ where: { googleId: 'g-123' } });
      expect(result?.id).toBe('1');
    });

    it('deve retornar null se não encontrar', async () => {
      vi.mocked(prisma.usuario.findUnique).mockResolvedValueOnce(null);

      const result = await repo.buscarUsuarioPorGoogleId('nope');

      expect(result).toBeNull();
    });
  });

  describe('atualizarUsuario', () => {
    it('deve atualizar usuário com dados parciais', async () => {
      vi.mocked(prisma.usuario.update).mockResolvedValueOnce({ id: '1', nome: 'Novo' } as any);

      const result = await repo.atualizarUsuario('1', { nome: 'Novo' });

      expect(prisma.usuario.update).toHaveBeenCalledWith({ where: { id: '1' }, data: { nome: 'Novo' } });
      expect(result.nome).toBe('Novo');
    });
  });

  describe('incrementarConsultas', () => {
    it('deve incrementar consultas do usuário', async () => {
      vi.mocked(prisma.usuario.update).mockResolvedValueOnce({ id: '1', consultasUsadas: 6 } as any);

      const result = await repo.incrementarConsultas('1');

      expect(prisma.usuario.update).toHaveBeenCalledWith({
        where: { id: '1' },
        data: { consultasUsadas: { increment: 1 } },
      });
      expect(result.consultasUsadas).toBe(6);
    });
  });

  describe('resetarConsultasMensal', () => {
    it('deve resetar consultas de todos os usuários', async () => {
      vi.mocked(prisma.usuario.updateMany).mockResolvedValueOnce({ count: 10 } as any);

      const result = await repo.resetarConsultasMensal();

      expect(prisma.usuario.updateMany).toHaveBeenCalledWith({
        data: { consultasUsadas: 0 },
      });
      expect(result.count).toBe(10);
    });
  });

  describe('deletarUsuario', () => {
    it('deve deletar usuário por id', async () => {
      vi.mocked(prisma.usuario.delete).mockResolvedValueOnce({ id: 'user-1' } as any);

      const result = await repo.deletarUsuario('user-1');

      expect(prisma.usuario.delete).toHaveBeenCalledWith({ where: { id: 'user-1' } });
      expect(result.id).toBe('user-1');
    });
  });
});
