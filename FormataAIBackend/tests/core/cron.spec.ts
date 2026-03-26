import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/core/s3', () => ({
  limparArquivosExpirados: vi.fn(),
}));

vi.mock('../../src/core/logger', () => ({
  logger: {
    info: vi.fn(),
    sucesso: vi.fn(),
    erro: vi.fn(),
  },
}));

vi.mock('../../src/database/prisma', () => ({
  default: {},
}));

vi.mock('../../src/modules/usuarios/usuarios.repository', () => ({
  resetarConsultasDiario: vi.fn(),
}));

// vi.mock factories are hoisted — use inline fn
const scheduleMock = vi.hoisted(() => vi.fn());
vi.mock('node-cron', () => ({
  default: { schedule: scheduleMock },
}));

import { iniciarCronJobs } from '../../src/core/cron';
import { limparArquivosExpirados } from '../../src/core/s3';
import * as usuariosRepository from '../../src/modules/usuarios/usuarios.repository';

describe('cron', () => {
  beforeEach(() => {
    scheduleMock.mockReset();
  });

  it('deve agendar 1 job diário (S3 + reset consultas)', () => {
    iniciarCronJobs();
    expect(scheduleMock).toHaveBeenCalledTimes(1);
    expect(scheduleMock).toHaveBeenCalledWith('0 0 * * *', expect.any(Function));
  });

  it('o callback diário deve chamar limparArquivosExpirados e resetarConsultasDiario', async () => {
    vi.mocked(limparArquivosExpirados).mockResolvedValueOnce(5);
    vi.mocked(usuariosRepository.resetarConsultasDiario).mockResolvedValueOnce({ count: 10 } as any);

    iniciarCronJobs();

    const callback = scheduleMock.mock.calls[0][1];
    await callback();

    expect(limparArquivosExpirados).toHaveBeenCalled();
    expect(usuariosRepository.resetarConsultasDiario).toHaveBeenCalled();
  });

  it('o callback diário deve tratar erros de S3', async () => {
    vi.mocked(limparArquivosExpirados).mockRejectedValueOnce(new Error('falha S3'));
    vi.mocked(usuariosRepository.resetarConsultasDiario).mockResolvedValueOnce({ count: 0 } as any);

    iniciarCronJobs();

    const callback = scheduleMock.mock.calls[0][1];
    await expect(callback()).resolves.not.toThrow();
  });

  it('o callback diário deve tratar erros de reset', async () => {
    vi.mocked(limparArquivosExpirados).mockResolvedValueOnce(0);
    vi.mocked(usuariosRepository.resetarConsultasDiario).mockRejectedValueOnce(new Error('falha reset'));

    iniciarCronJobs();

    const callback = scheduleMock.mock.calls[0][1];
    await expect(callback()).resolves.not.toThrow();
  });
});
