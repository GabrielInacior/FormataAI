import prisma from '../../database/prisma';
import { CriarUsuarioDto, AtualizarUsuarioDto } from './usuarios.entity';

export async function criarUsuario(dados: CriarUsuarioDto) {
  return prisma.usuario.create({ data: dados });
}

export async function buscarUsuarioPorEmail(email: string) {
  return prisma.usuario.findUnique({ where: { email } });
}

export async function buscarUsuarioPorId(id: string) {
  return prisma.usuario.findUnique({ where: { id } });
}

export async function buscarUsuarioPorGoogleId(googleId: string) {
  return prisma.usuario.findUnique({ where: { googleId } });
}

export async function atualizarUsuario(id: string, dados: AtualizarUsuarioDto) {
  return prisma.usuario.update({ where: { id }, data: dados });
}

export async function incrementarConsultas(id: string) {
  return prisma.usuario.update({
    where: { id },
    data: { consultasUsadas: { increment: 1 } },
  });
}

export async function resetarConsultasDiario() {
  return prisma.usuario.updateMany({
    data: { consultasUsadas: 0 },
  });
}

export async function deletarUsuario(id: string) {
  return prisma.usuario.delete({ where: { id } });
}
