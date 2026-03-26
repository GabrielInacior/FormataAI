export interface LoginDto {
  email: string;
  senha: string;
}

export interface RegistroDto {
  nome: string;
  email: string;
  senha: string;
}

export interface GoogleAuthDto {
  idToken: string;
}

export interface TokenResponse {
  token: string;
  usuario: {
    id: string;
    nome: string;
    email: string;
    fotoUrl?: string | null;
    provedor: string;
  };
}
