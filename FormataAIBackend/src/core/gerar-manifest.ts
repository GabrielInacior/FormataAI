/**
 * Script que escaneia todos os controllers em src/modules/
 * e gera automaticamente o manifest.json na raiz do backend.
 *
 * Cada controller deve exportar:
 *   export const rotas: RotaConfig[] = [...]
 *
 * Uso: npx tsx src/core/gerar-manifest.ts
 *      ou: npm run manifest
 */
import fs from 'fs';
import path from 'path';

interface RotaManifest {
  method: string;
  path: string;
  handler: string;
  auth?: boolean;
  upload?: string;
}

interface ModuloManifest {
  moduleName: string;
  controller: string;
  routes: RotaManifest[];
}

interface Manifest {
  generatedAt: string;
  modules: ModuloManifest[];
}

function gerarManifest() {
  const modulesDir = path.join(__dirname, '..', 'modules');
  const manifestPath = path.join(__dirname, '..', '..', 'manifest.json');

  const moduleFolders = fs.readdirSync(modulesDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name);

  const modules: ModuloManifest[] = [];

  for (const folder of moduleFolders) {
    const controllerFile = path.join(modulesDir, folder, `${folder}.controller.ts`);

    if (!fs.existsSync(controllerFile)) {
      console.warn(`[MANIFEST] Módulo "${folder}" sem controller — ignorado`);
      continue;
    }

    // Lê o arquivo .ts e extrai o array `rotas` via regex
    const content = fs.readFileSync(controllerFile, 'utf-8');
    const rotas = extrairRotas(content);

    if (rotas.length === 0) {
      console.warn(`[MANIFEST] Módulo "${folder}" sem rotas exportadas — ignorado`);
      continue;
    }

    modules.push({
      moduleName: folder,
      controller: `${folder}.controller`,
      routes: rotas,
    });

    console.log(`[MANIFEST] ${folder}: ${rotas.length} rota(s) encontrada(s)`);
  }

  const manifest: Manifest = {
    generatedAt: new Date().toISOString(),
    modules,
  };

  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf-8');
  console.log(`\n[MANIFEST] Gerado com sucesso: manifest.json (${modules.length} módulos, ${modules.reduce((a, m) => a + m.routes.length, 0)} rotas)`);
}

function extrairRotas(fileContent: string): RotaManifest[] {
  // Procura: export const rotas: RotaConfig[] = [ ... ];
  // ou:      export const rotas = [ ... ];
  const rotasMatch = fileContent.match(/export\s+const\s+rotas\s*(?::\s*RotaConfig\[\])?\s*=\s*\[([\s\S]*?)\];/);

  if (!rotasMatch) return [];

  const rotasBlock = rotasMatch[1];
  const rotas: RotaManifest[] = [];

  // Extrai cada objeto { ... } dentro do array
  const objectRegex = /\{([^}]+)\}/g;
  let match;

  while ((match = objectRegex.exec(rotasBlock)) !== null) {
    const objStr = match[1];
    const rota: Partial<RotaManifest> = {};

    // Extrai method
    const methodMatch = objStr.match(/method\s*:\s*['"](\w+)['"]/);
    if (methodMatch) rota.method = methodMatch[1];

    // Extrai path
    const pathMatch = objStr.match(/path\s*:\s*['"]([^'"]+)['"]/);
    if (pathMatch) rota.path = pathMatch[1];

    // Extrai handler
    const handlerMatch = objStr.match(/handler\s*:\s*['"](\w+)['"]/);
    if (handlerMatch) rota.handler = handlerMatch[1];

    // Extrai auth
    const authMatch = objStr.match(/auth\s*:\s*(true|false)/);
    if (authMatch) rota.auth = authMatch[1] === 'true';

    // Extrai upload
    const uploadMatch = objStr.match(/upload\s*:\s*['"](\w+)['"]/);
    if (uploadMatch) rota.upload = uploadMatch[1];

    if (rota.method && rota.path && rota.handler) {
      rotas.push(rota as RotaManifest);
    }
  }

  return rotas;
}

gerarManifest();
