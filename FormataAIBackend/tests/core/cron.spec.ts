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
  resetarConsultasMensal: vi.fn(),
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

  it('deve agendar 2 jobs (S3 diário + reset mensal)', () => {
    iniciarCronJobs();
    expect(scheduleMock).toHaveBeenCalledTimes(2);
    expect(scheduleMock).toHaveBeenCalledWith('0 0 * * *', expect.any(Function));
    expect(scheduleMock).toHaveBeenCalledWith('0 0 1 * *', expect.any(Function));
  });

  it('o callback S3 deve chamar limparArquivosExpirados', async () => {
    vi.mocked(limparArquivosExpirados).mockResolvedValueOnce(5);

    iniciarCronJobs();

    // Pega a callback do primeiro schedule (S3)
    const callback = scheduleMock.mock.calls[0][1];
    await callback();

    expect(limparArquivosExpirados).toHaveBeenCalled();
  });

  it('o callback S3 deve tratar erros', async () => {
    vi.mocked(limparArquivosExpirados).mockRejectedValueOnce(new Error('falha S3'));

    iniciarCronJobs();

    const callback = scheduleMock.mock.calls[0][1];
    await expect(callback()).resolves.not.toThrow();
  });

  it('o callback mensal deve chamar resetarConsultasMensal', async () => {
    vi.mocked(usuariosRepository.resetarConsultasMensal).mockResolvedValueOnce({ count: 10 } as any);

    iniciarCronJobs();

    // Pega a callback do segundo schedule (reset mensal)
    const callback = scheduleMock.mock.calls[1][1];
    await callback();

    expect(usuariosRepository.resetarConsultasMensal).toHaveBeenCalled();
  });

  it('o callback mensal deve tratar erros', async () => {
    vi.mocked(usuariosRepository.resetarConsultasMensal).mockRejectedValueOnce(new Error('falha reset'));

    iniciarCronJobs();

    const callback = scheduleMock.mock.calls[1][1];
    await expect(callback()).resolves.not.toThrow();
  });
});
