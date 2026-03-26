import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  ListObjectsV2Command,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import { env } from './env';
import { logger } from './logger';

const s3 = new S3Client({
  region: env.AWS_REGION,
  credentials: {
    accessKeyId: env.AWS_ACCESS_KEY_ID,
    secretAccessKey: env.AWS_SECRET_ACCESS_KEY,
  },
});

export interface UploadResult {
  key: string;
  url: string;
}

/**
 * Faz upload de um buffer para o S3.
 * @param key - Caminho/nome do arquivo no bucket (ex: "audios/uuid.wav")
 * @param buffer - Conteúdo do arquivo
 * @param contentType - MIME type
 */
export async function uploadArquivo(
  key: string,
  buffer: Buffer,
  contentType: string,
): Promise<UploadResult> {
  await s3.send(new PutObjectCommand({
    Bucket: env.S3_BUCKET_NAME,
    Key: key,
    Body: buffer,
    ContentType: contentType,
  }));

  const url = `https://${env.S3_BUCKET_NAME}.s3.${env.AWS_REGION}.amazonaws.com/${key}`;

  logger.info('S3', `Upload: ${key}`);
  return { key, url };
}

/**
 * Deleta um arquivo do S3.
 */
export async function deletarArquivo(key: string): Promise<void> {
  await s3.send(new DeleteObjectCommand({
    Bucket: env.S3_BUCKET_NAME,
    Key: key,
  }));
  logger.info('S3', `Deletado: ${key}`);
}

/**
 * Lista todas as keys no bucket (ou com prefixo).
 */
export async function listarArquivos(prefix?: string): Promise<{ key: string; lastModified?: Date }[]> {
  const result = await s3.send(new ListObjectsV2Command({
    Bucket: env.S3_BUCKET_NAME,
    Prefix: prefix,
  }));

  return (result.Contents || []).map((obj) => ({
    key: obj.Key || '',
    lastModified: obj.LastModified,
  }));
}

/**
 * Retorna o conteúdo de um arquivo do S3 como stream.
 */
export async function buscarArquivo(key: string) {
  const result = await s3.send(new GetObjectCommand({
    Bucket: env.S3_BUCKET_NAME,
    Key: key,
  }));

  return result.Body;
}

/**
 * Deleta todos os arquivos mais antigos que o número de dias configurado.
 */
export async function limparArquivosExpirados(): Promise<number> {
  const diasExpiracao = env.S3_DIAS_EXPIRACAO;
  const limiteData = new Date();
  limiteData.setDate(limiteData.getDate() - diasExpiracao);

  const arquivos = await listarArquivos();
  let deletados = 0;

  for (const arquivo of arquivos) {
    if (arquivo.lastModified && arquivo.lastModified < limiteData) {
      try {
        await deletarArquivo(arquivo.key);
        deletados++;
      } catch (error) {
        logger.erro('S3', `Falha ao deletar arquivo expirado: ${arquivo.key}`, error);
      }
    }
  }

  return deletados;
}

export { s3 as s3Client };
