import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock do prisma
vi.mock('../../../src/database/prisma', () => ({
  default: {
    conversa: {
      create: vi.fn(),
      findUnique: vi.fn(),
      findMany: vi.fn(),
      count: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
    },
    mensagem: {
      create: vi.fn(),
      findMany: vi.fn(),
      count: vi.fn(),
    },
  },
}));

import prisma from '../../../src/database/prisma';
import * as repo from '../../../src/modules/ia/ia.repository';

describe('ia.repository', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('criarConversa', () => {
    it('deve criar conversa com dados corretos', async () => {
      vi.mocked(prisma.conversa.create).mockResolvedValueOnce({ id: 'conv-1' } as any);

      const result = await repo.criarConversa({ usuarioId: 'user-1', titulo: 'Test', categoria: 'EMAIL' });

      expect(prisma.conversa.create).toHaveBeenCalledWith({
        data: { usuarioId: 'user-1', titulo: 'Test', categoria: 'EMAIL' },
      });
      expect(result.id).toBe('conv-1');
    });
  });

  describe('buscarConversaPorId', () => {
    it('deve buscar conversa com mensagens', async () => {
      vi.mocked(prisma.conversa.findUnique).mockResolvedValueOnce({
        id: 'conv-1',
        mensagens: [],
      } as any);

      const result = await repo.buscarConversaPorId('conv-1');

      expect(prisma.conversa.findUnique).toHaveBeenCalledWith({
        where: { id: 'conv-1' },
        include: { mensagens: { orderBy: { criadoEm: 'asc' } } },
      });
      expect(result?.id).toBe('conv-1');
    });

    it('deve retornar null se não encontrar', async () => {
      vi.mocked(prisma.conversa.findUnique).mockResolvedValueOnce(null);

      const result = await repo.buscarConversaPorId('nope');
      expect(result).toBeNull();
    });
  });

  describe('listarConversas', () => {
    it('deve listar conversas com paginação', async () => {
      vi.mocked(prisma.conversa.findMany).mockResolvedValueOnce([{ id: '1' }] as any);
      vi.mocked(prisma.conversa.count).mockResolvedValueOnce(10);

      const result = await repo.listarConversas('user-1', {}, 0, 20);

      expect(result.dados).toHaveLength(1);
      expect(result.total).toBe(10);
    });

    it('deve aplicar filtro de categoria', async () => {
      vi.mocked(prisma.conversa.findMany).mockResolvedValueOnce([]);
      vi.mocked(prisma.conversa.count).mockResolvedValueOnce(0);

      await repo.listarConversas('user-1', { categoria: 'EMAIL' }, 0, 10);

      const whereArg = vi.mocked(prisma.conversa.findMany).mock.calls[0][0]?.where;
      expect(whereArg).toMatchObject({ categoria: 'EMAIL' });
    });

    it('deve aplicar filtro de busca', async () => {
      vi.mocked(prisma.conversa.findMany).mockResolvedValueOnce([]);
      vi.mocked(prisma.conversa.count).mockResolvedValueOnce(0);

      await repo.listarConversas('user-1', { busca: 'email formal' }, 0, 10);

      const whereArg = vi.mocked(prisma.conversa.findMany).mock.calls[0][0]?.where;
      expect(whereArg).toHaveProperty('OR');
    });

    it('deve aplicar filtro de data', async () => {
      vi.mocked(prisma.conversa.findMany).mockResolvedValueOnce([]);
      vi.mocked(prisma.conversa.count).mockResolvedValueOnce(0);

      const dataInicio = new Date('2024-01-01');
      const dataFim = new Date('2024-12-31');
      await repo.listarConversas('user-1', { dataInicio, dataFim }, 0, 10);

      const whereArg = vi.mocked(prisma.conversa.findMany).mock.calls[0][0]?.where;
      expect(whereArg).toHaveProperty('criadoEm');
    });

    it('deve aplicar filtro de favoritada e arquivada', async () => {
      vi.mocked(prisma.conversa.findMany).mockResolvedValueOnce([]);
      vi.mocked(prisma.conversa.count).mockResolvedValueOnce(0);

      await repo.listarConversas('user-1', { favoritada: true, arquivada: false }, 0, 10);

      const whereArg = vi.mocked(prisma.conversa.findMany).mock.calls[0][0]?.where;
      expect(whereArg).toMatchObject({ favoritada: true, arquivada: false });
    });
  });

  describe('atualizarConversa', () => {
    it('deve atualizar conversa', async () => {
      vi.mocked(prisma.conversa.update).mockResolvedValueOnce({ id: '1', titulo: 'Novo' } as any);

      const result = await repo.atualizarConversa('1', { titulo: 'Novo' });

      expect(prisma.conversa.update).toHaveBeenCalledWith({ where: { id: '1' }, data: { titulo: 'Novo' } });
      expect(result.titulo).toBe('Novo');
    });
  });

  describe('deletarConversa', () => {
    it('deve deletar conversa', async () => {
      vi.mocked(prisma.conversa.delete).mockResolvedValueOnce({ id: '1' } as any);

      await repo.deletarConversa('1');

      expect(prisma.conversa.delete).toHaveBeenCalledWith({ where: { id: '1' } });
    });
  });

  describe('criarMensagem', () => {
    it('deve criar mensagem', async () => {
      vi.mocked(prisma.mensagem.create).mockResolvedValueOnce({ id: 'msg-1' } as any);

      const result = await repo.criarMensagem({
        conversaId: 'conv-1',
        tipo: 'USUARIO',
        conteudo: 'Olá',
      });

      expect(prisma.mensagem.create).toHaveBeenCalledWith({
        data: { conversaId: 'conv-1', tipo: 'USUARIO', conteudo: 'Olá' },
      });
      expect(result.id).toBe('msg-1');
    });
  });

  describe('listarMensagens', () => {
    it('deve listar mensagens com paginação', async () => {
      vi.mocked(prisma.mensagem.findMany).mockResolvedValueOnce([{ id: 'msg-1' }] as any);
      vi.mocked(prisma.mensagem.count).mockResolvedValueOnce(5);

      const result = await repo.listarMensagens('conv-1', 0, 20);

      expect(result.dados).toHaveLength(1);
      expect(result.total).toBe(5);
    });
  });
});
