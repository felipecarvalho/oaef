#!/usr/bin/env node
// ==============================================================================
// OAEF Governance Engine - React Native Runtime
// Implements docs/standards/governance_checks.md for the `react-native` stack.
// Author: Felipe Carvalho | License: Apache 2.0
// ==============================================================================

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
process.chdir(ROOT);

// ------------------------------------------------------------------------------
// Canonical catalog (must stay byte-identical to AGENTS.md section 3)
// ------------------------------------------------------------------------------
const SKILLS = [
  'ponytail', 'nullable-types', 'architecture-audit', 'screen-builder', 'component-author',
  'responsive-layout', 'ui-preview', 'fix-layout-issues', 'test-generator', 'collect-coverage',
  'run-static-analysis', 'code-review', 'conformance-audit'
];

function skillTriggers(skill) {
  switch (skill) {
    case 'ponytail': return ['new', 'refactor', 'add', 'simple', 'minimal', 'yagni', 'dead code', 'delete', 'remove'];
    case 'screen-builder': return ['screen', 'page', 'feature', 'flow', 'view'];
    case 'component-author': return ['component', 'widget', 'button', 'card', 'modal'];
    case 'ui-preview': return ['preview', 'storybook', 'isolated render'];
    case 'responsive-layout': return ['responsive', 'adaptive', 'breakpoint', 'tablet', 'foldable', 'viewport'];
    case 'fix-layout-issues': return ['overflow', 'unbounded', 'layout', 'layout broken', 'render error'];
    case 'test-generator': return ['test', 'coverage', 'mock', 'fixture'];
    case 'collect-coverage': return ['coverage', 'lcov', 'jacoco', 'cobertura', 'branches'];
    case 'run-static-analysis': return ['analyze', 'lint', 'typecheck', 'warnings'];
    case 'nullable-types': return ['null', 'optional', 'nil', 'guard clause', 'defensive'];
    case 'architecture-audit': return ['architecture', 'boundary', 'coupling', 'cycle'];
    case 'conformance-audit': return ['conformance', 'doctor', 'parity', 'frontmatter'];
    case 'code-review': return ['review', 'pr', 'checklist', 'pre-pr'];
    default: return [];
  }
}

function skillMeta(skill) {
  if (['ponytail', 'collect-coverage', 'run-static-analysis', 'conformance-audit'].includes(skill)) return '—';
  return 'ponytail';
}

const ROUTING_FIXTURES = [
  ['create a new screen for the booking flow', 'screen-builder'],
  ['build a reusable button component', 'component-author'],
  ['the layout overflows on small screens', 'fix-layout-issues'],
  ['add responsive breakpoints for tablet', 'responsive-layout'],
  ['write unit tests for the payment service', 'test-generator'],
  ['collect coverage and check the branch floor', 'collect-coverage'],
  ['fix all analyzer warnings', 'run-static-analysis'],
  ['this optional list parameter is always null', 'nullable-types'],
  ['audit module boundaries and cyclic imports', 'architecture-audit'],
  ['verify the repo conforms to the framework', 'conformance-audit'],
  ['review my PR before I open it', 'code-review'],
  ['remove the dead code and the 1-line use case', 'ponytail']
];

const RECIPES = [
  '1. Feature / Screen Construction: ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review',
  '2. Reusable Component / Module Authoring: ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis',
  '3. Bug Fix / Root-Cause Remediation: ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis',
  '4. Domain, Data & Infrastructure: ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis',
  '5. Pre-Submission / Pull Request Cycle: collect-coverage -> run-static-analysis -> code-review'
];

const MIRROR_DIRS = ['.claude/skills', '.cursor/rules', '.windsurf/skills', '.cline/skills', '.grok/agents'];

const AGENTS_FILE = 'AGENTS.md';
const LLMS_FILE = 'llms.txt';
const CONTEXT_FILE = 'oaef.context.json';
const BASELINE_FILE = 'docs/wiki/metrics/baseline.json';
const ADOPTION_LEDGER = 'docs/wiki/metrics/adoption.json';

// ------------------------------------------------------------------------------
// Profile & adoption resolution
// ------------------------------------------------------------------------------
let PROFILE = 'strict';
let ADOPTION_MODE = 'install';

function jsonValue(key, file) {
  if (!fs.existsSync(file)) return '';
  const text = fs.readFileSync(file, 'utf8');
  const match = text.match(new RegExp('"' + escapeRe(key) + '"\\s*:\\s*"([^"]*)"'));
  return match ? match[1] : '';
}

function resolveProfile() {
  PROFILE = 'strict';
  const contextProfile = jsonValue('strictness', CONTEXT_FILE);
  if (contextProfile) {
    PROFILE = contextProfile;
  } else {
    const baselineProfile = jsonValue('profile', BASELINE_FILE);
    if (baselineProfile) PROFILE = baselineProfile;
  }
  ADOPTION_MODE = jsonValue('adoption_mode', CONTEXT_FILE) || 'install';
}

function isAdoption() {
  return ADOPTION_MODE !== 'install';
}

function userOwnedSkill(skill) {
  if (!fs.existsSync(ADOPTION_LEDGER)) return false;
  const text = fs.readFileSync(ADOPTION_LEDGER, 'utf8');
  const match = text.match(/"user_skills"\s*:\s*\[([^\]]*)\]/);
  if (!match) return false;
  return match[1].includes('"' + skill + '"');
}

const CC_BASELINE_KEYS = {
  'CC-01': 'max_single_letter_identifiers',
  'CC-02': 'max_cryptic_abbreviations',
  'CC-03': 'max_mutable_lazy_initializations',
  'CC-04': 'max_dummy_keys',
  'CC-05': 'max_raw_prints',
  'CC-06': 'max_silent_catches',
  'CC-07': 'max_service_locator_leaks',
  'CC-08': 'max_nullable_collections',
  'CC-09': 'max_unimplemented_placeholders',
  'CC-10': 'max_concrete_client_instantiations',
  'CC-11': 'max_silent_catches'
};

const CC_IDS = ['CC-01', 'CC-02', 'CC-03', 'CC-04', 'CC-05', 'CC-06', 'CC-07', 'CC-08', 'CC-09', 'CC-10', 'CC-11'];

function ccBlocking(id) {
  if (id === 'CC-11') return false;
  if (id === 'CC-04') return true;
  if (isAdoption()) return false;
  return PROFILE === 'strict';
}

function ccThreshold(id) {
  const key = CC_BASELINE_KEYS[id];
  if (!key || !fs.existsSync(BASELINE_FILE)) return 0;
  const text = fs.readFileSync(BASELINE_FILE, 'utf8');
  const match = text.match(new RegExp('"' + escapeRe(key) + '"\\s*:\\s*([0-9][0-9.]*)'));
  return match ? parseFloat(match[1]) : 0;
}

// ------------------------------------------------------------------------------
// File discovery
// ------------------------------------------------------------------------------
const PRODUCTION_ROOTS = ['src', 'app'];
const SOURCE_EXTENSIONS = new Set(['.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs']);

const EXCLUDED_SEGMENTS = new Set([
  '.git', 'node_modules', 'vendor', 'build', 'dist', 'target', 'obj', 'tool', 'docs', 'templates',
  'examples', 'coverage', 'generated', '.oaef', '.github', '.agents', '.claude', '.cursor',
  '.windsurf', '.cline', '.grok', 'bin', '.dart_tool', '.gradle', '.idea', '.venv', 'venv', '__pycache__'
]);

const TEST_SEGMENTS = new Set(['test', 'tests', '__tests__', 'spec', 'specs', 'androidTest', 'iosTest']);

function segmentsOf(relPath) {
  return relPath.split('/');
}

function isExcludedPath(relPath) {
  for (const segment of segmentsOf(relPath)) {
    if (EXCLUDED_SEGMENTS.has(segment)) return true;
  }
  const base = path.posix.basename(relPath);
  if (/\.g\./.test(base)) return true;
  if (/_pb2\.py$/.test(base) || /_pb2_grpc\.py$/.test(base)) return true;
  if (/\.min\.js$/.test(base)) return true;
  if (/\.generated\./.test(base) || /\.freezed\./.test(base) || /\.designer\./.test(base)) return true;
  return false;
}

function isTestPath(relPath) {
  for (const segment of segmentsOf(relPath)) {
    if (TEST_SEGMENTS.has(segment)) return true;
  }
  const base = path.posix.basename(relPath);
  if (/_test\./.test(base)) return true;
  if (/\.spec\./.test(base) || /\.test\./.test(base)) return true;
  if (/^test_.*\.py$/.test(base)) return true;
  if (/Tests\.cs$/.test(base) || /Test\.kt$/.test(base)) return true;
  return false;
}

function isSourceFile(relPath) {
  return SOURCE_EXTENSIONS.has(path.extname(relPath).toLowerCase());
}

function walkDir(dir, out) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  entries.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
  for (const entry of entries) {
    if (entry.isSymbolicLink()) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walkDir(full, out);
    } else if (entry.isFile()) {
      out.push(full);
    }
  }
}

function collectScopedFiles() {
  const files = [];
  for (const root of PRODUCTION_ROOTS) {
    if (fs.existsSync(path.join(ROOT, root))) walkDir(path.join(ROOT, root), files);
  }
  return files
    .map((full) => path.relative(ROOT, full).split(path.sep).join('/'))
    .sort();
}

function productionFiles() {
  return collectScopedFiles().filter(
    (rel) => isSourceFile(rel) && !isExcludedPath(rel) && !isTestPath(rel)
  );
}

function allSourceFiles() {
  return collectScopedFiles().filter((rel) => isSourceFile(rel) && !isExcludedPath(rel));
}

function readLines(relPath) {
  try {
    return fs.readFileSync(relPath, 'utf8').split('\n').map((line) => line.replace(/\r$/, ''));
  } catch {
    return [];
  }
}

// ------------------------------------------------------------------------------
// Finding emission
// ------------------------------------------------------------------------------
const CC_COUNTS = {};
for (const id of CC_IDS) CC_COUNTS[id] = 0;
let CC_TOTAL = 0;
let SK_FAILURES = 0;

function emit(id, file, line, message) {
  process.stdout.write(`${id} ${file}:${line} — ${message}\n`);
  if (Object.prototype.hasOwnProperty.call(CC_COUNTS, id)) CC_COUNTS[id] += 1;
  if (id.startsWith('CC-')) CC_TOTAL += 1;
}

function emitSkill(id, file, line, message) {
  process.stdout.write(`${id} ${file}:${line} — ${message}\n`);
  SK_FAILURES += 1;
}

function escapeRe(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// ------------------------------------------------------------------------------
// CC-01 / CC-02 : identifier discipline
// ------------------------------------------------------------------------------
const CRYPTIC = new Set([
  'cb', 'fn', 'res', 'req', 'btn', 'val', 'tmp', 'ctx', 'el', 'usr', 'mgr',
  'idx', 'cnt', 'buf', 'str', 'num', 'doc', 'elem', 'curr', 'prev'
]);

const KEYWORDS = new Set([
  'if', 'for', 'while', 'switch', 'catch', 'return', 'function', 'typeof', 'instanceof',
  'await', 'new', 'do', 'else', 'delete', 'in', 'of', 'case', 'with', 'yield', 'void',
  'throw', 'try', 'finally', 'class', 'const', 'let', 'var', 'import', 'export', 'default',
  'extends', 'super', 'this', 'null', 'undefined', 'true', 'false', 'async', 'static'
]);

function splitParams(text) {
  const params = [];
  let depth = 0;
  let current = '';
  for (const char of text) {
    if ('([{<'.includes(char)) depth += 1;
    if (')]}>'.includes(char)) depth -= 1;
    if (char === ',' && depth <= 0) {
      params.push(current);
      current = '';
    } else {
      current += char;
    }
  }
  params.push(current);
  return params.map((param) => param.trim()).filter((param) => param.length > 0);
}

function paramIdentifier(param) {
  const match = param.match(/^([A-Za-z_$][A-Za-z0-9_$]*)/);
  return match ? match[1] : '';
}

function collectBindings(line) {
  const names = [];
  const add = (name) => {
    if (name && !KEYWORDS.has(name)) names.push(name);
  };
  let match;

  const declRe = /(?:^|[^\w$.])(?:const|let|var)\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*(?:=|;|,|\)|of\b|in\b)/g;
  while ((match = declRe.exec(line))) add(match[1]);

  const arrowParenRe = /\(([^()]*)\)\s*=>/g;
  while ((match = arrowParenRe.exec(line))) {
    for (const param of splitParams(match[1])) add(paramIdentifier(param));
  }

  const arrowBareRe = /(?:^|[^\w$.])([A-Za-z_$][A-Za-z0-9_$]*)\s*=>/g;
  while ((match = arrowBareRe.exec(line))) add(match[1]);

  const fnRe = /\bfunction\s*[A-Za-z_$]*\s*\(([^()]*)\)/g;
  while ((match = fnRe.exec(line))) {
    for (const param of splitParams(match[1])) add(paramIdentifier(param));
  }

  const methodRe = /(?:^|[^\w$.])([A-Za-z_$][A-Za-z0-9_$]*)\s*\(([^()]*)\)\s*(?::[^;{=]+)?\{/g;
  while ((match = methodRe.exec(line))) {
    if (KEYWORDS.has(match[1])) continue;
    for (const param of splitParams(match[2])) add(paramIdentifier(param));
  }

  const catchRe = /\bcatch\s*\(\s*([A-Za-z_$][A-Za-z0-9_$]*)/g;
  while ((match = catchRe.exec(line))) add(match[1]);

  return names;
}

function checkIdentifierDiscipline(relPath) {
  const lines = readLines(relPath);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const trimmed = line.trim();
    if (trimmed === '' || trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.startsWith('/*')) continue;

    const names = [];
    for (const name of collectBindings(line)) {
      if (!names.includes(name)) names.push(name);
    }

    for (const name of names) {
      if (name.length === 1) {
        if (name === '_') continue;
        if ((name === 'i' || name === 'j') && /\bfor\b/.test(line)) continue;
        emit('CC-01', relPath, index + 1, `prohibited single-letter identifier "${name}"; use a descriptive name`);
        break;
      }
      if (CRYPTIC.has(name.toLowerCase())) {
        emit('CC-02', relPath, index + 1, `prohibited cryptic abbreviation "${name}"; use the full identifier`);
        break;
      }
    }
  }
}

// ------------------------------------------------------------------------------
// CC-03 : mutable lazy initialization
// ------------------------------------------------------------------------------
const LAZY_FIELD_RE = /client|Client|instance|Instance|service|Service|provider|Provider/;

function checkLazyInit(relPath) {
  const lines = readLines(relPath);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (!line.includes('??=')) continue;
    if (!LAZY_FIELD_RE.test(line)) continue;
    emit('CC-03', relPath, index + 1, 'prohibited mutable lazy initialization; inject the dependency via constructor');
  }
}

// ------------------------------------------------------------------------------
// CC-04 : hardcoded placeholder / secret
// ------------------------------------------------------------------------------
const SECRET_POSITIVE = /(dummy_|changeme|TODO_KEY|(api[_-]?key|secret|password|token)\s*[:=]\s*("[^"]*"|'[^']*'))/;
const SECRET_ALLOWED = /(api[_-]?key|secret|password|token)\s*[:=]\s*("[^"]*\{[^"]*"|'[^']*\{[^']*'|\$|process\.env|import\.meta\.env|env\[)/;

function checkSecrets(relPath) {
  const lines = readLines(relPath);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (!SECRET_POSITIVE.test(line)) continue;
    if (SECRET_ALLOWED.test(line)) continue;
    emit('CC-04', relPath, index + 1, 'prohibited hardcoded placeholder/secret; source it from configuration/environment');
  }
}

// ------------------------------------------------------------------------------
// CC-05 : raw print / debug output
// ------------------------------------------------------------------------------
const RAW_PRINT_RE = /console\.(log|debug|warn)\s*\(/;

function checkRawPrints(relPath) {
  const lines = readLines(relPath);
  for (let index = 0; index < lines.length; index += 1) {
    if (!RAW_PRINT_RE.test(lines[index])) continue;
    emit('CC-05', relPath, index + 1, 'prohibited raw print/debug output in production code; use the logging interface');
  }
}

// ------------------------------------------------------------------------------
// CC-06 : silent exception swallowing
// ------------------------------------------------------------------------------
const SILENT_MESSAGE = 'prohibited silent exception swallowing; log with error+stack trace or rethrow';

function checkSilentCatches(relPath) {
  const lines = readLines(relPath);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];

    if (/catch\s*(\([^)]*\))?\s*\{\s*\}\s*$/.test(line)) {
      emit('CC-06', relPath, index + 1, SILENT_MESSAGE);
      continue;
    }

    if (/\.catch\s*\(\s*(?:\([^)]*\)|[A-Za-z_$][A-Za-z0-9_$]*)?\s*=>\s*\{\s*\}\s*\)?/.test(line)) {
      emit('CC-06', relPath, index + 1, SILENT_MESSAGE);
      continue;
    }

    if (/\.catch\s*\(\s*function\s*\([^)]*\)\s*\{\s*\}\s*\)?/.test(line)) {
      emit('CC-06', relPath, index + 1, SILENT_MESSAGE);
      continue;
    }

    if (/catch\s*(\([^)]*\))?\s*\{\s*$/.test(line)) {
      let emptied = true;
      for (let lookahead = 1; lookahead <= 3; lookahead += 1) {
        const upcoming = lines[index + lookahead];
        if (upcoming === undefined) break;
        if (/^\s*$/.test(upcoming) || /^\s*(\/\/|#|\*)/.test(upcoming)) continue;
        if (/^\s*\}/.test(upcoming)) break;
        emptied = false;
        break;
      }
      if (emptied) emit('CC-06', relPath, index + 1, SILENT_MESSAGE);
      continue;
    }
  }
}

// ------------------------------------------------------------------------------
// CC-07 : service-locator resolution outside the composition root
// ------------------------------------------------------------------------------
const SERVICE_LOCATOR_RE = /(?:container|Container)\.get\(|container\.resolve\(|getService\(/;
const DI_BANNED_SEGMENTS = new Set(['domain', 'data', 'services', 'repositories']);

function checkServiceLocator(relPath) {
  const banned = segmentsOf(relPath).some((segment) => DI_BANNED_SEGMENTS.has(segment));
  if (!banned) return;
  const lines = readLines(relPath);
  for (let index = 0; index < lines.length; index += 1) {
    if (!SERVICE_LOCATOR_RE.test(lines[index])) continue;
    emit('CC-07', relPath, index + 1, 'prohibited service-locator resolution outside the composition root/presentation layer; inject via constructor');
  }
}

// ------------------------------------------------------------------------------
// CC-08 : nullable / optional collection parameter
// ------------------------------------------------------------------------------
const COLLECTION_GENERIC_RE = /^(Array|ReadonlyArray|Map|Set)\s*</;
const COLLECTION_RE = /\b(Array|ReadonlyArray|Map|Set)\s*</;
const OPTIONAL_PARAM_RE = /^[A-Za-z_$][A-Za-z0-9_$]*\s*\?\s*:/;

function isNullableCollectionParam(param) {
  if (param.includes('=')) return false;
  const match = param.match(/^[A-Za-z_$][A-Za-z0-9_$]*\s*\??\s*:\s*(.+)$/);
  if (!match) return false;
  const type = match[1].trim();
  const generic = COLLECTION_GENERIC_RE.test(type);
  const collection = COLLECTION_RE.test(type) || /\[\s*\]/.test(type);
  const optional = OPTIONAL_PARAM_RE.test(param);
  const unionNullable = /\|\s*(undefined|null)\b/.test(type);
  return generic || (collection && (optional || unionNullable));
}

function checkNullableCollections(relPath) {
  const lines = readLines(relPath);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const lists = [];
    let match;
    const arrowRe = /\(([^()]*)\)\s*=>/g;
    while ((match = arrowRe.exec(line))) lists.push(match[1]);
    const fnRe = /\bfunction\s*[A-Za-z_$]*\s*\(([^()]*)\)/g;
    while ((match = fnRe.exec(line))) lists.push(match[1]);
    const methodRe = /(?:^|[^\w$.])([A-Za-z_$][A-Za-z0-9_$]*)\s*\(([^()]*)\)\s*(?::[^;{=]+)?\{/g;
    while ((match = methodRe.exec(line))) {
      if (KEYWORDS.has(match[1])) continue;
      lists.push(match[2]);
    }
    let reported = false;
    for (const list of lists) {
      for (const param of splitParams(list)) {
        if (!isNullableCollectionParam(param)) continue;
        emit('CC-08', relPath, index + 1, 'prohibited nullable collection parameter; default to a constant empty collection');
        reported = true;
        break;
      }
      if (reported) break;
    }
  }
}

// ------------------------------------------------------------------------------
// CC-09 : unimplemented placeholder
// ------------------------------------------------------------------------------
const UNIMPLEMENTED_RE = /throw\s+new\s+Error\(\s*['"]Not implemented['"]/;

function checkUnimplemented(relPath) {
  const lines = readLines(relPath);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (!UNIMPLEMENTED_RE.test(line)) continue;
    if (line.includes('echo "not implemented"')) continue;
    emit('CC-09', relPath, index + 1, 'prohibited unimplemented placeholder in production contract; implement the contract (LSP)');
  }
}

// ------------------------------------------------------------------------------
// CC-10 : concrete network-client instantiation outside the composition root
// ------------------------------------------------------------------------------
const CONCRETE_CLIENT_RE = /axios\.create\(|new\s+XMLHttpRequest\(|new\s+HttpClient\(/;

function isCompositionRoot(relPath) {
  const segments = segmentsOf(relPath);
  const base = path.posix.basename(relPath);
  if (/^main\./.test(base)) return true;
  if (segments.includes('di')) return true;
  if (base.includes('composition_root')) return true;
  if (base.includes('Application')) return true;
  if (base.includes('AppDelegate')) return true;
  if (base === 'Program.cs' || base === 'Startup.cs') return true;
  return false;
}

function checkConcreteClient(relPath) {
  if (isCompositionRoot(relPath)) return;
  const lines = readLines(relPath);
  for (let index = 0; index < lines.length; index += 1) {
    if (!CONCRETE_CLIENT_RE.test(lines[index])) continue;
    emit('CC-10', relPath, index + 1, 'prohibited concrete network-client instantiation outside the composition root; depend on an abstraction (DIP)');
  }
}

// ------------------------------------------------------------------------------
// CC-11 : avoidable allocation on a hot path (advisory)
// ------------------------------------------------------------------------------
const ALLOCATION_RE = /\[\s*\.\.\.|\.(map|filter|slice)\(/;
const LOOP_HEADER_RE = /\b(for|while)\s*\(/;
const LOOP_CALLBACK_RE = /\.(forEach|map|filter|reduce|flatMap)\(\s*(?:\([^)]*\)|[A-Za-z_$][A-Za-z0-9_$]*)?\s*=>\s*\{/;

function checkAllocations(relPath) {
  const lines = readLines(relPath);
  let depth = 0;
  const loopDepths = [];
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const insideLoop = loopDepths.some((loopDepth) => depth >= loopDepth);
    if (insideLoop && ALLOCATION_RE.test(line)) {
      emit('CC-11', relPath, index + 1, '[advisory] avoidable allocation on hot path; inspect without copying and return the original reference');
    }
    const opensLoopBlock = LOOP_HEADER_RE.test(line) && line.includes('{');
    const opensCallbackBlock = LOOP_CALLBACK_RE.test(line);
    const depthBefore = depth;
    const opens = (line.match(/\{/g) || []).length;
    const closes = (line.match(/\}/g) || []).length;
    depth += opens - closes;
    if (depth < 0) depth = 0;
    if (opensLoopBlock || opensCallbackBlock) loopDepths.push(depthBefore + 1);
    while (loopDepths.length > 0 && depth < loopDepths[loopDepths.length - 1]) loopDepths.pop();
  }
}

function runCleanCodeChecks() {
  for (const file of productionFiles()) {
    checkIdentifierDiscipline(file);
    checkLazyInit(file);
    checkSecrets(file);
    checkRawPrints(file);
    checkSilentCatches(file);
    checkUnimplemented(file);
    checkServiceLocator(file);
    checkNullableCollections(file);
    checkConcreteClient(file);
  }
  for (const file of allSourceFiles()) {
    checkAllocations(file);
  }
}

function blockingTotal() {
  let total = 0;
  for (const id of CC_IDS) {
    const count = CC_COUNTS[id];
    if (count <= 0) continue;
    if (ccBlocking(id) && count > ccThreshold(id)) total += count;
  }
  return total;
}

function cleanCodeBehavior() {
  return ccBlocking('CC-01') ? 'blocking' : 'advisory';
}

function runCleanCode(forceStandard = false) {
  resolveProfile();
  if (forceStandard) PROFILE = 'standard';
  runCleanCodeChecks();
  process.stdout.write(`Clean Code: ${CC_TOTAL} violation(s) (${PROFILE} profile: ${cleanCodeBehavior()})\n`);
  if (blockingTotal() > 0) process.exit(1);
}

// ------------------------------------------------------------------------------
// PT-01 : ponytail debt markers
// ------------------------------------------------------------------------------
function scanDebtMarkers() {
  for (const file of allSourceFiles()) {
    const lines = readLines(file);
    for (let index = 0; index < lines.length; index += 1) {
      const line = lines[index];
      if (!/(^|[^A-Za-z])(\/\/|#|--|\/\*|\/\/\/|<!--)[^\n]*ponytail:/.test(line)) continue;
      const position = line.indexOf('ponytail:');
      if (position < 0) continue;
      const reason = line.slice(position + 'ponytail:'.length).trim();
      process.stdout.write(`PT-01 ${file}:${index + 1} — ${reason}\n`);
    }
  }
}

function scanNarrationComments() {
  for (const file of productionFiles()) {
    const lines = readLines(file);
    for (let index = 0; index < lines.length; index += 1) {
      if (/^\s*(\/\/|#)\s*(increment|decrement|set|assign|call|return|loop|iterate|initialize|create|check|store)\s/.test(lines[index])) {
        process.stdout.write(`[advisory] [DELETE] ${file}:${index + 1} — narration comment restates the next line\n`);
      }
    }
  }
}

function scanSingleStatementDelegation() {
  const delegationRe = /=>\s*[A-Za-z_][A-Za-z0-9_.]*\([^)]*\)[;]?\s*$|^\s*\{\s*return\s+[A-Za-z_][A-Za-z0-9_.]*\([^)]*\);\s*\}\s*$/;
  for (const file of productionFiles()) {
    const lines = readLines(file);
    for (let index = 0; index < lines.length; index += 1) {
      if (!delegationRe.test(lines[index])) continue;
      process.stdout.write(`[advisory] [SHRINK] ${file}:${index + 1} — single-statement delegation; verify a caller justifies the layer\n`);
    }
  }
}

function runPonytailDebt() {
  scanDebtMarkers();
}

function runPonytailAudit() {
  scanDebtMarkers();
  scanNarrationComments();
  scanSingleStatementDelegation();
}

// ------------------------------------------------------------------------------
// SK-01 .. SK-06 : skill activation invariants
// ------------------------------------------------------------------------------
function skillDir(skill) {
  return `.agents/skills/${skill}`;
}

function frontmatterValue(skill, key) {
  const skillFile = `${skillDir(skill)}/SKILL.md`;
  if (!fs.existsSync(skillFile)) return '';
  const lines = readLines(skillFile);
  if (lines[0] !== '---') return '';
  let collecting = false;
  let value = '';
  const keyRe = new RegExp('^' + escapeRe(key) + ':');
  for (let index = 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (line === '---') break;
    if (keyRe.test(line)) {
      value = line.slice(key.length + 1).replace(/^[ \t]+/, '');
      collecting = true;
      continue;
    }
    if (collecting && /^[ \t]+/.test(line)) {
      const trimmed = line.replace(/^[ \t]+/, '');
      if (/^[>|][-+]?$/.test(value) || value === '') value = trimmed;
      else value = `${value} ${trimmed}`;
      continue;
    }
    if (collecting) collecting = false;
  }
  return value.replace(/[ \t]+$/, '');
}

function frontmatterKeys(skill) {
  const skillFile = `${skillDir(skill)}/SKILL.md`;
  if (!fs.existsSync(skillFile)) return [];
  const lines = readLines(skillFile);
  if (lines[0] !== '---') return [];
  const keys = [];
  for (let index = 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (line === '---') break;
    const match = line.match(/^([A-Za-z][A-Za-z0-9_-]*):/);
    if (match) keys.push(match[1]);
  }
  return keys;
}

function auditSkillsParity() {
  for (const skill of SKILLS) {
    if (!fs.existsSync(`${skillDir(skill)}/SKILL.md`)) {
      emitSkill('SK-01', `.agents/skills/${skill}`, 0, `skill "${skill}" is not listed in .agents/skills (parity required)`);
      continue;
    }
    if (fs.existsSync(AGENTS_FILE) && !fs.readFileSync(AGENTS_FILE, 'utf8').includes('`' + skill + '`')) {
      emitSkill('SK-01', AGENTS_FILE, 0, `skill "${skill}" is not listed in AGENTS.md (parity required)`);
    }
    if (fs.existsSync('README.md') && !fs.readFileSync('README.md', 'utf8').includes(skill)) {
      emitSkill('SK-01', 'README.md', 0, `skill "${skill}" is not listed in README.md (parity required)`);
    }
  }
}

const SKILL_FRONTMATTER_MESSAGE = (skill) =>
  `skill "${skill}" frontmatter must declare "Use when", "Triggers on:" and "Chains into:" with >=150 characters and name==directory`;

function auditSkillsFrontmatter() {
  for (const skill of SKILLS) {
    const skillFile = `${skillDir(skill)}/SKILL.md`;
    if (!fs.existsSync(skillFile)) continue;
    if (isAdoption() && userOwnedSkill(skill)) continue;

    const description = frontmatterValue(skill, 'description');
    if (
      description === ''
      || !description.includes('Use when')
      || !description.includes('Triggers on:')
      || !description.includes('Chains into:')
      || description.length < 150
    ) {
      emitSkill('SK-02', skillFile, 0, SKILL_FRONTMATTER_MESSAGE(skill));
      continue;
    }
    if (frontmatterValue(skill, 'name') !== skill) {
      emitSkill('SK-02', skillFile, 0, SKILL_FRONTMATTER_MESSAGE(skill));
      continue;
    }
    for (const key of frontmatterKeys(skill)) {
      if (['name', 'description', 'argument-hint', 'license', 'metadata'].includes(key)) continue;
      emitSkill('SK-02', skillFile, 0, SKILL_FRONTMATTER_MESSAGE(skill));
    }
    if (!readLines(skillFile).some((line) => line.startsWith('## Territory'))) {
      emitSkill('SK-02', skillFile, 0, SKILL_FRONTMATTER_MESSAGE(skill));
    }
  }
}

function auditEntrypointParity() {
  const llmsText = fs.existsSync(LLMS_FILE) ? fs.readFileSync(LLMS_FILE, 'utf8') : null;
  for (const skill of SKILLS) {
    if (llmsText !== null && !llmsText.includes(skill)) {
      emitSkill('SK-03', LLMS_FILE, 0, `skill "${skill}" is not listed in llms.txt`);
    }
  }
  for (const entry of ['README.md', 'docs/INDEX.md', 'docs/MANIFESTO.md']) {
    if (!fs.existsSync(entry)) continue;
    if (!fs.readFileSync(entry, 'utf8').includes('llms.txt')) {
      emitSkill('SK-03', entry, 0, `entrypoint ${entry} does not reference llms.txt`);
    }
  }
}

function matrixRows() {
  if (!fs.existsSync(AGENTS_FILE)) return [];
  const lines = readLines(AGENTS_FILE);
  const rows = [];
  let inside = false;
  for (const line of lines) {
    if (line.startsWith('### 3.3')) {
      inside = true;
      continue;
    }
    if (inside && line.startsWith('#')) inside = false;
    if (!inside || !line.startsWith('|')) continue;
    const cells = line.split('|');
    if (cells.length < 7) continue;
    let primary = cells[4].replace(/[`\s]/g, '');
    if (primary === '' || primary === 'PrimarySkill') continue;
    const triggers = cells[3].replace(/^\s+|\s+$/g, '');
    rows.push({ primary, triggers });
  }
  return rows;
}

function auditTriggerCoherence() {
  const rows = matrixRows();
  for (const skill of SKILLS) {
    const row = rows.find((candidate) => candidate.primary === skill);
    if (!row) {
      emitSkill('SK-04', AGENTS_FILE, 0, `skill "${skill}" has no dispatch-matrix row`);
      continue;
    }
    if (isAdoption() && userOwnedSkill(skill)) continue;
    const frontmatter = frontmatterValue(skill, 'description').toLowerCase();
    const triggers = [row.triggers];
    for (let trigger of triggers) {
      trigger = trigger.replace(/^"/, '').replace(/"$/, '').toLowerCase();
      if (trigger === '') continue;
      if (!frontmatter.includes(trigger)) {
        emitSkill('SK-04', AGENTS_FILE, 0, `trigger "${trigger}" for skill "${skill}" is missing from its frontmatter "Triggers on:"`);
      }
    }
  }
}

function mirrorPresent(target) {
  try {
    fs.lstatSync(target);
    return true;
  } catch {
    return fs.existsSync(target);
  }
}

function mirrorOf(dir, skill) {
  if (!mirrorPresent(dir)) return null;
  if (fs.existsSync(`${dir}/${skill}`) && fs.statSync(`${dir}/${skill}`).isDirectory()) return `${dir}/${skill}/SKILL.md`;
  if (fs.existsSync(`${dir}/${skill}.md`)) return `${dir}/${skill}.md`;
  if (fs.existsSync(`${dir}/${skill}.mdc`)) return `${dir}/${skill}.mdc`;
  return null;
}

function filesEqual(left, right) {
  try {
    return fs.readFileSync(left).equals(fs.readFileSync(right));
  } catch {
    return false;
  }
}

function auditMirrorParity() {
  for (const dir of MIRROR_DIRS) {
    if (!mirrorPresent(dir)) continue;
    for (const skill of SKILLS) {
      const canonical = `${skillDir(skill)}/SKILL.md`;
      if (!fs.existsSync(canonical)) continue;
      const mirror = mirrorOf(dir, skill);
      if (!mirror || !filesEqual(canonical, mirror)) {
        emitSkill('SK-05', dir, 0, `harness mirror "${dir}" diverges from .agents/skills for skill "${skill}" (run: oaef skills sync-mirrors)`);
      }
    }
  }
}

// --- routing ------------------------------------------------------------------
function candidateForms(token) {
  const forms = [token];
  if (/ies$/.test(token)) forms.push(token.slice(0, token.length - 3) + 'y');
  if (/es$/.test(token)) forms.push(token.slice(0, token.length - 2));
  if (/s$/.test(token)) forms.push(token.slice(0, token.length - 1));
  if (/ing$/.test(token)) forms.push(token.slice(0, token.length - 3));
  if (/ed$/.test(token)) forms.push(token.slice(0, token.length - 2));
  if (/ion$/.test(token)) forms.push(token.slice(0, token.length - 3));
  return forms.filter((form) => form !== '');
}

function commonPrefix(left, right) {
  const limit = Math.min(left.length, right.length);
  for (let position = 0; position < limit; position += 1) {
    if (left[position] !== right[position]) return position;
  }
  return limit;
}

function wordMatch(token, word) {
  if (word === '') return false;
  for (const form of candidateForms(token)) {
    if (form === word) return true;
    if (form.length >= 4 && commonPrefix(form, word) >= 4) return true;
  }
  return false;
}

const TERRITORY = ' features screens pages components shared ui core domain data infra test tests ';

function routePrompt(promptRaw) {
  const prompt = promptRaw.toLowerCase();
  const tokens = prompt.split(/[^a-z0-9-]+/).filter((token) => token.length > 0);
  let best = 'ponytail';
  let bestScore = 0;

  for (const skill of SKILLS) {
    let score = 0;
    for (const word of skill.split('-')) {
      for (const token of tokens) {
        if (wordMatch(token, word)) {
          score += 5;
          break;
        }
      }
    }
    for (const trigger of skillTriggers(skill)) {
      const weight = Math.min(trigger.length, 8);
      if (trigger.includes(' ')) {
        if (prompt.includes(trigger)) score += 3 + weight;
      } else {
        for (const token of tokens) {
          if (wordMatch(token, trigger)) {
            score += 3 + weight;
            break;
          }
        }
      }
    }
    for (const token of tokens) {
      if (TERRITORY.includes(' ' + token + ' ')) score += 1;
    }
    if (score > bestScore) {
      bestScore = score;
      best = skill;
    }
  }

  if (bestScore === 0) best = 'ponytail';
  return best;
}

function runSkillsRoute(query) {
  const primary = routePrompt(query);
  const meta = skillMeta(primary);
  process.stdout.write(`Routing: "${query}"\n`);
  process.stdout.write(`Primary skill: ${primary} ${skillDir(primary)}/SKILL.md\n`);
  process.stdout.write(`Meta-skill: ${meta}\n`);
  process.stdout.write(`Recipes containing ${primary}:\n`);
  for (const recipe of RECIPES) {
    if (recipe.includes(primary)) process.stdout.write(`  ${recipe}\n`);
  }
}

function runSkillsSelftest() {
  for (const [prompt, expected] of ROUTING_FIXTURES) {
    const got = routePrompt(prompt);
    if (got !== expected) {
      emitSkill('SK-06', AGENTS_FILE, 0, `routing self-test failed: prompt "${prompt}" resolved to "${got}" but expected "${expected}"`);
    }
  }
}

function runSkillsAudit(flag) {
  const selftest = flag === '--selftest';
  resolveProfile();
  auditSkillsParity();
  auditSkillsFrontmatter();
  auditEntrypointParity();
  auditTriggerCoherence();
  auditMirrorParity();
  if (selftest) runSkillsSelftest();
  process.stdout.write(`Skills: ${SK_FAILURES} finding(s)\n`);
  if (SK_FAILURES > 0) process.exit(1);
}

function runSkillsSyncMirrors(flag) {
  const checkOnly = flag === '--check';
  resolveProfile();
  let repaired = 0;
  for (const dir of MIRROR_DIRS) {
    if (!mirrorPresent(dir)) continue;
    let linkTarget = null;
    try {
      if (fs.lstatSync(dir).isSymbolicLink()) linkTarget = fs.readlinkSync(dir);
    } catch {
      linkTarget = null;
    }
    if (linkTarget === '../.agents/skills' && fs.existsSync(dir)) {
      process.stdout.write(`✅ ${dir} is a symlink to .agents/skills (parity by construction)\n`);
      continue;
    }
    if (!fs.existsSync(dir) || !fs.statSync(dir).isDirectory()) continue;
    for (const skill of SKILLS) {
      const canonical = `${skillDir(skill)}/SKILL.md`;
      if (!fs.existsSync(canonical)) continue;
      const entry = mirrorOf(dir, skill);
      if (entry) {
        if (!checkOnly && !filesEqual(canonical, entry)) {
          fs.copyFileSync(canonical, entry);
          process.stdout.write(`🔧 ${dir}: repaired mirror for ${skill} (canonical catalog is authoritative)\n`);
          repaired += 1;
        }
        continue;
      }
      if (checkOnly) continue;
      const target = `${dir}/${skill}`;
      let linked = false;
      try {
        fs.symlinkSync(`../.agents/skills/${skill}`, target);
        linked = fs.existsSync(target);
      } catch {
        linked = false;
      }
      if (linked) {
        process.stdout.write(`🔧 ${dir}: created mirror link for ${skill}\n`);
      } else {
        try {
          fs.rmSync(target, { recursive: true, force: true });
        } catch {
          // best effort
        }
        fs.cpSync(skillDir(skill), target, { recursive: true });
        process.stdout.write(`🔧 ${dir}: created mirror copy for ${skill}\n`);
      }
      repaired += 1;
    }
  }

  SK_FAILURES = 0;
  auditMirrorParity();
  if (checkOnly) {
    if (SK_FAILURES > 0) {
      process.stdout.write(`Mirrors: ${SK_FAILURES} divergence(s) detected\n`);
      process.exit(1);
    }
    process.stdout.write('Mirrors: parity verified\n');
    return;
  }
  if (SK_FAILURES > 0) {
    process.stdout.write(`Mirrors: ${SK_FAILURES} divergence(s) remain (user-owned entries are preserved)\n`);
    process.exit(1);
  }
  process.stdout.write(`Mirrors: ${repaired} entry(ies) synchronized, parity verified\n`);
}

// ------------------------------------------------------------------------------
// lint / doctor / quality gate / sync / metrics
// ------------------------------------------------------------------------------
function normalizeMirror(file) {
  return readLines(file).filter((line) => !line.startsWith('<!--')).join('').replace(/[ \t\r\n]/g, '');
}

function walkAll(dir, options = {}) {
  const out = [];
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  entries.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
  for (const entry of entries) {
    if (entry.isSymbolicLink()) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (options.skipDirs && options.skipDirs.has(entry.name)) continue;
      out.push(...walkAll(full, options));
    } else if (entry.isFile()) {
      out.push(full);
    }
  }
  return out;
}

const SECRET_PATTERNS = [
  /sk-[a-zA-Z0-9]{20,}/,
  /ghp_[a-zA-Z0-9]{20,}/,
  /AKIA[0-9A-Z]{16}/,
  /-----BEGIN [A-Z ]*PRIVATE KEY-----/
];

const SUPPRESSION_RE = /(?:\/\/[ \t]*ignore:|\/\*[ \t]*eslint-disable|\/\/[ \t]*@ts-ignore|#[ \t]*noqa|#[ \t]*type:[ \t]*ignore|\/\/nolint|#\[allow\(|@Suppress\(|\/\/[ \t]*swiftlint:disable|#pragma warning disable)/;
const SUPPRESSION_ALLOWED_RE = /(deprecated_member_use|type=lint|SA1019|CS0618|CS0612|DEPRECATION|DeprecatedCallableAddReplaceWith|#\[allow\(deprecated\)|@typescript-eslint\/no-deprecated|W1505|B005|deprecated-method|type:[ \t]*ignore\[deprecated\]|DO NOT EDIT|@generated|\.g\.)/;

function runLint() {
  resolveProfile();
  let failed = false;

  if (fs.existsSync('AGENTS.md') && fs.existsSync('CLAUDE.md')) {
    if (normalizeMirror('AGENTS.md') !== normalizeMirror('CLAUDE.md')) {
      process.stderr.write('❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run "oaef sync".\n');
      failed = true;
    }
  }

  for (const file of walkAll('docs')) {
    let text;
    try {
      text = fs.readFileSync(file, 'utf8');
    } catch {
      continue;
    }
    if (SECRET_PATTERNS.some((pattern) => pattern.test(text))) {
      process.stderr.write('🚨 [SECURITY] Potential secret detected in docs/!\n');
      failed = true;
      break;
    }
  }

  const suppressionSkip = new Set(['.git', 'node_modules', 'build', 'dist', 'docs', 'tool', 'templates', '.agents']);
  const suppressions = [];
  for (const file of walkAll('.', { skipDirs: suppressionSkip })) {
    if (file.endsWith('.md')) continue;
    let lines;
    try {
      lines = readLines(file);
    } catch {
      continue;
    }
    for (let index = 0; index < lines.length; index += 1) {
      const line = lines[index];
      if (!SUPPRESSION_RE.test(line)) continue;
      if (SUPPRESSION_ALLOWED_RE.test(line)) continue;
      suppressions.push(`${path.relative(ROOT, file).split(path.sep).join('/')}:${index + 1}:${line}`);
    }
  }
  if (suppressions.length > 0) {
    process.stderr.write('🚨 [LINT] Unallowed linter/compiler suppression comments detected:\n');
    for (const suppression of suppressions) process.stderr.write(`${suppression}\n`);
    failed = true;
  }

  runCleanCodeChecks();
  auditSkillsParity();
  auditSkillsFrontmatter();
  auditEntrypointParity();
  auditTriggerCoherence();
  auditMirrorParity();
  runSkillsSelftest();
  if (SK_FAILURES > 0) failed = true;

  if (failed) {
    process.stderr.write('❌ LINT FAILED.\n');
    process.exit(1);
  }
  process.stdout.write('✅ [LINT] All integrity and secret audits passed cleanly.\n');
}

const REQUIRED_FILES = [
  'AGENTS.md', 'CLAUDE.md', 'llms.txt', 'oaef.context.json', 'docs/INDEX.md', 'docs/MANIFESTO.md',
  'docs/DESIGN.md', 'docs/HARNESSES.md', 'docs/standards/coding_patterns.md', 'docs/standards/testing.md',
  'docs/standards/logging.md', 'docs/standards/clean_code.md', 'docs/standards/solid.md',
  'docs/standards/review.md', 'docs/standards/analytics_and_telemetry.md',
  'docs/standards/governance_checks.md', 'docs/wiki/metrics/baseline.json', 'docs/wiki/memory/handoff.md',
  'docs/wiki/log.md', '.github/workflows/ci.yml', '.github/pull_request_template.md', '.gitignore',
  'CONTRIBUTING.md', 'SECURITY.md'
];

function runConform() {
  resolveProfile();
  let checks = 0;
  let passed = 0;
  let failed = false;

  process.stdout.write('🩺 OAEF Conformance Audit (doctor)...\n');
  for (const entry of REQUIRED_FILES) {
    checks += 1;
    if (fs.existsSync(entry)) {
      passed += 1;
      process.stdout.write(`✅ ${entry} present\n`);
    } else {
      process.stderr.write(`❌ ${entry} missing\n`);
      failed = true;
    }
  }

  for (const skill of SKILLS) {
    checks += 1;
    if (fs.existsSync(`${skillDir(skill)}/SKILL.md`)) {
      passed += 1;
      process.stdout.write(`✅ .agents/skills/${skill}/SKILL.md present\n`);
    } else {
      process.stderr.write(`❌ .agents/skills/${skill}/SKILL.md missing\n`);
      failed = true;
    }
  }

  checks += 1;
  if (
    fs.existsSync('AGENTS.md') && fs.existsSync('CLAUDE.md')
    && normalizeMirror('AGENTS.md') === normalizeMirror('CLAUDE.md')
  ) {
    passed += 1;
    process.stdout.write('✅ CLAUDE.md mirror parity verified\n');
  } else {
    process.stderr.write('❌ CLAUDE.md mirror parity failed (run oaef sync)\n');
    failed = true;
  }

  checks += 1;
  const agentsText = fs.existsSync('AGENTS.md') ? fs.readFileSync('AGENTS.md', 'utf8') : '';
  const llmsText = fs.existsSync('llms.txt') ? fs.readFileSync('llms.txt', 'utf8') : '';
  if (/\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}/.test(agentsText + '\n' + llmsText)) {
    process.stderr.write('❌ unresolved template placeholders found\n');
    failed = true;
  } else {
    passed += 1;
    process.stdout.write('✅ no unresolved template placeholders\n');
  }

  SK_FAILURES = 0;
  runSkillsSelftest();
  checks += 1;
  if (SK_FAILURES === 0) {
    passed += 1;
    process.stdout.write('✅ routing self-test (SK-06) passed\n');
  } else {
    process.stderr.write('❌ routing self-test (SK-06) failed\n');
    failed = true;
  }

  process.stdout.write(`\n📊 Conformance: ${passed}/${checks} checks passed\n`);
  if (failed) process.exit(1);
}

function readBaseline() {
  if (!fs.existsSync(BASELINE_FILE)) return null;
  try {
    return JSON.parse(fs.readFileSync(BASELINE_FILE, 'utf8'));
  } catch {
    return null;
  }
}

function hasTestScript() {
  if (!fs.existsSync('package.json')) return false;
  try {
    const manifest = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    return Boolean(manifest.scripts && manifest.scripts.test);
  } catch {
    return false;
  }
}

function lcovLinePercent(file) {
  if (!fs.existsSync(file)) return 100.0;
  let found = 0;
  let hit = 0;
  for (const line of readLines(file)) {
    if (line.startsWith('LF:')) found += parseInt(line.slice(3), 10) || 0;
    if (line.startsWith('LH:')) hit += parseInt(line.slice(3), 10) || 0;
  }
  return found === 0 ? 100.0 : (hit / found) * 100.0;
}

function runQualityGate(record = false) {
  resolveProfile();
  process.stdout.write('🔍 Initiating OAEF Quality Gate Audit (React Native)...\n');
  const baseline = readBaseline();
  const minLine = baseline?.baseline?.coverage?.lines_min_percentage ?? 95.0;
  const maxFileLines = baseline?.baseline?.clean_sizing?.file_max_lines ?? 300;

  let linePercent = 100.0;
  if (hasTestScript()) {
    process.stdout.write('ℹ️  Running test suite with coverage...\n');
    try {
      execSync('npm test -- --coverage', { stdio: 'inherit' });
    } catch {
      process.stderr.write('❌ Tests failed.\n');
      process.exit(1);
    }
    linePercent = lcovLinePercent('coverage/lcov.info');
    process.stdout.write(`📊 Line Coverage: ${linePercent.toFixed(1)}% (Floor: ${minLine}%)\n`);
    if (linePercent < minLine) {
      process.stderr.write('❌ Quality Gates Failed.\n');
      process.exit(1);
    }
  } else {
    process.stdout.write('ℹ️  No Node test manifest found; skipping test/coverage stage.\n');
  }

  let oversized = 0;
  for (const file of productionFiles()) {
    const lines = fs.readFileSync(file, 'utf8').split('\n').length;
    if (lines > maxFileLines) {
      process.stderr.write(`⚠️  Oversized file (${lines}L > ${maxFileLines}L): ${file}\n`);
      oversized += 1;
    }
  }
  if (oversized > 0) {
    process.stderr.write(`❌ Quality Gate Failed: ${oversized} oversized files detected.\n`);
    process.exit(1);
  }

  runCleanCodeChecks();
  process.stdout.write(`Clean Code: ${CC_TOTAL} violation(s) (${PROFILE} profile: ${cleanCodeBehavior()})\n`);
  const blocking = blockingTotal();
  if (PROFILE === 'strict' && !isAdoption() && blocking > 0) {
    process.stderr.write(`❌ Quality Gate Failed: ${blocking} clean-code violation(s).\n`);
    process.exit(1);
  }
  process.stdout.write('🎉 Quality Gates PASSED!\n');

  if (record && hasTestScript() && baseline?.baseline?.coverage && linePercent > minLine) {
    baseline.baseline.coverage.lines_min_percentage = parseFloat(linePercent.toFixed(1));
    fs.writeFileSync(BASELINE_FILE, JSON.stringify(baseline, null, 2));
    process.stdout.write(`🔒 Monotonic Ratchet: Updated baseline floor to ${linePercent.toFixed(1)}%\n`);
  }
}

function runSync() {
  if (!fs.existsSync('AGENTS.md')) {
    process.stderr.write('AGENTS.md not found.\n');
    process.exit(1);
  }
  const content = fs.readFileSync('AGENTS.md', 'utf8');
  const banner = '<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n'
    + "<!-- To modify rules, edit AGENTS.md and run 'oaef sync'. -->\n\n";
  fs.writeFileSync('CLAUDE.md', banner + content);
  process.stdout.write('✅ Synchronized AGENTS.md -> CLAUDE.md\n');
}

function runMetrics() {
  if (fs.existsSync(BASELINE_FILE)) process.stdout.write(fs.readFileSync(BASELINE_FILE, 'utf8'));
}

function usage() {
  process.stdout.write(`OAEF Governance Tool (React Native Engine)
Usage: node tool/governance.mjs <command>
Commands:
  quality-gate|audit        Quality Gate audit (coverage, sizing, clean code)
  clean-code [--standard]   Governance barriers (docs/standards/governance_checks.md)
  ponytail-debt             Report every "// ponytail:" debt marker (PT-01)
  ponytail-audit            Advisory anti-slop audit
  skills-audit [--selftest] Skill activation invariants (SK-01..SK-06)
  skills-route "<query>"    Resolve a prompt to its governing skill and recipe
  skills-sync-mirrors [--check] Rebuild or validate the harness skill mirrors
  lint                      Mirror parity, secrets, anti-suppression, skills
  doctor|conform            Conformance audit
  metrics                   Display baseline thresholds
  sync                      Synchronize AGENTS.md to CLAUDE.md
`);
}

// ------------------------------------------------------------------------------
// Dispatch
// ------------------------------------------------------------------------------
const argv = process.argv.slice(2);
const command = argv[0] || '';
const rest = argv.slice(1);

switch (command) {
  case 'quality-gate':
  case 'audit':
    runQualityGate(rest.includes('--record') || rest.includes('--ratchet'));
    break;
  case 'metrics':
    runMetrics();
    break;
  case 'lint':
    runLint();
    break;
  case 'conform':
  case 'doctor':
    runConform();
    break;
  case 'sync':
    runSync();
    break;
  case 'clean-code':
  case 'governance-check':
    runCleanCode(rest.includes('--standard'));
    break;
  case 'ponytail-debt':
    runPonytailDebt();
    break;
  case 'ponytail-audit':
    runPonytailAudit();
    break;
  case 'ponytail':
    if (rest[0] === 'audit') runPonytailAudit();
    else runPonytailDebt();
    break;
  case 'skills-audit':
    runSkillsAudit(rest[0] || '');
    break;
  case 'skills-route':
    runSkillsRoute(rest.join(' '));
    break;
  case 'skills-sync-mirrors':
    runSkillsSyncMirrors(rest[0] || '');
    break;
  case 'skills':
    switch (rest[0]) {
      case 'sync-mirrors':
        runSkillsSyncMirrors(rest[1] || '');
        break;
      case 'audit':
        runSkillsAudit(rest[1] || '');
        break;
      case 'route':
        runSkillsRoute(rest.slice(1).join(' '));
        break;
      default:
        usage();
        process.exit(1);
    }
    break;
  default:
    usage();
    process.exit(1);
}
