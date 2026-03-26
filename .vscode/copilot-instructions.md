# FormataAI - Instruções do Projeto

## Visão Geral
FormataAI é um aplicativo mobile focado na transcrição de voz e geração inteligente de conteúdo usando IA. O objetivo é eliminar a barreira técnica na formulação de prompts, permitindo que usuários obtenham documentos formatados (emails, mensagens, orçamentos etc.) apenas com comandos de voz.

**Público-alvo:** Profissionais liberais, donos de pequenos negócios, pessoas 50+ anos, usuários com pouca fluência tecnológica.

## Arquitetura

### Frontend
- **Framework:** Flutter (Dart)
- **Premissa UX:** Máximo 3 toques por ação, botão único de gravação, interface acessível para público idoso

### Backend
- **Runtime:** Node.js
- **Linguagem:** TypeScript (NUNCA usar JavaScript puro)
- **Framework:** Express.js
- **ORM:** Prisma
- **Banco de dados:** PostgreSQL
- **Autenticação:** JWT (jsonwebtoken) + bcryptjs + Google OAuth (google-auth-library)
- **Segurança:** helmet, cors, express-rate-limit
- **Upload:** multer
- **IA:** OpenAI (Whisper para transcrição, GPT-4o mini para geração)

### Padrão Arquitetural: BFF (Backend For Frontend)
Cada módulo em `src/modules/` segue a estrutura:
```
src/modules/<nome-modulo>/
  ├── <nome>.controller.ts # Lógica de rota (handlers) + export rotas[]
  ├── <nome>.entity.ts     # Tipagens/interfaces da entidade
  └── <nome>.repository.ts # Acesso a dados (Prisma)
```

### Manifest Único Auto-Gerado
Existe um **único** `manifest.json` na **raiz** do backend que registra todas as rotas de todos os módulos.
Ele é **gerado automaticamente** pelo script `npm run manifest` (que roda `src/core/gerar-manifest.ts`).
O script lê o `export const rotas: RotaConfig[]` de cada controller e gera o manifest.

**NUNCA editar manifest.json manualmente** — ele é regenerado automaticamente no `predev` e `prebuild`.

Cada controller deve exportar suas rotas assim:
```typescript
import { RotaConfig } from '../../core/types';

export const rotas: RotaConfig[] = [
  { method: 'GET',  path: '/buscar-perfil', handler: 'buscarPerfil', auth: true },
  { method: 'POST', path: '/processar',     handler: 'processar',    auth: true, upload: 'audio' },
];
```

### Convenção de Rotas
As rotas são registradas automaticamente. O prefixo da rota é o nome da pasta do módulo.

**Formato:** `GET /api/<pasta>/<path>`

**Exemplo:** `buscarPerfil` na pasta `usuarios/` → `GET /api/usuarios/buscar-perfil`

### Estrutura de Pastas do Backend
```
FormataAIBackend/
  ├── manifest.json             # AUTO-GERADO — nunca editar manualmente
  ├── src/
  │   ├── core/
  │   │   ├── server.ts           # Configuração Express
  │   │   ├── router.ts           # Lê manifest.json e registra rotas
  │   │   ├── env.ts              # Variáveis de ambiente tipadas
  │   │   ├── types.ts            # Tipos compartilhados (RotaConfig, etc)
  │   │   ├── paginacao.ts        # Helpers de paginação, filtros, FTS
  │   │   ├── cron.ts             # Jobs agendados (limpeza S3 diária, reset consultas mensal)
  │   │   ├── s3.ts               # Upload/download/limpeza de arquivos no AWS S3
  │   │   ├── logger.ts           # Logger colorido para console
  │   │   └── gerar-manifest.ts   # Script que gera manifest.json
  │   ├── database/
  │   │   └── prisma.ts           # Instância do Prisma Client
  │   ├── middlewares/
  │   │   ├── auth.middleware.ts   # Verificação JWT
  │   │   ├── upload.middleware.ts # Multer para áudio
  │   │   ├── request-logger.middleware.ts # Log de requisições
  │   │   └── error.middleware.ts  # Handler de erros global
  │   └── modules/
  │       ├── auth/               # Login, registro, Google OAuth, alterar senha, deletar conta
  │       ├── ia/                 # Conversas, mensagens, Whisper + GPT
  │       └── usuarios/           # Perfil, atualização, estatísticas
  ├── prisma/
  │   ├── schema.prisma
  │   └── migrations/
  ├── tsconfig.json
  └── package.json
```

### Banco de Dados (Prisma Schema)
- **Usuario** — cadastro, plano (GRATUITO/PREMIUM), limite de consultas, suporta login por Email e Google (provedor, googleId, fotoUrl, senha nullable)
- **RefreshToken** — tokens de refresh para sessões
- **Conversa** — agrupa mensagens, tem categoria (EMAIL/MENSAGEM/ORCAMENTO/DOCUMENTO/OUTRO), favoritar/arquivar
- **Mensagem** — cada interação (USUARIO/ASSISTENTE), guarda transcrição, intenção, conteúdo, tokens usados

### Paginação e Filtros
Usar helpers de `src/core/paginacao.ts`:
- `extrairPaginacao(req)` — ?pagina=1&limite=20
- `extrairBusca(req)` — ?busca=texto (busca case-insensitive)
- `extrairFiltroData(req)` — ?dataInicio=2024-01-01&dataFim=2024-12-31
- `montarPaginacao(dados, total, params)` — resposta padronizada

## Regras de Código

1. **Sempre TypeScript** — nunca `.js`, sempre `.ts`
2. **Nomes em português** para entidades, variáveis de domínio e rotas
3. **Kebab-case** para nomes de rotas (buscar-usuarios, criar-usuario)
4. **camelCase** para funções e variáveis
5. **PascalCase** para interfaces e tipos
6. **Imports com caminhos relativos**
7. **Async/await** em vez de callbacks
8. **Tratamento de erros** centralizado no middleware
9. **Variáveis sensíveis** sempre via `.env`
10. **Validação de input** nas camadas de controller

## Modelo de Monetização
- Freemium com Google AdMob
- 50 consultas gratuitas/mês por usuário

## APIs Externas
- **OpenAI Whisper API** — transcrição de áudio para texto
- **OpenAI GPT-4o mini** — interpretação de intenção e geração de conteúdo formatado
- **Google OAuth** — verificação de idToken do Google Sign-In (via google-auth-library)

## Catálogo de Endpoints (15 rotas)

### Auth (`/api/auth/`)
| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| POST | `/registrar` | ❌ | Registro com email/senha |
| POST | `/login` | ❌ | Login com email/senha |
| POST | `/google` | ❌ | Login/registro via Google idToken |
| POST | `/alterar-senha` | ✅ | Alterar ou definir senha (Google users) |
| DELETE | `/deletar-conta` | ✅ | Deletar conta e todos os dados |

### Usuarios (`/api/usuarios/`)
| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| GET | `/buscar-perfil` | ✅ | Retorna perfil (sem senha) |
| PUT | `/atualizar-perfil` | ✅ | Atualizar nome, email, fotoUrl |
| GET | `/estatisticas` | ✅ | Consultas usadas/restantes, plano |

### IA (`/api/ia/`)
| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| POST | `/processar` | ✅ | Upload áudio → transcrição → resposta IA |
| POST | `/conversas` | ✅ | Criar nova conversa |
| GET | `/conversas` | ✅ | Listar conversas (paginação, busca, filtros) |
| GET | `/conversas/:id` | ✅ | Detalhe de conversa |
| PUT | `/conversas/:id` | ✅ | Atualizar título/categoria/favoritar/arquivar |
| DELETE | `/conversas/:id` | ✅ | Deletar conversa |
| GET | `/conversas/:id/mensagens` | ✅ | Listar mensagens da conversa |

## Fluxo de Autenticação Google (Flutter → Backend)
1. Flutter usa `google_sign_in` para obter o `idToken` do Google
2. Flutter envia `POST /api/auth/google` com `{ idToken }` no body
3. Backend verifica o idToken com `OAuth2Client.verifyIdToken()` no Google servers
4. Três cenários:
   - **Conta Google existente** → retorna token JWT
   - **Conta email existente** com mesmo email → vincula Google à conta (merge)
   - **Conta nova** → cria usuário com `provedor: GOOGLE`, sem senha
5. Resposta: `{ token, usuario: { id, nome, email, fotoUrl, provedor } }`

## Jobs Agendados (Cron)
- **Limpeza S3** — Diário (00:00): Remove arquivos de áudio expirados
- **Reset consultas** — Mensal (dia 1, 00:00): Zera `consultasUsadas` de todos os usuários

## Testes
- **Framework:** vitest + @vitest/coverage-v8
- **Localização:** `tests/` (mesma estrutura do `src/`)
- **Total:** 16 suítes, 149 testes, 97.5% cobertura de statements
- **Comando:** `npx vitest run --coverage`

## Variáveis de Ambiente (.env)
```
DATABASE_URL, PORT, JWT_SECRET, JWT_EXPIRES_IN, OPENAI_API_KEY, GOOGLE_CLIENT_ID,
AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, S3_BUCKET_NAME, S3_DIAS_EXPIRACAO
```
