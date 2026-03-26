import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { OAuth2Client } from 'google-auth-library';
import { env } from '../../core/env';
import { logger } from '../../core/logger';
import { RotaConfig } from '../../core/types';
import * as usuariosRepository from '../usuarios/usuarios.repository';

const googleClient = new OAuth2Client(env.GOOGLE_CLIENT_ID);

// ─── Rotas ──────────────────────────────────────────────────

export const rotas: RotaConfig[] = [
  { method: 'POST', path: '/registrar',      handler: 'registrar',      auth: false },
  { method: 'POST', path: '/login',           handler: 'login',          auth: false },
  { method: 'POST', path: '/google',          handler: 'googleAuth',     auth: false },
  { method: 'POST', path: '/alterar-senha',   handler: 'alterarSenha',   auth: true },
  { method: 'DELETE', path: '/deletar-conta', handler: 'deletarConta',   auth: true },
];

// ─── Helpers ────────────────────────────────────────────────

function gerarToken(id: string, email: string): string {
  return jwt.sign(
    { id, email },
    env.JWT_SECRET,
    { expiresIn: env.JWT_EXPIRES_IN } as jwt.SignOptions,
  );
}

function formatarUsuario(usuario: any) {
  return {
    id: usuario.id,
    nome: usuario.nome,
    email: usuario.email,
    fotoUrl: usuario.fotoUrl ?? null,
    provedor: usuario.provedor,
  };
}

// ─── Handlers ───────────────────────────────────────────────

export async function registrar(req: Request, res: Response) {
  try {
    const { nome, email, senha } = req.body;

    if (!nome || !email || !senha) {
      res.status(400).json({ erro: 'Nome, email e senha são obrigatórios' });
      return;
    }

    const existente = await usuariosRepository.buscarUsuarioPorEmail(email);
    if (existente) {
      res.status(409).json({ erro: 'Email já cadastrado' });
      return;
    }

    const senhaHash = await bcrypt.hash(senha, 10);
    const usuario = await usuariosRepository.criarUsuario({
      nome,
      email,
      senha: senhaHash,
      provedor: 'EMAIL',
    });

    const token = gerarToken(usuario.id, usuario.email);

    res.status(201).json({
      token,
      usuario: formatarUsuario(usuario),
    });
  } catch (error) {
    logger.erro('AUTH', 'Erro ao registrar usuário', error);
    res.status(500).json({ erro: 'Erro ao registrar usuário' });
  }
}

export async function login(req: Request, res: Response) {
  try {
    const { email, senha } = req.body;

    if (!email || !senha) {
      res.status(400).json({ erro: 'Email e senha são obrigatórios' });
      return;
    }

    const usuario = await usuariosRepository.buscarUsuarioPorEmail(email);
    if (!usuario || !usuario.senha) {
      res.status(401).json({ erro: 'Credenciais inválidas' });
      return;
    }

    const senhaValida = await bcrypt.compare(senha, usuario.senha);
    if (!senhaValida) {
      res.status(401).json({ erro: 'Credenciais inválidas' });
      return;
    }

    const token = gerarToken(usuario.id, usuario.email);

    res.json({
      token,
      usuario: formatarUsuario(usuario),
    });
  } catch (error) {
    logger.erro('AUTH', 'Erro ao fazer login', error);
    res.status(500).json({ erro: 'Erro ao fazer login' });
  }
}

export async function googleAuth(req: Request, res: Response) {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      res.status(400).json({ erro: 'Token do Google é obrigatório' });
      return;
    }

    // Verificar ID token com o Google
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    if (!payload || !payload.email) {
      res.status(401).json({ erro: 'Token do Google inválido' });
      return;
    }

    const { sub: googleId, email, name, picture } = payload;

    // Buscar usuário pelo googleId
    let usuario = await usuariosRepository.buscarUsuarioPorGoogleId(googleId!);

    if (!usuario) {
      // Verificar se existe conta com mesmo email (migrar para Google)
      const existente = await usuariosRepository.buscarUsuarioPorEmail(email!);

      if (existente) {
        // Vincular Google à conta existente
        usuario = await usuariosRepository.atualizarUsuario(existente.id, {
          googleId,
          fotoUrl: picture,
          provedor: 'GOOGLE',
        } as any);
      } else {
        // Criar conta nova via Google
        usuario = await usuariosRepository.criarUsuario({
          nome: name || email!.split('@')[0],
          email: email!,
          googleId: googleId!,
          fotoUrl: picture,
          provedor: 'GOOGLE',
        });
      }
    }

    const token = gerarToken(usuario.id, usuario.email);

    res.json({
      token,
      usuario: formatarUsuario(usuario),
    });
  } catch (error) {
    logger.erro('AUTH', 'Erro na autenticação Google', error);
    res.status(401).json({ erro: 'Falha na autenticação com Google' });
  }
}

export async function alterarSenha(req: Request, res: Response) {
  try {
    const { senhaAtual, novaSenha } = req.body;

    if (!novaSenha) {
      res.status(400).json({ erro: 'Nova senha é obrigatória' });
      return;
    }

    const usuario = await usuariosRepository.buscarUsuarioPorId(req.usuario!.id);
    if (!usuario) {
      res.status(404).json({ erro: 'Usuário não encontrado' });
      return;
    }

    // Se tem senha (conta EMAIL), exigir senha atual
    if (usuario.senha) {
      if (!senhaAtual) {
        res.status(400).json({ erro: 'Senha atual é obrigatória' });
        return;
      }
      const senhaValida = await bcrypt.compare(senhaAtual, usuario.senha);
      if (!senhaValida) {
        res.status(401).json({ erro: 'Senha atual incorreta' });
        return;
      }
    }

    const senhaHash = await bcrypt.hash(novaSenha, 10);
    await usuariosRepository.atualizarUsuario(usuario.id, { senha: senhaHash } as any);

    res.json({ mensagem: 'Senha alterada com sucesso' });
  } catch (error) {
    logger.erro('AUTH', 'Erro ao alterar senha', error);
    res.status(500).json({ erro: 'Erro ao alterar senha' });
  }
}

export async function deletarConta(req: Request, res: Response) {
  try {
    await usuariosRepository.deletarUsuario(req.usuario!.id);
    res.status(204).send();
  } catch (error) {
    logger.erro('AUTH', 'Erro ao deletar conta', error);
    res.status(500).json({ erro: 'Erro ao deletar conta' });
  }
}
