import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock do logger antes de importar o módulo
vi.mock('../../src/core/logger', () => ({
  logger: {
    info: vi.fn(),
    erro: vi.fn(),
    aviso: vi.fn(),
    sucesso: vi.fn(),
  },
}));

// Mock do S3Client — use vi.hoisted so sendMock is available during mock factory
const sendMock = vi.hoisted(() => vi.fn());
vi.mock('@aws-sdk/client-s3', () => {
  class MockS3Client {
    send = sendMock;
  }
  return {
    S3Client: MockS3Client,
    PutObjectCommand: vi.fn(),
    DeleteObjectCommand: vi.fn(),
    ListObjectsV2Command: vi.fn(),
    GetObjectCommand: vi.fn(),
  };
});

import { uploadArquivo, deletarArquivo, listarArquivos, limparArquivosExpirados, buscarArquivo } from '../../src/core/s3';

describe('s3', () => {
  beforeEach(() => {
    sendMock.mockReset();
  });

  describe('uploadArquivo', () => {
    it('deve fazer upload e retornar key e url', async () => {
      sendMock.mockResolvedValueOnce({});

      const result = await uploadArquivo('audios/test.wav', Buffer.from('data'), 'audio/wav');

      expect(result.key).toBe('audios/test.wav');
      expect(result.url).toContain('audios/test.wav');
      expect(sendMock).toHaveBeenCalledTimes(1);
    });
  });

  describe('deletarArquivo', () => {
    it('deve chamar send com DeleteObjectCommand', async () => {
      sendMock.mockResolvedValueOnce({});

      await deletarArquivo('audios/test.wav');

      expect(sendMock).toHaveBeenCalledTimes(1);
    });
  });

  describe('listarArquivos', () => {
    it('deve retornar lista de arquivos', async () => {
      const dataAntiga = new Date('2024-01-01');
      sendMock.mockResolvedValueOnce({
        Contents: [
          { Key: 'audios/file1.wav', LastModified: dataAntiga },
          { Key: 'audios/file2.wav', LastModified: new Date() },
        ],
      });

      const result = await listarArquivos('audios/');

      expect(result).toHaveLength(2);
      expect(result[0].key).toBe('audios/file1.wav');
    });

    it('deve retornar array vazio se não houver conteúdo', async () => {
      sendMock.mockResolvedValueOnce({ Contents: undefined });

      const result = await listarArquivos();

      expect(result).toEqual([]);
    });
  });

  describe('buscarArquivo', () => {
    it('deve retornar o Body do resultado do S3', async () => {
      const mockBody = { transformToByteArray: vi.fn() };
      sendMock.mockResolvedValueOnce({ Body: mockBody });

      const result = await buscarArquivo('audios/test.wav');

      expect(result).toBe(mockBody);
      expect(sendMock).toHaveBeenCalledTimes(1);
    });
  });

  describe('limparArquivosExpirados', () => {
    it('deve deletar arquivos mais antigos que o limite', async () => {
      const dataAntiga = new Date();
      dataAntiga.setDate(dataAntiga.getDate() - 15); // 15 dias atrás

      // Primeiro call: listarArquivos
      sendMock.mockResolvedValueOnce({
        Contents: [
          { Key: 'audios/expirado.wav', LastModified: dataAntiga },
          { Key: 'audios/recente.wav', LastModified: new Date() },
        ],
      });
      // Segundo call: deletarArquivo
      sendMock.mockResolvedValueOnce({});

      const deletados = await limparArquivosExpirados();

      expect(deletados).toBe(1);
    });

    it('deve retornar 0 se não houver arquivos expirados', async () => {
      sendMock.mockResolvedValueOnce({
        Contents: [
          { Key: 'audios/recente.wav', LastModified: new Date() },
        ],
      });

      const deletados = await limparArquivosExpirados();

      expect(deletados).toBe(0);
    });

    it('deve tratar erro ao deletar arquivo individual', async () => {
      const dataAntiga = new Date();
      dataAntiga.setDate(dataAntiga.getDate() - 15);

      sendMock.mockResolvedValueOnce({
        Contents: [
          { Key: 'audios/expirado.wav', LastModified: dataAntiga },
        ],
      });
      sendMock.mockRejectedValueOnce(new Error('S3 error'));

      const deletados = await limparArquivosExpirados();

      expect(deletados).toBe(0);
    });
  });
});
