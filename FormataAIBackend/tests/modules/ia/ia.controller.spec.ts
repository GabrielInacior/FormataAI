import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mocks
vi.mock('../../../src/core/logger', () => ({
  logger: { erro: vi.fn(), aviso: vi.fn() },
}));

vi.mock('../../../src/database/prisma', () => ({
  default: {},
}));

vi.mock('../../../src/core/s3', () => ({
  uploadArquivo: vi.fn().mockResolvedValue({ key: 'audios/test.wav', url: 'https://s3/test.wav' }),
}));

vi.mock('../../../src/core/paginacao', () => ({
  extrairPaginacao: vi.fn().mockReturnValue({ pagina: 1, limite: 20, skip: 0 }),
  extrairBusca: vi.fn().mockReturnValue(undefined),
  extrairFiltroData: vi.fn().mockReturnValue({}),
  montarPaginacao: vi.fn((dados: any, total: any, params: any) => ({
    dados,
    paginacao: { pagina: params.pagina, limite: params.limite, total, totalPaginas: 1 },
  })),
}));

vi.mock('../../../src/modules/ia/ia.repository', () => ({
  criarConversa: vi.fn(),
  buscarConversaPorId: vi.fn(),
  listarConversas: vi.fn(),
  atualizarConversa: vi.fn(),
  deletarConversa: vi.fn(),
  criarMensagem: vi.fn(),
  listarMensagens: vi.fn(),
}));

vi.mock('../../../src/modules/usuarios/usuarios.repository', () => ({
  buscarUsuarioPorId: vi.fn(),
  incrementarConsultas: vi.fn(),
}));

vi.mock('openai', () => {
  class MockOpenAI {
    audio = {
      transcriptions: {
        create: vi.fn().mockResolvedValue({ text: 'texto transcrito' }),
      },
    };
    chat = {
      completions: {
        create: vi.fn().mockResolvedValue({
          choices: [{ message: { content: JSON.stringify({ intencao: 'email', categoria: 'EMAIL', resposta: 'Prezado...' }) } }],
          usage: { total_tokens: 100 },
        }),
      },
    };
  }
  return { default: MockOpenAI };
});

import * as iaController from '../../../src/modules/ia/ia.controller';
import * as iaRepository from '../../../src/modules/ia/ia.repository';
import * as usuariosRepository from '../../../src/modules/usuarios/usuarios.repository';

function criarReqMock(overrides: any = {}) {
  return {
    usuario: { id: 'user-1', email: 'test@test.com' },
    body: {},
    query: {},
    params: {},
    file: undefined,
    ...overrides,
  } as any;
}

function criarResMock() {
  const res: any = {};
  res.status = vi.fn().mockReturnValue(res);
  res.json = vi.fn().mockReturnValue(res);
  res.send = vi.fn().mockReturnValue(res);
  return res;
}

describe('ia.controller', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('rotas', () => {
    it('deve exportar array de rotas', () => {
      expect(iaController.rotas).toBeDefined();
      expect(iaController.rotas.length).toBe(7);
    });

    it('todas rotas devem ter auth: true', () => {
      iaController.rotas.forEach((rota) => {
        expect(rota.auth).toBe(true);
      });
    });

    it('rota /processar deve ter upload', () => {
      const processarRota = iaController.rotas.find((r) => r.path === '/processar');
      expect(processarRota?.upload).toBe('audio');
    });
  });

  describe('criarConversa', () => {
    it('deve criar conversa e retornar 201', async () => {
      vi.mocked(iaRepository.criarConversa).mockResolvedValueOnce({ id: 'conv-1' } as any);

      const res = criarResMock();
      await iaController.criarConversa(
        criarReqMock({ body: { titulo: 'teste', categoria: 'EMAIL' } }),
        res,
      );

      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ id: 'conv-1' }));
    });

    it('deve retornar 500 em caso de erro', async () => {
      vi.mocked(iaRepository.criarConversa).mockRejectedValueOnce(new Error('db'));

      const res = criarResMock();
      await iaController.criarConversa(criarReqMock(), res);

      expect(res.status).toHaveBeenCalledWith(500);
    });
  });

  describe('listarConversas', () => {
    it('deve retornar lista paginada', async () => {
      vi.mocked(iaRepository.listarConversas).mockResolvedValueOnce({ dados: [], total: 0 });

      const res = criarResMock();
      await iaController.listarConversas(criarReqMock(), res);

      expect(res.json).toHaveBeenCalled();
    });

    it('deve retornar 500 em caso de erro', async () => {
      vi.mocked(iaRepository.listarConversas).mockRejectedValueOnce(new Error('db'));

      const res = criarResMock();
      await iaController.listarConversas(criarReqMock(), res);

      expect(res.status).toHaveBeenCalledWith(500);
    });
  });

  describe('buscarConversa', () => {
    it('deve retornar conversa', async () => {
      vi.mocked(iaRepository.buscarConversaPorId).mockResolvedValueOnce({
        id: 'conv-1',
        usuarioId: 'user-1',
      } as any);

      const res = criarResMock();
      await iaController.buscarConversa(criarReqMock({ params: { id: 'conv-1' } }), res);

      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ id: 'conv-1' }));
    });

    it('deve retornar 404 se conversa não encontrada', async () => {
      vi.mocked(iaRepository.buscarConversaPorId).mockResolvedValueOnce(null);

      const res = criarResMock();
      await iaController.buscarConversa(criarReqMock({ params: { id: 'nope' } }), res);

      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('deve retornar 404 se conversa pertence a outro usuário', async () => {
      vi.mocked(iaRepository.buscarConversaPorId).mockResolvedValueOnce({
        id: 'conv-1',
        usuarioId: 'outro-user',
      } as any);

      const res = criarResMock();
      await iaController.buscarConversa(criarReqMock({ params: { id: 'conv-1' } }), res);

      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('deve retornar 500 em caso de erro', async () => {
      vi.mocked(iaRepository.buscarConversaPorId).mockRejectedValueOnce(new Error('db'));

      const res = criarResMock();
      await iaController.buscarConversa(criarReqMock({ params: { id: '1' } }), res);

      expect(res.status).toHaveBeenCalledWith(500);
    });
  });

  describe('atualizarConversa', () => {
    it('deve atualizar conversa', async () => {
      vi.mocked(iaRepository.buscarConversaPorId).mockResolvedValueOnce({
        id: 'conv-1',
        usuarioId: 'user-1',
      } as any);
      vi.mocked(iaRepository.atualizarConversa).mockResolvedValueOnce({ id: 'conv-1', titulo: 'Novo' } as any);

      const res = criarResMock();
      await iaController.atualizarConversa(
        criarReqMock({ params: { id: 'conv-1' }, body: { titulo: 'Novo' } }),
        res,
      );

      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ titulo: 'Novo' }));
    });

    it('deve retornar 404 se não encontrar', async () => {
      vi.mocked(iaRepository.buscarConversaPorId).mockResolvedValueOnce(null);

      const res = criarResMock();
      await iaController.atualizarConversa(criarReqMock({ params: { id: 'nope' } }), res);

      expect(res.status).toHaveBeenCalledWith(404);
    });
  });

  describe('deletarConversa', () => {
    it('deve deletar conversa e retornar 204', async () => {
      vi.mocked(iaRepository.buscarConversaPorId).mockResolvedValueOnce({
        id: 'conv-1',
        usuarioId: 'user-1',
      } as any);
      vi.mocked(iaRepository.deletarConversa).mockResolvedValueOnce({ id: 'conv-1' } as any);

      const res = criarResMock();
      await iaController.deletarConversa(criarReqMock({ params: { id: 'conv-1' } }), res);

      expect(res.status).toHaveBeenCalledWith(204);
    });

    it('deve retornar 404 se não encontrar', async () => {
      vi.mocked(iaRepository.buscarConversaPorId).mockResolvedValueOnce(null);

      const res = criarResMock();
      await iaController.deletarConversa(criarReqMock({ params: { id: 'nope' } }), res);

      expect(res.status).toHaveBeenCalledWith(404);
    });
  });

  describe('listarMensagens', () => {
    it('deve listar mensagens de uma conversa', async () => {
      vi.mocked(iaRepository.buscarConversaPorId).mockResolvedValueOnce({
        id: 'conv-1',
        usuarioId: 'user-1',
      } as any);
      vi.mocked(iaRepository.listarMensagens).mockResolvedValueOnce({ dados: [], total: 0 });

      const res = criarResMock();
      await iaController.listarMensagens(criarReqMock({ params: { id: 'conv-1' } }), res);

      expect(res.json).toHaveBeenCalled();
    });

    it('deve retornar 404 se conversa não pertencer ao usuário', async () => {
      vi.mocked(iaRepository.buscarConversaPorId).mockResolvedValueOnce({
        id: 'conv-1',
        usuarioId: 'outro',
      } as any);

      const res = criarResMock();
      await iaController.listarMensagens(criarReqMock({ params: { id: 'conv-1' } }), res);

      expect(res.status).toHaveBeenCalledWith(404);
    });
  });

  describe('processar', () => {
    it('deve retornar 404 se usuário não encontrado', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce(null);

      const res = criarResMock();
      await iaController.processar(criarReqMock(), res);

      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('deve retornar 429 se atingiu limite', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce({
        id: 'user-1',
        consultasUsadas: 50,
        limiteConsultas: 50,
      } as any);

      const res = criarResMock();
      await iaController.processar(criarReqMock(), res);

      expect(res.status).toHaveBeenCalledWith(429);
    });

    it('deve retornar 400 se não enviar arquivo', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce({
        id: 'user-1',
        consultasUsadas: 0,
        limiteConsultas: 50,
      } as any);

      const res = criarResMock();
      await iaController.processar(criarReqMock({ file: undefined }), res);

      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('deve processar áudio com sucesso (fluxo completo)', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce({
        id: 'user-1',
        consultasUsadas: 0,
        limiteConsultas: 50,
      } as any);
      vi.mocked(iaRepository.criarConversa).mockResolvedValueOnce({ id: 'conv-new' } as any);
      vi.mocked(iaRepository.criarMensagem)
        .mockResolvedValueOnce({ id: 'msg-user' } as any)
        .mockResolvedValueOnce({ id: 'msg-ia' } as any);
      vi.mocked(usuariosRepository.incrementarConsultas).mockResolvedValueOnce({} as any);

      const res = criarResMock();
      await iaController.processar(
        criarReqMock({
          file: {
            buffer: Buffer.from('audio data'),
            originalname: 'test.wav',
            mimetype: 'audio/wav',
          },
        }),
        res,
      );

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          conversaId: 'conv-new',
          mensagemId: 'msg-ia',
          transcricao: 'texto transcrito',
        }),
      );
      expect(iaRepository.criarConversa).toHaveBeenCalled();
      expect(iaRepository.criarMensagem).toHaveBeenCalledTimes(2);
      expect(usuariosRepository.incrementarConsultas).toHaveBeenCalledWith('user-1');
    });

    it('deve processar com conversaId existente', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockResolvedValueOnce({
        id: 'user-1',
        consultasUsadas: 0,
        limiteConsultas: 50,
      } as any);
      vi.mocked(iaRepository.criarMensagem)
        .mockResolvedValueOnce({ id: 'msg-user' } as any)
        .mockResolvedValueOnce({ id: 'msg-ia' } as any);
      vi.mocked(usuariosRepository.incrementarConsultas).mockResolvedValueOnce({} as any);

      const res = criarResMock();
      await iaController.processar(
        criarReqMock({
          body: { conversaId: 'conv-existente' },
          file: {
            buffer: Buffer.from('audio data'),
            originalname: 'test.wav',
            mimetype: 'audio/wav',
          },
        }),
        res,
      );

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          conversaId: 'conv-existente',
        }),
      );
      expect(iaRepository.criarConversa).not.toHaveBeenCalled();
    });

    it('deve retornar 500 em caso de erro no processamento', async () => {
      vi.mocked(usuariosRepository.buscarUsuarioPorId).mockRejectedValueOnce(new Error('fail'));

      const res = criarResMock();
      await iaController.processar(criarReqMock(), res);

      expect(res.status).toHaveBeenCalledWith(500);
    });
  });
});
