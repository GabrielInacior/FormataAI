import chalk from 'chalk';

// ─── Cores por método HTTP ──────────────────────────────────

const metodosCores: Record<string, (text: string) => string> = {
  GET:    chalk.green,
  POST:   chalk.blue,
  PUT:    chalk.yellow,
  DELETE: chalk.red,
  PATCH:  chalk.magenta,
};

const statusCor = (status: number): ((text: string) => string) => {
  if (status >= 500) return chalk.bgRed.white;
  if (status >= 400) return chalk.red;
  if (status >= 300) return chalk.cyan;
  if (status >= 200) return chalk.green;
  return chalk.white;
};

// ─── Logger principal ───────────────────────────────────────

export const logger = {
  /** Log de requisição HTTP colorido */
  requisicao(method: string, path: string, status: number, duracaoMs: number) {
    const metodoFmt = (metodosCores[method] || chalk.white)(method.padEnd(6));
    const statusFmt = statusCor(status)(String(status));
    const pathFmt = chalk.white(path);
    const duracaoFmt = duracaoMs < 100
      ? chalk.green(`${duracaoMs}ms`)
      : duracaoMs < 500
        ? chalk.yellow(`${duracaoMs}ms`)
        : chalk.red(`${duracaoMs}ms`);

    const timestamp = chalk.gray(new Date().toLocaleTimeString('pt-BR'));
    console.log(`${timestamp} ${metodoFmt} ${pathFmt} ${statusFmt} ${duracaoFmt}`);
  },

  /** Log informativo */
  info(contexto: string, mensagem: string) {
    const timestamp = chalk.gray(new Date().toLocaleTimeString('pt-BR'));
    console.log(`${timestamp} ${chalk.bgBlue.white(` ${contexto} `)} ${chalk.white(mensagem)}`);
  },

  /** Log de sucesso */
  sucesso(contexto: string, mensagem: string) {
    const timestamp = chalk.gray(new Date().toLocaleTimeString('pt-BR'));
    console.log(`${timestamp} ${chalk.bgGreen.black(` ${contexto} `)} ${chalk.green(mensagem)}`);
  },

  /** Log de aviso */
  aviso(contexto: string, mensagem: string) {
    const timestamp = chalk.gray(new Date().toLocaleTimeString('pt-BR'));
    console.warn(`${timestamp} ${chalk.bgYellow.black(` ${contexto} `)} ${chalk.yellow(mensagem)}`);
  },

  /** Log de erro (try/catch) */
  erro(contexto: string, mensagem: string, error?: unknown) {
    const timestamp = chalk.gray(new Date().toLocaleTimeString('pt-BR'));
    console.error(`${timestamp} ${chalk.bgRed.white(` ${contexto} `)} ${chalk.red(mensagem)}`);
    if (error instanceof Error) {
      console.error(chalk.gray(`  ↳ ${error.message}`));
      if (process.env.NODE_ENV === 'development' && error.stack) {
        const stackLines = error.stack.split('\n').slice(1, 4);
        stackLines.forEach((line) => console.error(chalk.gray(`    ${line.trim()}`)));
      }
    }
  },

  /** Separador visual para inicialização */
  banner(porta: number, ambiente: string) {
    console.log('');
    console.log(chalk.cyan('  ╔══════════════════════════════════════════╗'));
    console.log(chalk.cyan('  ║') + chalk.white.bold('   🎙️  FormataAI Backend                 ') + chalk.cyan('║'));
    console.log(chalk.cyan('  ╠══════════════════════════════════════════╣'));
    console.log(chalk.cyan('  ║') + `   Porta:    ${chalk.green(String(porta).padEnd(27))}` + chalk.cyan('║'));
    console.log(chalk.cyan('  ║') + `   Ambiente: ${chalk.yellow(ambiente.padEnd(27))}` + chalk.cyan('║'));
    console.log(chalk.cyan('  ╚══════════════════════════════════════════╝'));
    console.log('');
  },
};
