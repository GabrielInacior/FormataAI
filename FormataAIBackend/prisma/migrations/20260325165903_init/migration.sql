-- CreateEnum
CREATE TYPE "Plano" AS ENUM ('GRATUITO', 'PREMIUM');

-- CreateEnum
CREATE TYPE "CategoriaConversa" AS ENUM ('EMAIL', 'MENSAGEM', 'ORCAMENTO', 'DOCUMENTO', 'OUTRO');

-- CreateEnum
CREATE TYPE "TipoMensagem" AS ENUM ('USUARIO', 'ASSISTENTE');

-- CreateTable
CREATE TABLE "usuarios" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "senha" TEXT NOT NULL,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "consultas_usadas" INTEGER NOT NULL DEFAULT 0,
    "limite_consultas" INTEGER NOT NULL DEFAULT 50,
    "plano" "Plano" NOT NULL DEFAULT 'GRATUITO',
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "atualizado_em" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "usuario_id" TEXT NOT NULL,
    "expira_em" TIMESTAMP(3) NOT NULL,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "conversas" (
    "id" TEXT NOT NULL,
    "usuario_id" TEXT NOT NULL,
    "titulo" TEXT NOT NULL DEFAULT 'Nova conversa',
    "categoria" "CategoriaConversa" NOT NULL DEFAULT 'OUTRO',
    "favoritada" BOOLEAN NOT NULL DEFAULT false,
    "arquivada" BOOLEAN NOT NULL DEFAULT false,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "atualizado_em" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "conversas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mensagens" (
    "id" TEXT NOT NULL,
    "conversa_id" TEXT NOT NULL,
    "tipo" "TipoMensagem" NOT NULL,
    "audio_url" TEXT,
    "transcricao" TEXT,
    "intencao" TEXT,
    "conteudo" TEXT NOT NULL DEFAULT '',
    "tokens_usados" INTEGER NOT NULL DEFAULT 0,
    "modelo_usado" TEXT NOT NULL DEFAULT 'gpt-4o-mini',
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mensagens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_email_key" ON "usuarios"("email");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_key" ON "refresh_tokens"("token");

-- CreateIndex
CREATE INDEX "refresh_tokens_token_idx" ON "refresh_tokens"("token");

-- CreateIndex
CREATE INDEX "conversas_usuario_id_criado_em_idx" ON "conversas"("usuario_id", "criado_em" DESC);

-- CreateIndex
CREATE INDEX "conversas_usuario_id_categoria_idx" ON "conversas"("usuario_id", "categoria");

-- CreateIndex
CREATE INDEX "mensagens_conversa_id_criado_em_idx" ON "mensagens"("conversa_id", "criado_em");

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversas" ADD CONSTRAINT "conversas_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mensagens" ADD CONSTRAINT "mensagens_conversa_id_fkey" FOREIGN KEY ("conversa_id") REFERENCES "conversas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
