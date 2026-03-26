-- CreateEnum
CREATE TYPE "Provedor" AS ENUM ('EMAIL', 'GOOGLE');

-- AlterTable: adiciona colunas de autenticação Google e foto
ALTER TABLE "usuarios"
  ADD COLUMN IF NOT EXISTS "foto_url" TEXT,
  ADD COLUMN IF NOT EXISTS "google_id" TEXT,
  ADD COLUMN IF NOT EXISTS "provedor" "Provedor" NOT NULL DEFAULT 'EMAIL';

-- AlterTable: torna senha nullable (Google users não têm senha)
ALTER TABLE "usuarios" ALTER COLUMN "senha" DROP NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "usuarios_google_id_key" ON "usuarios"("google_id");
