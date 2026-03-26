export type Provedor = 'EMAIL' | 'GOOGLE';

export interface Usuario {
  id: string;
  nome: string;
  email: string;
  senha: string | null;
  fotoUrl: string | null;
  googleId: string | null;
  provedor: Provedor;
  ativo: boolean;
  consultasUsadas: number;
  limiteConsultas: number;
  plano: 'GRATUITO' | 'PREMIUM';
  criadoEm: Date;
  atualizadoEm: Date;
}

export interface CriarUsuarioDto {
  nome: string;
  email: string;
  senha?: string;
  fotoUrl?: string;
  googleId?: string;
  provedor?: Provedor;
}

export interface AtualizarUsuarioDto {
  nome?: string;
  email?: string;
  fotoUrl?: string;
}
