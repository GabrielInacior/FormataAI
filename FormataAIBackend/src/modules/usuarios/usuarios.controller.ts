import { Request, Response } from 'express';
import { RotaConfig } from '../../core/types';
import { logger } from '../../core/logger';
import * as usuariosRepository from './usuarios.repository';

// ─── Rotas ──────────────────────────────────────────────────

export const rotas: RotaConfig[] = [
  { method: 'GET', path: '/buscar-perfil',    handler: 'buscarPerfil',    auth: true },
  { method: 'PUT', path: '/atualizar-perfil', handler: 'atualizarPerfil', auth: true },
  { method: 'GET', path: '/estatisticas',     handler: 'estatisticas',    auth: true },
];

// ─── Handlers ───────────────────────────────────────────────

export async function buscarPerfil(req: Request, res: Response) {
  try {
    const usuario = await usuariosRepository.buscarUsuarioPorId(req.usuario!.id);

    if (!usuario) {
      res.status(404).json({ erro: 'Usuário não encontrado' });
      return;
    }

    const { senha: _, ...perfil } = usuario;
    res.json(perfil);
  } catch (error) {
    logger.erro('USUARIOS', 'Erro ao buscar perfil', error);
    res.status(500).json({ erro: 'Erro ao buscar perfil' });
  }
}

export async function atualizarPerfil(req: Request, res: Response) {
  try {
    const { nome, email, fotoUrl } = req.body;

    const usuario = await usuariosRepository.atualizarUsuario(req.usuario!.id, { nome, email, fotoUrl });
    const { senha: _, ...perfil } = usuario;

    res.json(perfil);
  } catch (error) {
    logger.erro('USUARIOS', 'Erro ao atualizar perfil', error);
    res.status(500).json({ erro: 'Erro ao atualizar perfil' });
  }
}

export async function estatisticas(req: Request, res: Response) {
  try {
    const usuario = await usuariosRepository.buscarUsuarioPorId(req.usuario!.id);

    if (!usuario) {
      res.status(404).json({ erro: 'Usuário não encontrado' });
      return;
    }

    res.json({
      consultasUsadas: usuario.consultasUsadas,
      limiteConsultas: usuario.limiteConsultas,
      consultasRestantes: Math.max(0, usuario.limiteConsultas - usuario.consultasUsadas),
      plano: usuario.plano,
    });
  } catch (error) {
    logger.erro('USUARIOS', 'Erro ao buscar estatísticas', error);
    res.status(500).json({ erro: 'Erro ao buscar estatísticas' });
  }
}
