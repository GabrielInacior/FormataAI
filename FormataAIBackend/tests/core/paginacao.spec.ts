import { describe, it, expect } from 'vitest';
import { extrairPaginacao, montarPaginacao, extrairBusca, extrairFiltroData } from '../../src/core/paginacao';

// Helper para criar um mock de Request
function criarReqMock(query: Record<string, string> = {}) {
  return { query } as any;
}

describe('paginacao', () => {
  describe('extrairPaginacao', () => {
    it('deve retornar valores padrão quando sem query params', () => {
      const result = extrairPaginacao(criarReqMock());
      expect(result).toEqual({ pagina: 1, limite: 20, skip: 0 });
    });

    it('deve extrair pagina e limite da query', () => {
      const result = extrairPaginacao(criarReqMock({ pagina: '3', limite: '10' }));
      expect(result).toEqual({ pagina: 3, limite: 10, skip: 20 });
    });

    it('deve limitar mínimo de pagina a 1', () => {
      const result = extrairPaginacao(criarReqMock({ pagina: '0' }));
      expect(result.pagina).toBe(1);
    });

    it('deve limitar mínimo de limite a 1', () => {
      const result = extrairPaginacao(criarReqMock({ limite: '-5' }));
      expect(result.limite).toBe(1);
    });

    it('deve limitar máximo de limite a 100', () => {
      const result = extrairPaginacao(criarReqMock({ limite: '500' }));
      expect(result.limite).toBe(100);
    });

    it('deve calcular skip corretamente', () => {
      const result = extrairPaginacao(criarReqMock({ pagina: '5', limite: '10' }));
      expect(result.skip).toBe(40);
    });
  });

  describe('montarPaginacao', () => {
    it('deve montar resposta paginada corretamente', () => {
      const dados = [{ id: '1' }, { id: '2' }];
      const result = montarPaginacao(dados, 50, { pagina: 1, limite: 20, skip: 0 });
      expect(result.dados).toEqual(dados);
      expect(result.paginacao.pagina).toBe(1);
      expect(result.paginacao.limite).toBe(20);
      expect(result.paginacao.total).toBe(50);
      expect(result.paginacao.totalPaginas).toBe(3);
    });

    it('deve calcular totalPaginas com arredondamento', () => {
      const result = montarPaginacao([], 21, { pagina: 1, limite: 10, skip: 0 });
      expect(result.paginacao.totalPaginas).toBe(3);
    });

    it('deve retornar 0 totalPaginas para total 0', () => {
      const result = montarPaginacao([], 0, { pagina: 1, limite: 10, skip: 0 });
      expect(result.paginacao.totalPaginas).toBe(0);
    });
  });

  describe('extrairBusca', () => {
    it('deve retornar undefined sem parâmetro busca', () => {
      expect(extrairBusca(criarReqMock())).toBeUndefined();
    });

    it('deve retornar string de busca trimada', () => {
      expect(extrairBusca(criarReqMock({ busca: '  email formal  ' }))).toBe('email formal');
    });

    it('deve retornar undefined para busca vazia', () => {
      expect(extrairBusca(criarReqMock({ busca: '   ' }))).toBeUndefined();
    });
  });

  describe('extrairFiltroData', () => {
    it('deve retornar undefined sem parâmetros de data', () => {
      const result = extrairFiltroData(criarReqMock());
      expect(result.dataInicio).toBeUndefined();
      expect(result.dataFim).toBeUndefined();
    });

    it('deve parsear dataInicio', () => {
      const result = extrairFiltroData(criarReqMock({ dataInicio: '2024-01-01' }));
      expect(result.dataInicio).toBeInstanceOf(Date);
    });

    it('deve parsear dataFim', () => {
      const result = extrairFiltroData(criarReqMock({ dataFim: '2024-12-31' }));
      expect(result.dataFim).toBeInstanceOf(Date);
    });

    it('deve parsear ambas as datas', () => {
      const result = extrairFiltroData(criarReqMock({ dataInicio: '2024-01-01', dataFim: '2024-12-31' }));
      expect(result.dataInicio).toBeInstanceOf(Date);
      expect(result.dataFim).toBeInstanceOf(Date);
    });
  });
});
