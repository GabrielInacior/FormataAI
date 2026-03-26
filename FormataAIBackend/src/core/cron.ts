import cron from 'node-cron';
import { limparArquivosExpirados } from './s3';
import { logger } from './logger';
import * as usuariosRepository from '../modules/usuarios/usuarios.repository';

/**
 * Inicializa os jobs agendados (cron).
 * - Limpeza de arquivos S3 expirados: todos os dias à meia-noite.
 * - Reset mensal de consultas usadas: dia 1 de cada mês às 00:00.
 */
export function iniciarCronJobs() {
  // Todo dia à meia-noite (00:00) — reset diário de consultas
  cron.schedule('0 0 * * *', async () => {
    logger.info('CRON', 'Iniciando limpeza de arquivos expirados no S3...');

    try {
      const deletados = await limparArquivosExpirados();
      logger.sucesso('CRON', `Limpeza concluída: ${deletados} arquivo(s) deletado(s)`);
    } catch (error) {
      logger.erro('CRON', 'Erro na limpeza de arquivos do S3', error);
    }

    logger.info('CRON', 'Iniciando reset diário de consultas...');
    try {
      const resultado = await usuariosRepository.resetarConsultasDiario();
      logger.sucesso('CRON', `Reset diário concluído: ${resultado.count} usuário(s) resetado(s)`);
    } catch (error) {
      logger.erro('CRON', 'Erro no reset diário de consultas', error);
    }
  });

  logger.info('CRON', 'Jobs agendados: limpeza S3 + reset consultas (diário)');
}
