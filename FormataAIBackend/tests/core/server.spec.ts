import { describe, it, expect, vi } from 'vitest';
import express from 'express';

// Mock dependências antes de importar
vi.mock('../../src/core/router', () => ({
  criarRouter: vi.fn(() => express.Router()),
}));

vi.mock('../../src/core/logger', () => ({
  logger: {
    banner: vi.fn(),
    info: vi.fn(),
    sucesso: vi.fn(),
  },
}));

vi.mock('../../src/core/cron', () => ({
  iniciarCronJobs: vi.fn(),
}));

import { criarServidor, iniciarServidor } from '../../src/core/server';
import { logger } from '../../src/core/logger';
import { iniciarCronJobs } from '../../src/core/cron';

describe('server', () => {
  it('deve criar instância do express app', () => {
    const app = criarServidor();
    expect(app).toBeDefined();
    expect(typeof app.listen).toBe('function');
  });

  it('iniciarServidor deve chamar app.listen e iniciarCronJobs', async () => {
    const app = iniciarServidor();
    expect(app).toBeDefined();

    // app.listen é chamado com a porta e callback
    // O callback chama logger.banner — aguardar tick para executar
    await new Promise((r) => setTimeout(r, 100));

    expect(iniciarCronJobs).toHaveBeenCalled();
  });
});
