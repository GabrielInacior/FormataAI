import { describe, it, expect, vi } from 'vitest';
import { logger } from '../../src/core/logger';

describe('logger', () => {
  it('deve ter métodos de log definidos', () => {
    expect(typeof logger.requisicao).toBe('function');
    expect(typeof logger.info).toBe('function');
    expect(typeof logger.sucesso).toBe('function');
    expect(typeof logger.aviso).toBe('function');
    expect(typeof logger.erro).toBe('function');
    expect(typeof logger.banner).toBe('function');
  });

  it('logger.info não deve lançar erro', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    expect(() => logger.info('TESTE', 'mensagem de teste')).not.toThrow();
    spy.mockRestore();
  });

  it('logger.sucesso não deve lançar erro', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    expect(() => logger.sucesso('TESTE', 'sucesso')).not.toThrow();
    spy.mockRestore();
  });

  it('logger.aviso não deve lançar erro', () => {
    const spy = vi.spyOn(console, 'warn').mockImplementation(() => {});
    expect(() => logger.aviso('TESTE', 'aviso')).not.toThrow();
    spy.mockRestore();
  });

  it('logger.erro deve logar stack em dev', () => {
    const spyErr = vi.spyOn(console, 'error').mockImplementation(() => {});
    process.env.NODE_ENV = 'development';
    expect(() => logger.erro('TESTE', 'erro', new Error('falha'))).not.toThrow();
    expect(spyErr).toHaveBeenCalled();
    spyErr.mockRestore();
  });

  it('logger.erro sem error não lança exceção', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {});
    expect(() => logger.erro('TESTE', 'sem error')).not.toThrow();
    spy.mockRestore();
  });

  it('logger.requisicao deve logar com cores', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    expect(() => logger.requisicao('GET', '/api/health', 200, 12)).not.toThrow();
    expect(() => logger.requisicao('POST', '/api/auth/login', 401, 150)).not.toThrow();
    expect(() => logger.requisicao('DELETE', '/api/conversas/1', 500, 600)).not.toThrow();
    expect(spy).toHaveBeenCalledTimes(3);
    spy.mockRestore();
  });

  it('logger.banner deve exibir informações do servidor', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    expect(() => logger.banner(3000, 'development')).not.toThrow();
    expect(spy).toHaveBeenCalled();
    spy.mockRestore();
  });
});
