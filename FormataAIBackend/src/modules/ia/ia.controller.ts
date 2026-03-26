import { Request, Response } from 'express';
import OpenAI from 'openai';
import { env } from '../../core/env';
import { logger } from '../../core/logger';
import { RotaConfig } from '../../core/types';
import { extrairPaginacao, extrairBusca, extrairFiltroData, montarPaginacao } from '../../core/paginacao';
import { uploadArquivo } from '../../core/s3';
import { FiltrosConversa, CategoriaConversa } from './ia.entity';
import * as iaRepository from './ia.repository';
import * as usuariosRepository from '../usuarios/usuarios.repository';

const openai = new OpenAI({ apiKey: env.OPENAI_API_KEY });

// ─── Rotas ──────────────────────────────────────────────────

export const rotas: RotaConfig[] = [
  { method: 'POST',   path: '/processar',               handler: 'processar',         auth: true, upload: 'audio' },
  { method: 'POST',   path: '/reprocessar',              handler: 'reprocessar',       auth: true },
  { method: 'POST',   path: '/conversas',                handler: 'criarConversa',     auth: true },
  { method: 'GET',    path: '/conversas',                handler: 'listarConversas',   auth: true },
  { method: 'GET',    path: '/conversas/:id',            handler: 'buscarConversa',    auth: true },
  { method: 'PUT',    path: '/conversas/:id',            handler: 'atualizarConversa', auth: true },
  { method: 'DELETE', path: '/conversas/:id',            handler: 'deletarConversa',   auth: true },
  { method: 'GET',    path: '/conversas/:id/mensagens',  handler: 'listarMensagens',   auth: true },
];

// ─── Handlers ───────────────────────────────────────────────

export async function processar(req: Request, res: Response) {
  try {
    const usuarioId = req.usuario!.id;

    // Verificar limite de consultas
    const usuario = await usuariosRepository.buscarUsuarioPorId(usuarioId);
    if (!usuario) {
      res.status(404).json({ erro: 'Usuário não encontrado' });
      return;
    }

    if (usuario.consultasUsadas >= usuario.limiteConsultas) {
      res.status(429).json({ erro: 'Limite de consultas mensais atingido' });
      return;
    }

    const file = req.file;
    if (!file) {
      res.status(400).json({ erro: 'Arquivo de áudio é obrigatório' });
      return;
    }

    // Validar tamanho do arquivo (15MB)
    const maxSize = 15 * 1024 * 1024;
    if (file.size > maxSize) {
      res.status(413).json({ erro: 'Arquivo muito grande. O limite é 15MB.' });
      return;
    }

    // conversaId opcional — se não vier, cria uma nova conversa
    let conversaId = req.body.conversaId as string | undefined;

    // formato escolhido pelo usuário no wizard (ex: WHATSAPP, EMAIL, etc.)
    const formatoEscolhido = req.body.formato as string | undefined;

    // 0. Upload do áudio para S3
    const audioKey = `audios/${usuarioId}/${Date.now()}-${file.originalname}`;
    let audioUrl: string | undefined;
    try {
      const uploadResult = await uploadArquivo(audioKey, file.buffer, file.mimetype);
      audioUrl = uploadResult.url;
    } catch (err) {
      logger.aviso('IA', 'Upload S3 falhou, prosseguindo sem armazenar áudio');
    }

    // 1. Transcrever áudio com Whisper
    const audioFile = new File([Buffer.from(file.buffer)], file.originalname, {
      type: file.mimetype,
    }) as any;
    const transcricaoResult = await openai.audio.transcriptions.create({
      model: 'whisper-1',
      file: audioFile,
      language: 'pt',
    });

    // Filtrar alucinações conhecidas do Whisper (silêncio/áudio muito curto)
    const alucinacoes = [
      'amara.org',
      'legendas pela comunidade',
      'subtitles by',
      'thanks for watching',
      'obrigado por assistir',
      'thank you for watching',
      'inscreva-se',
      'subscribe',
    ];
    let transcricao = transcricaoResult.text.trim();
    const transcricaoLower = transcricao.toLowerCase();
    if (!transcricao || alucinacoes.some(a => transcricaoLower.includes(a))) {
      res.status(400).json({ erro: 'Áudio não contém fala detectável. Tente gravar novamente.' });
      return;
    }

    // 2. Gerar conteúdo formatado com GPT-4o mini
    const instrucaoFormato = formatoEscolhido
      ? `O usuário ESCOLHEU o formato: ${formatoEscolhido}. Gere o conteúdo EXATAMENTE neste formato.`
      : 'Identifique automaticamente o melhor formato para o conteúdo.';

    const formatosDisponiveis: Record<string, string> = {
      WHATSAPP: 'mensagem para WhatsApp — tom informal/amigável, direta, com emojis quando adequado',
      EMAIL: 'email formal/profissional — com saudação, corpo e despedida',
      DOCUMENTO: 'documento formal — estruturado com parágrafos, linguagem formal',
      ORCAMENTO: 'orçamento — com itens, valores, condições e total',
      RECEITA: 'receita médica ou culinária — formato estruturado com ingredientes/itens e instruções',
      RESUMO: 'resumo — síntese objetiva e concisa do conteúdo ditado',
      POSTAGEM: 'postagem para rede social — engajante, com hashtags quando adequado',
      LISTA: 'lista organizada — com tópicos claros e ordenados',
      OUTRO: 'formato livre — escolha o melhor formato para o conteúdo',
    };

    const descricaoFormato = formatoEscolhido && formatosDisponiveis[formatoEscolhido]
      ? formatosDisponiveis[formatoEscolhido]
      : 'formato livre';

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
  content: `
     Você é um sistema automático de formatação de texto a partir de transcrição de voz.

     Sua função é interpretar a intenção do usuário e transformar o conteúdo em um texto claro, bem estruturado e pronto para uso.


      ${instrucaoFormato}
      Formato alvo: ${descricaoFormato}

      REGRAS GERAIS:
      - Corrija erros de fala, repetição e frases incompletas
      - Adicione pontuação adequada (vírgulas, pontos, parágrafos)
      - Reorganize o texto para melhorar clareza e fluidez
      - NÃO invente informações que não foram ditas
      - Se necessário, complete frases de forma coerente com o contexto

      INTERPRETAÇÃO:
      - Identifique automaticamente o tipo de conteúdo (mensagem, email, orçamento, documento, etc)
      - Se for mensagem → texto direto e natural
      - Se for email → incluir saudação, corpo e despedida
      - Se for profissional → usar linguagem mais formal
      - Se for conversa → usar linguagem natural e simples

      REGRAS CRÍTICAS:
      - O campo "resposta" deve conter APENAS o texto final formatado
      - NÃO incluir explicações, comentários ou qualquer texto fora do conteúdo final
      - NÃO usar frases como "Aqui está", "Claro", etc
      - NÃO responder ao usuário — apenas formatar

      FORMATAÇÃO:
      - Use quebras de linha quando necessário
      - Use listas quando fizer sentido
      - Deixe o texto pronto para copiar e enviar

      SAÍDA (OBRIGATÓRIA EM JSON):
      {
        "intencao": "título curto (máx 6 palavras)",
        "categoria": "${formatoEscolhido || 'EMAIL|MENSAGEM|ORCAMENTO|DOCUMENTO|OUTRO'}",
        "resposta": "texto final formatado"
      }
      `,
        },
        { role: 'user', content: transcricao },
      ],
      response_format: { type: 'json_object' },
    });

    const resultadoIA = JSON.parse(completion.choices[0].message.content || '{}');
    // Garante que resposta é sempre string (GPT às vezes retorna array)
    if (Array.isArray(resultadoIA.resposta)) {
      resultadoIA.resposta = resultadoIA.resposta.join('\n');
    }
    const tokensUsados = completion.usage?.total_tokens || 0;

    // 3. Criar conversa se não existe
    if (!conversaId) {
      const categoria = (['EMAIL', 'MENSAGEM', 'ORCAMENTO', 'DOCUMENTO', 'OUTRO'].includes(resultadoIA.categoria)
        ? resultadoIA.categoria
        : 'OUTRO') as CategoriaConversa;

      // Gerar título inteligente com GPT
      let titulo = resultadoIA.intencao || transcricao.substring(0, 60);
      try {
        const tituloResult = await openai.chat.completions.create({
          model: 'gpt-4o-mini',
          messages: [
            {
              role: 'system',
              content: 'Gere um título CURTO (máximo 6 palavras) e descritivo para uma conversa baseada neste contexto. Responda APENAS com o título, sem aspas nem pontuação final.',
            },
            { role: 'user', content: `Intenção: ${resultadoIA.intencao}\nCategoria: ${resultadoIA.categoria}\nConteúdo: ${transcricao.substring(0, 200)}` },
          ],
          max_tokens: 30,
        });
        const tituloGerado = tituloResult.choices[0].message.content?.trim();
        if (tituloGerado && tituloGerado.length > 2) {
          titulo = tituloGerado;
        }
      } catch {
        logger.aviso('IA', 'Falha ao gerar título inteligente, usando fallback');
      }

      const conversa = await iaRepository.criarConversa({
        usuarioId,
        titulo,
        categoria,
      });
      conversaId = conversa.id;
    }

    // 4. Salvar mensagem do usuário
    await iaRepository.criarMensagem({
      conversaId,
      tipo: 'USUARIO',
      audioUrl,
      transcricao,
      conteudo: transcricao,
    });

    // 5. Salvar resposta da IA
    const mensagemIA = await iaRepository.criarMensagem({
      conversaId,
      tipo: 'ASSISTENTE',
      intencao: resultadoIA.intencao,
      conteudo: resultadoIA.resposta || '',
      tokensUsados,
      modeloUsado: 'gpt-4o-mini',
    });

    // 6. Atualizar título da conversa se ainda é "Nova conversa"
    try {
      const conv = await iaRepository.buscarConversaPorId(conversaId);
      if (conv && (conv.titulo === 'Nova conversa' || !conv.titulo)) {
        let titulo = resultadoIA.intencao || transcricao.substring(0, 60);
        try {
          const tituloResult = await openai.chat.completions.create({
            model: 'gpt-4o-mini',
            messages: [
              {
                role: 'system',
                content: 'Gere um título CURTO (máximo 6 palavras) e descritivo para uma conversa baseada neste contexto. Responda APENAS com o título, sem aspas nem pontuação final.',
              },
              { role: 'user', content: `Intenção: ${resultadoIA.intencao}\nCategoria: ${resultadoIA.categoria}\nConteúdo: ${transcricao.substring(0, 200)}` },
            ],
            max_tokens: 30,
          });
          const tituloGerado = tituloResult.choices[0].message.content?.trim();
          if (tituloGerado && tituloGerado.length > 2) titulo = tituloGerado;
        } catch { /* fallback para intencao */ }
        await iaRepository.atualizarConversa(conversaId, { titulo });
      }
    } catch { /* não impede o fluxo */ }

    // 7. Incrementar contador de consultas
    await usuariosRepository.incrementarConsultas(usuarioId);

    res.json({
      conversaId,
      mensagemId: mensagemIA.id,
      transcricao,
      intencao: resultadoIA.intencao,
      categoria: resultadoIA.categoria,
      resposta: resultadoIA.resposta,
      audioUrl: audioUrl || null,
    });
  } catch (error) {
    logger.erro('IA', 'Erro ao processar áudio', error);
    res.status(500).json({ erro: 'Erro ao processar áudio' });
  }
}

/**
 * Reprocessa uma transcrição existente com um novo formato.
 * Body: { mensagemId: string, formato: string }
 */
export async function reprocessar(req: Request, res: Response) {
  try {
    const usuarioId = req.usuario!.id;

    // Verificar limite
    const usuario = await usuariosRepository.buscarUsuarioPorId(usuarioId);
    if (!usuario) {
      res.status(404).json({ erro: 'Usuário não encontrado' });
      return;
    }
    if (usuario.consultasUsadas >= usuario.limiteConsultas) {
      res.status(429).json({ erro: 'Limite de consultas diárias atingido' });
      return;
    }

    const { mensagemId, formato } = req.body;
    if (!mensagemId || !formato) {
      res.status(400).json({ erro: 'mensagemId e formato são obrigatórios' });
      return;
    }

    // Buscar mensagem original (deve ser do tipo USUARIO e pertencer ao usuário)
    const mensagens = await iaRepository.listarMensagens(mensagemId, 0, 1);
    // Na verdade, precisamos buscar a mensagem pelo ID diretamente
    const mensagemOriginal = await iaRepository.buscarMensagemPorId(mensagemId);
    if (!mensagemOriginal) {
      res.status(404).json({ erro: 'Mensagem não encontrada' });
      return;
    }

    // Verificar que pertence ao usuário (via conversa)
    const conversa = await iaRepository.buscarConversaPorId(mensagemOriginal.conversaId);
    if (!conversa || conversa.usuarioId !== usuarioId) {
      res.status(404).json({ erro: 'Mensagem não encontrada' });
      return;
    }

    const transcricao = mensagemOriginal.transcricao || mensagemOriginal.conteudo;
    if (!transcricao) {
      res.status(400).json({ erro: 'Mensagem não possui transcrição para reprocessar' });
      return;
    }

    // Criar nova conversa para o reprocessamento
    const formatosDisponiveis: Record<string, string> = {
      WHATSAPP: 'mensagem para WhatsApp — tom informal/amigável, direta, com emojis quando adequado',
      EMAIL: 'email formal/profissional — com saudação, corpo e despedida',
      DOCUMENTO: 'documento formal — estruturado com parágrafos, linguagem formal',
      ORCAMENTO: 'orçamento — com itens, valores, condições e total',
      RECEITA: 'receita médica ou culinária — formato estruturado com ingredientes/itens e instruções',
      RESUMO: 'resumo — síntese objetiva e concisa do conteúdo ditado',
      POSTAGEM: 'postagem para rede social — engajante, com hashtags quando adequado',
      LISTA: 'lista organizada — com tópicos claros e ordenados',
      OUTRO: 'formato livre — escolha o melhor formato para o conteúdo',
    };

    const descricaoFormato = formatosDisponiveis[formato] || 'formato livre';

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: `Você é um assistente especializado em formatar conteúdo. O usuário quer REFORMATAR um texto que já foi transcrito de áudio.

O formato escolhido é: ${formato}
Descrição: ${descricaoFormato}

Sua tarefa:
1. Identificar a INTENÇÃO do texto
2. A CATEGORIA é: ${formato}
3. Gerar o CONTEÚDO FORMATADO pronto para uso

Responda SEMPRE em JSON com este formato:
{
  "intencao": "descrição curta da intenção identificada",
  "categoria": "${formato}",
  "resposta": "conteúdo formatado pronto para uso"
}`,
        },
        { role: 'user', content: transcricao },
      ],
      response_format: { type: 'json_object' },
    });

    const resultadoIA = JSON.parse(completion.choices[0].message.content || '{}');
    const tokensUsados = completion.usage?.total_tokens || 0;

    // Criar nova conversa
    const categoria = (['EMAIL', 'MENSAGEM', 'ORCAMENTO', 'DOCUMENTO', 'OUTRO'].includes(resultadoIA.categoria)
      ? resultadoIA.categoria
      : 'OUTRO') as CategoriaConversa;

    let titulo = resultadoIA.intencao || transcricao.substring(0, 60);
    try {
      const tituloResult = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: 'Gere um título CURTO (máximo 6 palavras) e descritivo para uma conversa baseada neste contexto. Responda APENAS com o título, sem aspas nem pontuação final.',
          },
          { role: 'user', content: `Intenção: ${resultadoIA.intencao}\nCategoria: ${formato}\nConteúdo: ${transcricao.substring(0, 200)}` },
        ],
        max_tokens: 30,
      });
      const tituloGerado = tituloResult.choices[0].message.content?.trim();
      if (tituloGerado && tituloGerado.length > 2) titulo = tituloGerado;
    } catch {
      logger.aviso('IA', 'Falha ao gerar título no reprocessamento');
    }

    const novaConversa = await iaRepository.criarConversa({ usuarioId, titulo, categoria });

    // Salvar mensagem do usuário (reutiliza transcrição, sem áudio)
    await iaRepository.criarMensagem({
      conversaId: novaConversa.id,
      tipo: 'USUARIO',
      transcricao,
      conteudo: transcricao,
    });

    // Salvar resposta da IA
    const mensagemIA = await iaRepository.criarMensagem({
      conversaId: novaConversa.id,
      tipo: 'ASSISTENTE',
      intencao: resultadoIA.intencao,
      conteudo: resultadoIA.resposta || '',
      tokensUsados,
      modeloUsado: 'gpt-4o-mini',
    });

    await usuariosRepository.incrementarConsultas(usuarioId);

    res.json({
      conversaId: novaConversa.id,
      mensagemId: mensagemIA.id,
      transcricao,
      intencao: resultadoIA.intencao,
      categoria: resultadoIA.categoria,
      resposta: resultadoIA.resposta,
    });
  } catch (error) {
    logger.erro('IA', 'Erro ao reprocessar transcrição', error);
    res.status(500).json({ erro: 'Erro ao reprocessar transcrição' });
  }
}

export async function criarConversa(req: Request, res: Response) {
  try {
    const { titulo, categoria } = req.body;
    const conversa = await iaRepository.criarConversa({
      usuarioId: req.usuario!.id,
      titulo,
      categoria,
    });
    res.status(201).json(conversa);
  } catch (error) {
    logger.erro('IA', 'Erro ao criar conversa', error);
    res.status(500).json({ erro: 'Erro ao criar conversa' });
  }
}

export async function listarConversas(req: Request, res: Response) {
  try {
    const { pagina, limite, skip } = extrairPaginacao(req);
    const busca = extrairBusca(req);
    const { dataInicio, dataFim } = extrairFiltroData(req);

    const filtros: FiltrosConversa = {
      busca,
      dataInicio,
      dataFim,
      categoria: req.query.categoria as CategoriaConversa | undefined,
      favoritada: req.query.favoritada !== undefined ? req.query.favoritada === 'true' : undefined,
      arquivada: req.query.arquivada === 'true' ? true : false,
    };

    const { dados, total } = await iaRepository.listarConversas(
      req.usuario!.id,
      filtros,
      skip,
      limite,
    );

    res.json(montarPaginacao(dados, total, { pagina, limite, skip }));
  } catch (error) {
    logger.erro('IA', 'Erro ao listar conversas', error);
    res.status(500).json({ erro: 'Erro ao listar conversas' });
  }
}

export async function buscarConversa(req: Request, res: Response) {
  try {
    const id = req.params.id as string;
    const conversa = await iaRepository.buscarConversaPorId(id);

    if (!conversa || conversa.usuarioId !== req.usuario!.id) {
      res.status(404).json({ erro: 'Conversa não encontrada' });
      return;
    }

    res.json(conversa);
  } catch (error) {
    logger.erro('IA', 'Erro ao buscar conversa', error);
    res.status(500).json({ erro: 'Erro ao buscar conversa' });
  }
}

export async function atualizarConversa(req: Request, res: Response) {
  try {
    const id = req.params.id as string;
    const conversa = await iaRepository.buscarConversaPorId(id);

    if (!conversa || conversa.usuarioId !== req.usuario!.id) {
      res.status(404).json({ erro: 'Conversa não encontrada' });
      return;
    }

    const { titulo, categoria, favoritada, arquivada } = req.body;
    const atualizada = await iaRepository.atualizarConversa(id, {
      titulo,
      categoria,
      favoritada,
      arquivada,
    });

    res.json(atualizada);
  } catch (error) {
    logger.erro('IA', 'Erro ao atualizar conversa', error);
    res.status(500).json({ erro: 'Erro ao atualizar conversa' });
  }
}

export async function deletarConversa(req: Request, res: Response) {
  try {
    const id = req.params.id as string;
    const conversa = await iaRepository.buscarConversaPorId(id);

    if (!conversa || conversa.usuarioId !== req.usuario!.id) {
      res.status(404).json({ erro: 'Conversa não encontrada' });
      return;
    }

    await iaRepository.deletarConversa(id);
    res.status(204).send();
  } catch (error) {
    logger.erro('IA', 'Erro ao deletar conversa', error);
    res.status(500).json({ erro: 'Erro ao deletar conversa' });
  }
}

export async function listarMensagens(req: Request, res: Response) {
  try {
    const conversaId = req.params.id as string;
    const conversa = await iaRepository.buscarConversaPorId(conversaId);

    if (!conversa || conversa.usuarioId !== req.usuario!.id) {
      res.status(404).json({ erro: 'Conversa não encontrada' });
      return;
    }

    const { pagina, limite, skip } = extrairPaginacao(req);
    const { dados, total } = await iaRepository.listarMensagens(conversaId, skip, limite);

    res.json(montarPaginacao(dados, total, { pagina, limite, skip }));
  } catch (error) {
    logger.erro('IA', 'Erro ao listar mensagens', error);
    res.status(500).json({ erro: 'Erro ao listar mensagens' });
  }
}
