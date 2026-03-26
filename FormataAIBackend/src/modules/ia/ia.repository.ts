import prisma from '../../database/prisma';
import { FiltrosConversa, CategoriaConversa, TipoMensagem } from './ia.entity';

// ─── Conversas ──────────────────────────────────────────────

export async function criarConversa(dados: {
  usuarioId: string;
  titulo?: string;
  categoria?: CategoriaConversa;
}) {
  return prisma.conversa.create({ data: dados });
}

export async function buscarConversaPorId(id: string) {
  return prisma.conversa.findUnique({
    where: { id },
    include: { mensagens: { orderBy: { criadoEm: 'asc' } } },
  });
}

export async function listarConversas(
  usuarioId: string,
  filtros: FiltrosConversa,
  skip: number,
  take: number,
) {
  const where: any = { usuarioId };

  if (filtros.categoria) where.categoria = filtros.categoria;
  if (filtros.favoritada !== undefined) where.favoritada = filtros.favoritada;
  if (filtros.arquivada !== undefined) where.arquivada = filtros.arquivada;

  // Filtro de data
  if (filtros.dataInicio || filtros.dataFim) {
    where.criadoEm = {};
    if (filtros.dataInicio) where.criadoEm.gte = filtros.dataInicio;
    if (filtros.dataFim) where.criadoEm.lte = filtros.dataFim;
  }

  // Full-text search no título e nas mensagens
  if (filtros.busca) {
    const termos = filtros.busca.split(/\s+/).filter(Boolean).join(' & ');
    where.OR = [
      { titulo: { contains: filtros.busca, mode: 'insensitive' } },
      {
        mensagens: {
          some: {
            OR: [
              { conteudo: { contains: filtros.busca, mode: 'insensitive' } },
              { transcricao: { contains: filtros.busca, mode: 'insensitive' } },
            ],
          },
        },
      },
    ];
  }

  const [dados, total] = await Promise.all([
    prisma.conversa.findMany({
      where,
      skip,
      take,
      orderBy: { criadoEm: 'desc' },
      include: {
        mensagens: { orderBy: { criadoEm: 'desc' }, take: 1 },
        _count: { select: { mensagens: true } },
      },
    }),
    prisma.conversa.count({ where }),
  ]);

  return { dados, total };
}

export async function atualizarConversa(id: string, dados: {
  titulo?: string;
  categoria?: CategoriaConversa;
  favoritada?: boolean;
  arquivada?: boolean;
}) {
  return prisma.conversa.update({ where: { id }, data: dados });
}

export async function deletarConversa(id: string) {
  return prisma.conversa.delete({ where: { id } });
}

// ─── Mensagens ──────────────────────────────────────────────

export async function criarMensagem(dados: {
  conversaId: string;
  tipo: TipoMensagem;
  audioUrl?: string;
  transcricao?: string;
  intencao?: string;
  conteudo: string;
  tokensUsados?: number;
  modeloUsado?: string;
}) {
  return prisma.mensagem.create({ data: dados });
}

export async function buscarMensagemPorId(id: string) {
  return prisma.mensagem.findUnique({ where: { id } });
}

export async function listarMensagens(
  conversaId: string,
  skip: number,
  take: number,
) {
  const [dados, total] = await Promise.all([
    prisma.mensagem.findMany({
      where: { conversaId },
      skip,
      take,
      orderBy: { criadoEm: 'asc' },
    }),
    prisma.mensagem.count({ where: { conversaId } }),
  ]);

  return { dados, total };
}
