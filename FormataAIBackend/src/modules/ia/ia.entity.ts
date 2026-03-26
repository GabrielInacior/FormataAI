export interface TranscricaoResult {
  texto: string;
}

export interface GeracaoResult {
  intencao: string;
  resposta: string;
}

export type CategoriaConversa = 'EMAIL' | 'MENSAGEM' | 'ORCAMENTO' | 'DOCUMENTO' | 'OUTRO';
export type TipoMensagem = 'USUARIO' | 'ASSISTENTE';

export interface ConversaDto {
  id: string;
  usuarioId: string;
  titulo: string;
  categoria: CategoriaConversa;
  favoritada: boolean;
  arquivada: boolean;
  criadoEm: Date;
  atualizadoEm: Date;
}

export interface MensagemDto {
  id: string;
  conversaId: string;
  tipo: TipoMensagem;
  audioUrl: string | null;
  transcricao: string | null;
  intencao: string | null;
  conteudo: string;
  tokensUsados: number;
  modeloUsado: string;
  criadoEm: Date;
}

export interface FiltrosConversa {
  categoria?: CategoriaConversa;
  favoritada?: boolean;
  arquivada?: boolean;
  busca?: string;
  dataInicio?: Date;
  dataFim?: Date;
}
