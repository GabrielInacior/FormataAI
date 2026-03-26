import { Request } from 'express';

export interface PaginacaoParams {
  pagina: number;
  limite: number;
  skip: number;
}

export interface PaginacaoResult<T> {
  dados: T[];
  paginacao: {
    pagina: number;
    limite: number;
    total: number;
    totalPaginas: number;
  };
}

/**
 * Extrai parâmetros de paginação da query string.
 * ?pagina=1&limite=20
 */
export function extrairPaginacao(req: Request): PaginacaoParams {
  const pagina = Math.max(1, Number(req.query.pagina) || 1);
  const limite = Math.min(100, Math.max(1, Number(req.query.limite) || 20));
  const skip = (pagina - 1) * limite;

  return { pagina, limite, skip };
}

/**
 * Monta o objeto de resposta paginada.
 */
export function montarPaginacao<T>(dados: T[], total: number, params: PaginacaoParams): PaginacaoResult<T> {
  return {
    dados,
    paginacao: {
      pagina: params.pagina,
      limite: params.limite,
      total,
      totalPaginas: Math.ceil(total / params.limite),
    },
  };
}

/**
 * Extrai filtro de busca textual (FTS) da query string.
 * ?busca=texto para pesquisar
 */
export function extrairBusca(req: Request): string | undefined {
  const busca = req.query.busca as string | undefined;
  return busca?.trim() || undefined;
}

/**
 * Extrai filtro de data da query string.
 * ?dataInicio=2024-01-01&dataFim=2024-12-31
 */
export function extrairFiltroData(req: Request): { dataInicio?: Date; dataFim?: Date } {
  const dataInicio = req.query.dataInicio ? new Date(req.query.dataInicio as string) : undefined;
  const dataFim = req.query.dataFim ? new Date(req.query.dataFim as string) : undefined;

  return {
    dataInicio: dataInicio && !isNaN(dataInicio.getTime()) ? dataInicio : undefined,
    dataFim: dataFim && !isNaN(dataFim.getTime()) ? dataFim : undefined,
  };
}
