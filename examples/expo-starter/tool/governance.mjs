#!/usr/bin/env node
// ==============================================================================
// OAEF Governance Engine - Expo / React Native Runtime
// Implements docs/standards/governance_checks.md for the `expo` stack.
// Author: Felipe Carvalho | License: Apache 2.0
// ==============================================================================

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
process.chdir(ROOT);

// ------------------------------------------------------------------------------
// Canonical catalog (must stay byte-identical to AGENTS.md section 3)
// ------------------------------------------------------------------------------
const SKILLS = [
  'ponytail', 'nullable-types', 'architecture-audit', 'screen-builder', 'component-author',
  'responsive-layout', 'ui-preview', 'fix-layout-issues', 'test-generator', 'collect-coverage',
  'run-static-analysis', 'code-review', 'conformance-audit',
];

const SKILL_TRIGGERS = {
  'ponytail': ['new', 'refactor', 'add', 'simple', 'minimal', 'yagni', 'dead code', 'delete', 'remove'],
  'screen-builder': ['screen', 'page', 'feature', 'flow', 'view'],
  'component-author': ['component', 'widget', 'button', 'card', 'modal'],
  'ui-preview': ['preview', 'storybook', 'isolated render'],
  'responsive-layout': ['responsive', 'adaptive', 'breakpoint', 'tablet', 'foldable', 'viewport'],
  'fix-layout-issues': ['overflow', 'unbounded', 'layout', 'layout broken', 'render error'],
  'test-generator': ['test', 'coverage', 'mock', 'fixture'],
  'collect-coverage': ['coverage', 'lcov', 'jacoco', 'cobertura', 'branches'],
  'run-static-analysis': ['analyze', 'lint', 'typecheck', 'warnings'],
  'nullable-types': ['null', 'optional', 'nil', 'guard clause', 'defensive'],
  'architecture-audit': ['architecture', 'boundary', 'coupling', 'cycle'],
  'conformance-audit': ['conformance', 'doctor', 'parity', 'frontmatter'],
  'code-review': ['review', 'pr', 'checklist', 'pre-pr'],
};

const RECIPES = [
  '1. Feature / Screen Construction: ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review',
  '2. Reusable Component / Module Authoring: ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis',
  '3. Bug Fix / Root-Cause Remediation: ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis',
  '4. Domain, Data & Infrastructure: ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis',
  '5. Pre-Submission / Pull Request Cycle: collect-coverage -> run-static-analysis -> code-review',
];

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
  ['remove the dead code and the 1-line use case', 'ponytail'],
];

const MIRROR_DIRS = ['.claude/skills', '.cursor/rules', '.windsurf/skills', '.cline/skills', '.grok/agents'];

const AGENTS_FILE = 'AGENTS.md';
const LLMS_FILE = 'llms.txt';
const CONTEXT_FILE = 'oaef.context.json';
const BASELINE_FILE = 'docs/wiki/metrics/baseline.json';
const ADOPTION_LEDGER = 'docs/wiki/metrics/adoption.json';

const TERRITORY_VOCABULARY = ' features screens pages components shared ui core domain data infra test tests ';

const EXCLUDED_SEGMENTS = new Set([
  '.git', '.github', '.agents', '.claude', '.cursor', '.windsurf', '.cline', '.grok', '.oaef',
  'node_modules', 'vendor', 'build', 'dist', 'target', 'obj', 'bin', 'tool', 'docs', 'templates',
  'examples', 'coverage', 'generated', '.venv', 'venv', '__pycache__', '.dart_tool', '.gradle', '.idea',
]);
const TEST_SEGMENTS = new Set(['test', 'tests', '__tests__', 'spec', 'specs', 'androidTest', 'iosTest']);
const SOURCE_EXTENSIONS = ['.ts', '.tsx', '.js', '.mjs', '.cjs', '.jsx'];
const FILE_EXCLUSIONS = [/\.g\./, /_pb2\.py$/, /_pb2_grpc\.py$/, /\.min\.js$/, /\.generated\./, /\.freezed\./, /\.designer\./];
const PRODUCTION_ROOTS = new Set(['app', 'src']);
const CRYPTIC = new Set(['cb', 'fn', 'res', 'req', 'btn', 'val', 'tmp', 'ctx', 'el', 'usr', 'mgr', 'idx', 'cnt', 'buf', 'str', 'num', 'doc', 'elem', 'curr', 'prev']);
const METHOD_KEYWORDS = new Set(['if', 'for', 'while', 'switch', 'catch', 'return', 'function', 'typeof', 'await', 'new', 'do', 'else', 'with', 'throw', 'describe', 'it', 'test', 'expect']);
const CC_IDS = ['CC-01', 'CC-02', 'CC-03', 'CC-04', 'CC-05', 'CC-06', 'CC-07', 'CC-08', 'CC-09', 'CC-10', 'CC-11'];
const THRESHOLD_KEYS = {
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
};

const MESSAGES = {
  'CC-01': (name) => `prohibited single-letter identifier "${name}"; use a descriptive name`,
  'CC-02': (name) => `prohibited cryptic abbreviation "${name}"; use the full identifier`,
  'CC-03': () => 'prohibited mutable lazy initialization; inject the dependency via constructor',
  'CC-04': () => 'prohibited hardcoded placeholder/secret; source it from configuration/environment',
  'CC-05': () => 'prohibited raw print/debug output in production code; use the logging interface',
  'CC-06': () => 'prohibited silent exception swallowing; log with error+stack trace or rethrow',
  'CC-07': () => 'prohibited service-locator resolution outside the composition root/presentation layer; inject via constructor',
  'CC-08': () => 'prohibited nullable collection parameter; default to a constant empty collection',
  'CC-09': () => 'prohibited unimplemented placeholder in production contract; implement the contract (LSP)',
  'CC-10': () => 'prohibited concrete network-client instantiation outside the composition root; depend on an abstraction (DIP)',
  'CC-11': () => '[advisory] avoidable allocation on hot path; inspect without copying and return the original reference',
};

const SKILL_MESSAGES = {
  'SK-02': (skill) => `skill "${skill}" frontmatter must declare "Use when", "Triggers on:" and "Chains into:" with >=150 characters and name==directory`,
  'SK-05': (dir, skill) => `harness mirror "${dir}" diverges from .agents/skills for skill "${skill}" (run: oaef skills sync-mirrors)`,
  'SK-06': (prompt, got, expected) => `routing self-test failed: prompt "${prompt}" resolved to "${got}" but expected "${expected}"`,
};

// ------------------------------------------------------------------------------
// Profile & adoption resolution
// ------------------------------------------------------------------------------
let PROFILE = 'strict';
let ADOPTION_MODE = 'install';

function jsonStringValue(key, file) {
  if (!fs.existsSync(file)) return '';
  const match = fs.readFileSync(file, 'utf8').match(new RegExp(`"${key}"\\s*:\\s*"([^"]*)"`));
  return match ? match[1] : '';
}

function resolveProfile() {
  PROFILE = 'strict';
  ADOPTION_MODE = 'install';
  const contextProfile = jsonStringValue('strictness', CONTEXT_FILE);
  if (contextProfile) {
    PROFILE = contextProfile;
  } else {
    const baselineProfile = jsonStringValue('profile', BASELINE_FILE);
    if (baselineProfile) PROFILE = baselineProfile;
  }
  const adoption = jsonStringValue('adoption_mode', CONTEXT_FILE);
  if (adoption) ADOPTION_MODE = adoption;
}

function isAdoption() {
  return ADOPTION_MODE !== 'install';
}

function userOwnedSkill(skill) {
  if (!fs.existsSync(ADOPTION_LEDGER)) return false;
  const text = fs.readFileSync(ADOPTION_LEDGER, 'utf8');
  const start = text.indexOf('"user_skills"');
  if (start < 0) return false;
  const end = text.indexOf(']', start);
  const body = end < 0 ? text.slice(start) : text.slice(start, end);
  return body.includes(`"${skill}"`);
}

function ccBlocks(id) {
  if (id === 'CC-04') return true; // blocking under every profile
  if (id === 'CC-11') return false; // advisory under every profile
  if (isAdoption()) return false;
  return PROFILE === 'strict';
}

function ccThreshold(id) {
  const key = THRESHOLD_KEYS[id];
  if (!key || !fs.existsSync(BASELINE_FILE)) return 0;
  const match = fs.readFileSync(BASELINE_FILE, 'utf8').match(new RegExp(`"${key}"\\s*:\\s*([0-9][0-9.]*)`));
  return match ? Number(match[1]) : 0;
}

// ------------------------------------------------------------------------------
// File discovery
// ------------------------------------------------------------------------------
let FILE_CACHE = null;

function walk(dir, out) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    if (entry.isSymbolicLink()) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (EXCLUDED_SEGMENTS.has(entry.name)) continue;
      walk(full, out);
    } else if (entry.isFile()) {
      out.push(path.relative(ROOT, full).split(path.sep).join('/'));
    }
  }
}

function allFiles() {
  if (FILE_CACHE === null) {
    FILE_CACHE = [];
    walk(ROOT, FILE_CACHE);
    FILE_CACHE.sort();
  }
  return FILE_CACHE;
}

function walkRaw(dir, out) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    if (entry.isSymbolicLink()) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walkRaw(full, out);
    else if (entry.isFile()) out.push(path.relative(ROOT, full).split(path.sep).join('/'));
  }
}

function isSourceFile(file) {
  return SOURCE_EXTENSIONS.some((ext) => file.endsWith(ext));
}

function isExcludedPath(file) {
  for (const segment of file.split('/')) {
    if (EXCLUDED_SEGMENTS.has(segment)) return true;
  }
  const base = path.posix.basename(file);
  return FILE_EXCLUSIONS.some((pattern) => pattern.test(base));
}

function isTestPath(file) {
  for (const segment of file.split('/')) {
    if (TEST_SEGMENTS.has(segment)) return true;
  }
  const base = path.posix.basename(file);
  return /_test\./.test(base) || /\.spec\./.test(base) || /\.test\./.test(base) || /^test_.*\.py$/.test(base) || /Tests\.cs$/.test(base) || /Test\.kt$/.test(base);
}

function isInProductionRoot(file) {
  return PRODUCTION_ROOTS.has(file.split('/')[0]);
}

function productionFiles() {
  return allFiles().filter((file) => isInProductionRoot(file) && isSourceFile(file) && !isExcludedPath(file) && !isTestPath(file));
}

function scannedFiles() {
  // CC-11 and PT-01 also observe test files inside the production roots.
  return allFiles().filter((file) => isInProductionRoot(file) && isSourceFile(file) && !isExcludedPath(file));
}

function readLines(file) {
  try {
    return fs.readFileSync(file, 'utf8').split('\n');
  } catch {
    return [];
  }
}

// ------------------------------------------------------------------------------
// Finding emission
// ------------------------------------------------------------------------------
let ccTotal = 0;
const ccCounts = Object.fromEntries(CC_IDS.map((id) => [id, 0]));
let skFailures = 0;

function emit(id, file, line, message) {
  console.log(`${id} ${file}:${line} — ${message}`);
  if (ccCounts[id] !== undefined) ccCounts[id] += 1;
  if (id.startsWith('CC-')) ccTotal += 1;
}

function emitSkill(id, file, line, message) {
  console.log(`${id} ${file}:${line} — ${message}`);
  skFailures += 1;
}

// ------------------------------------------------------------------------------
// Shared identifier helpers
// ------------------------------------------------------------------------------
function isCryptic(name) {
  return CRYPTIC.has(name.toLowerCase());
}

function splitTopLevel(text) {
  const chunks = [];
  let depth = 0;
  let current = '';
  for (const ch of text) {
    if ('([{<'.includes(ch)) depth += 1;
    else if (')]}>'.includes(ch)) depth -= 1;
    if (ch === ',' && depth === 0) {
      chunks.push(current);
      current = '';
    } else {
      current += ch;
    }
  }
  chunks.push(current);
  return chunks;
}

function chunkBindingName(chunk) {
  let text = chunk.trim();
  if (!text || text.startsWith('{') || text.startsWith('[')) return '';
  text = text.replace(/^\.\.\./, '');
  let cut = text.length;
  let depth = 0;
  for (let i = 0; i < text.length; i += 1) {
    const ch = text[i];
    if ('([{<'.includes(ch)) depth += 1;
    else if (')]}>'.includes(ch)) depth -= 1;
    else if (depth === 0 && (ch === '=' || ch === ':')) {
      cut = i;
      break;
    }
  }
  text = text.slice(0, cut).trim().replace(/^(?:readonly|public|private|protected|static)\s+/, '');
  const match = text.match(/^[A-Za-z_$][\w$]*/);
  return match ? match[0] : '';
}

function matchingParen(line, closeIndex) {
  let depth = 0;
  for (let i = closeIndex; i >= 0; i -= 1) {
    if (line[i] === ')') depth += 1;
    else if (line[i] === '(') {
      depth -= 1;
      if (depth === 0) return i;
    }
  }
  return -1;
}

function paramGroups(line) {
  const groups = [];
  let index = 0;
  while ((index = line.indexOf('=>', index)) !== -1) {
    let cursor = index - 1;
    while (cursor >= 0 && /\s/.test(line[cursor])) cursor -= 1;
    if (cursor >= 0 && line[cursor] === ')') {
      const open = matchingParen(line, cursor);
      if (open >= 0) groups.push(line.slice(open + 1, cursor));
    } else {
      let start = cursor;
      while (start >= 0 && /[A-Za-z0-9_$]/.test(line[start])) start -= 1;
      const name = line.slice(start + 1, cursor + 1);
      if (/^[A-Za-z_$][\w$]*$/.test(name)) groups.push(name);
    }
    index += 2;
  }
  const functionRe = /\bfunction\s*(?:[A-Za-z_$][\w$]*)?\s*\(/g;
  let match;
  while ((match = functionRe.exec(line)) !== null) {
    const open = line.indexOf('(', match.index);
    const close = indexOfClosingParen(line, open);
    if (close > open) groups.push(line.slice(open + 1, close));
  }
  if (/\{\s*$/.test(line) && !line.includes('=>')) {
    const method = line.match(/^\s*(?:export\s+)?(?:default\s+)?(?:(?:public|private|protected|static|async|override|declare)\s+)*(?:get\s+|set\s+)?([A-Za-z_$][\w$]*)\s*\(/);
    if (method && !METHOD_KEYWORDS.has(method[1])) {
      const open = line.indexOf('(', method.index);
      const close = indexOfClosingParen(line, open);
      if (close > open) groups.push(line.slice(open + 1, close));
    }
  }
  return groups;
}

function indexOfClosingParen(line, open) {
  let depth = 0;
  for (let i = open; i < line.length; i += 1) {
    if (line[i] === '(') depth += 1;
    else if (line[i] === ')') {
      depth -= 1;
      if (depth === 0) return i;
    }
  }
  return -1;
}

function isCommentLine(line) {
  const trimmed = line.trimStart();
  return trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*');
}

// ------------------------------------------------------------------------------
// CC-01 / CC-02 : identifier discipline
// ------------------------------------------------------------------------------
function checkIdentifierDiscipline(file, lines) {
  lines.forEach((line, index) => {
    if (isCommentLine(line)) return;
    const lineno = index + 1;
    const bindings = new Map(); // name -> loop binding?
    const record = (name, loop) => {
      if (!name) return;
      bindings.set(name, Boolean(bindings.get(name)) || Boolean(loop));
    };

    let match;
    const declarationRe = /\b(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*(?::[^=;]*)?=/g;
    while ((match = declarationRe.exec(line)) !== null) record(match[1], false);

    const forRe = /\bfor\s*\(\s*(?:const|let|var)\s+([A-Za-z_$][\w$]*)/g;
    while ((match = forRe.exec(line)) !== null) record(match[1], true);

    const catchRe = /\bcatch\s*\(\s*([A-Za-z_$][\w$]*)/g;
    while ((match = catchRe.exec(line)) !== null) record(match[1], false);

    for (const group of paramGroups(line)) {
      for (const chunk of splitTopLevel(group)) record(chunkBindingName(chunk), false);
    }

    for (const [name, loop] of bindings) {
      if (name === '_') continue;
      if (name.length === 1) {
        if ((name === 'i' || name === 'j') && (loop || /\bfor\b/.test(line))) continue;
        emit('CC-01', file, lineno, MESSAGES['CC-01'](name));
      } else if (isCryptic(name)) {
        emit('CC-02', file, lineno, MESSAGES['CC-02'](name));
      }
    }
  });
}

// ------------------------------------------------------------------------------
// CC-03 : mutable lazy initialization
// ------------------------------------------------------------------------------
function checkLazyInit(file, lines) {
  lines.forEach((line, index) => {
    if (!line.includes('??=')) return;
    if (/client|instance|service|provider/i.test(line)) {
      emit('CC-03', file, index + 1, MESSAGES['CC-03']());
    }
  });
}

// ------------------------------------------------------------------------------
// CC-04 : hardcoded placeholder / secret
// ------------------------------------------------------------------------------
function checkSecrets(file, lines) {
  lines.forEach((line, index) => {
    if (isCommentLine(line)) return;
    const lineno = index + 1;
    if (/\b(dummy_|changeme|TODO_KEY)/.test(line)) {
      emit('CC-04', file, lineno, MESSAGES['CC-04']());
      return;
    }
    const assignment = line.match(/\b(api[_-]?key|secret|password|token)\s*[:=]\s*(['"`])([^'"`]*)\2/i);
    if (assignment) {
      const value = assignment[3];
      if (/\$\{|process\.env|\$/.test(value)) return;
      emit('CC-04', file, lineno, MESSAGES['CC-04']());
    }
  });
}

// ------------------------------------------------------------------------------
// CC-05 : raw print / debug output
// ------------------------------------------------------------------------------
function checkRawPrints(file, lines) {
  lines.forEach((line, index) => {
    if (isCommentLine(line) || line.startsWith('#!')) return;
    if (/\bconsole\.(log|debug|warn)\s*\(/.test(line)) {
      emit('CC-05', file, index + 1, MESSAGES['CC-05']());
    }
  });
}

// ------------------------------------------------------------------------------
// CC-06 : silent exception swallowing
// ------------------------------------------------------------------------------
function bodyIsEmpty(lines, startIndex, endPattern) {
  for (let i = startIndex; i < Math.min(lines.length, startIndex + 8); i += 1) {
    const text = lines[i];
    if (/^\s*$/.test(text) || /^\s*(\/\/|#|\*|\/\*)/.test(text)) continue;
    if (endPattern.test(text)) return true;
    return false;
  }
  return true;
}

function checkSilentCatches(file, lines) {
  lines.forEach((line, index) => {
    // Promise handlers: .catch(() => {}) and multiline variants.
    if (/\.catch\s*\(\s*(?:async\s+)?(?:\([^)]*\)|[A-Za-z_$][\w$]*)?\s*=>\s*\{/.test(line)) {
      if (/\{\s*\}\s*\)?\s*;?\s*$/.test(line)) {
        emit('CC-06', file, index + 1, MESSAGES['CC-06']());
      } else if (bodyIsEmpty(lines, index + 1, /^\s*\}\s*\)/)) {
        emit('CC-06', file, index + 1, MESSAGES['CC-06']());
      }
      return;
    }
    // try / catch clauses.
    if (/catch\s*(?:\([^)]*\))?\s*\{\s*\}\s*;?\s*$/.test(line)) {
      emit('CC-06', file, index + 1, MESSAGES['CC-06']());
      return;
    }
    if (/catch\s*(?:\([^)]*\))?\s*\{\s*$/.test(line)) {
      if (bodyIsEmpty(lines, index + 1, /^\s*\}/)) {
        emit('CC-06', file, index + 1, MESSAGES['CC-06']());
      }
    }
  });
}

// ------------------------------------------------------------------------------
// CC-07 : service-locator confinement
// ------------------------------------------------------------------------------
const SERVICE_LOCATOR_RE = /container\.get\(|Container\.get\(|container\.resolve\(|getService\(/;
const LOCATOR_BANNED_SEGMENTS = new Set(['domain', 'data', 'services', 'repositories']);

function checkServiceLocator(file, lines) {
  const banned = file.split('/').some((segment) => LOCATOR_BANNED_SEGMENTS.has(segment));
  if (!banned) return;
  lines.forEach((line, index) => {
    if (SERVICE_LOCATOR_RE.test(line)) {
      emit('CC-07', file, index + 1, MESSAGES['CC-07']());
    }
  });
}

// ------------------------------------------------------------------------------
// CC-08 : nullable collection parameters
// ------------------------------------------------------------------------------
function isCollectionType(type) {
  const normalized = type.trim();
  if (/^(?:Array|ReadonlyArray|Map|Set)\s*</.test(normalized)) return true;
  if (/^(?:ReadonlyArray|Array|Map|Set)\b/.test(normalized)) return true;
  return /\[\s*\]/.test(normalized.split('|')[0]);
}

function checkNullableCollections(file, lines) {
  lines.forEach((line, index) => {
    const seen = new Set();
    for (const group of paramGroups(line)) {
      for (const chunk of splitTopLevel(group)) {
        const text = chunk.trim();
        if (!text || text.startsWith('{') || text.startsWith('[')) continue;
        const match = text.match(/^([A-Za-z_$][\w$]*)\s*(\?)?\s*:\s*([\s\S]+)$/);
        if (!match) continue;
        const [, name, optional, rawType] = match;
        if (seen.has(name)) continue;
        const type = rawType.trim().replace(/,$/, '');
        const nullable = Boolean(optional) || /\|\s*undefined\b/.test(type);
        if (nullable && isCollectionType(type)) {
          seen.add(name);
          emit('CC-08', file, index + 1, MESSAGES['CC-08']());
        }
      }
    }
  });
}

// ------------------------------------------------------------------------------
// CC-09 : unimplemented placeholder
// ------------------------------------------------------------------------------
function checkUnimplemented(file, lines) {
  if (file.endsWith('.md')) return;
  lines.forEach((line, index) => {
    if (/throw\s+new\s+Error\(\s*['"]Not implemented/.test(line)) {
      emit('CC-09', file, index + 1, MESSAGES['CC-09']());
    }
  });
}

// ------------------------------------------------------------------------------
// CC-10 : concrete network-client instantiation (DIP)
// ------------------------------------------------------------------------------
const NETWORK_CLIENT_RE = /axios\.create\(|new\s+XMLHttpRequest\(|new\s+HttpClient\(/;

function isCompositionRoot(file) {
  const segments = file.split('/');
  const base = segments[segments.length - 1];
  if (segments.includes('di')) return true;
  if (file.includes('composition_root')) return true;
  if (/^(?:main|App)\.(?:ts|tsx|js|jsx|mjs|cjs)$/.test(base)) return true;
  if (/^app\.config\./.test(base)) return true;
  return false;
}

function checkConcreteClient(file, lines) {
  if (isCompositionRoot(file)) return;
  lines.forEach((line, index) => {
    if (NETWORK_CLIENT_RE.test(line)) {
      emit('CC-10', file, index + 1, MESSAGES['CC-10']());
    }
  });
}

// ------------------------------------------------------------------------------
// CC-11 : avoidable allocation on a hot path (advisory, also scans tests)
// ------------------------------------------------------------------------------
function checkAllocation(file, lines) {
  let braceDepth = 0;
  const loopDepths = [];
  lines.forEach((line, index) => {
    const inLoop = loopDepths.length > 0;
    if (inLoop && (/\[\.\.\./.test(line) || /\.map\s*\(/.test(line))) {
      emit('CC-11', file, index + 1, MESSAGES['CC-11']());
    }
    const isLoopHeader = /\b(?:for|while)\s*\(/.test(line) && /\{\s*$/.test(line);
    if (isLoopHeader) loopDepths.push(braceDepth + 1);
    const opens = (line.match(/\{/g) || []).length;
    const closes = (line.match(/\}/g) || []).length;
    braceDepth += opens - closes;
    while (loopDepths.length > 0 && braceDepth < loopDepths[loopDepths.length - 1]) loopDepths.pop();
  });
}

// ------------------------------------------------------------------------------
// CC suite runners
// ------------------------------------------------------------------------------
function runCleanCodeReport() {
  for (const file of productionFiles()) {
    const lines = readLines(file);
    checkIdentifierDiscipline(file, lines);
    checkLazyInit(file, lines);
    checkSecrets(file, lines);
    checkRawPrints(file, lines);
    checkSilentCatches(file, lines);
    checkServiceLocator(file, lines);
    checkNullableCollections(file, lines);
    checkUnimplemented(file, lines);
    checkConcreteClient(file, lines);
  }
  for (const file of scannedFiles()) {
    checkAllocation(file, readLines(file));
  }
}

function blockingViolations() {
  let blocking = 0;
  for (const id of CC_IDS) {
    const count = ccCounts[id];
    if (count <= 0) continue;
    if (!ccBlocks(id)) continue;
    if (count > ccThreshold(id)) blocking += count;
  }
  return blocking;
}

function cleanCodeBehavior() {
  return ccBlocks('CC-01') ? 'blocking' : 'advisory';
}

function runCleanCode(args) {
  resolveProfile();
  if (args.includes('--standard')) PROFILE = 'standard';
  runCleanCodeReport();
  const behavior = cleanCodeBehavior();
  console.log(`Clean Code: ${ccTotal} violation(s) (${PROFILE} profile: ${behavior})`);
  if (blockingViolations() > 0) process.exit(1);
}

// ------------------------------------------------------------------------------
// PT-01 : ponytail debt markers
// ------------------------------------------------------------------------------
const DEBT_MARKER_RE = /(?:^|[^A-Za-z])(?:\/\/|#|--|\/\*|<!--)[^\n]*ponytail:(.*)$/;

function scanDebtMarkers() {
  for (const file of scannedFiles()) {
    readLines(file).forEach((line, index) => {
      const match = line.match(DEBT_MARKER_RE);
      if (match) {
        console.log(`PT-01 ${file}:${index + 1} — ${match[1].trim()}`);
      }
    });
  }
}

function runPonytailDebt() {
  scanDebtMarkers();
}

const NARRATION_RE = /^\s*(?:\/\/|#)\s*(?:increment|decrement|set|assign|call|return|loop|iterate|initialize|create|check|store)\s/;
const DELEGATION_RE = /=>(?:\s*[A-Za-z_][A-Za-z0-9_.]*\([^)]*\));?\s*$/;
const BLOCK_DELEGATION_RE = /^\s*\{\s*return\s+[A-Za-z_][A-Za-z0-9_.]*\([^)]*\);\s*\}\s*$/;

function runPonytailAudit() {
  scanDebtMarkers();
  for (const file of productionFiles()) {
    readLines(file).forEach((line, index) => {
      if (NARRATION_RE.test(line)) {
        console.log(`[advisory] [DELETE] ${file}:${index + 1} — narration comment restates the next line`);
      }
      if (DELEGATION_RE.test(line) || BLOCK_DELEGATION_RE.test(line)) {
        console.log(`[advisory] [SHRINK] ${file}:${index + 1} — single-statement delegation; verify a caller justifies the layer`);
      }
    });
  }
}

// ------------------------------------------------------------------------------
// SK-01 .. SK-06 : skill activation invariants
// ------------------------------------------------------------------------------
function skillDir(skill) {
  return `.agents/skills/${skill}`;
}

function skillFile(skill) {
  return `${skillDir(skill)}/SKILL.md`;
}

function frontmatterValue(skill, key) {
  const file = skillFile(skill);
  if (!fs.existsSync(file)) return '';
  const lines = readLines(file);
  if (lines[0] !== '---') return '';
  const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const keyRe = new RegExp(`^${escaped}:`);
  let value = null;
  let collecting = false;
  for (let i = 1; i < lines.length; i += 1) {
    const line = lines[i];
    if (line === '---') break;
    if (value === null) {
      const match = line.match(keyRe);
      if (match) {
        value = line.slice(match[0].length).replace(/^\s+/, '');
        collecting = true;
      }
      continue;
    }
    if (!collecting) continue;
    if (/^\s+/.test(line)) {
      const trimmed = line.replace(/^\s+/, '');
      if (/^[>|][-+]?$/.test(value) || value === '') value = trimmed;
      else value = `${value} ${trimmed}`;
    } else {
      collecting = false;
    }
  }
  if (value === null) return '';
  return value.replace(/\s+$/, '');
}

function frontmatterKeys(skill) {
  const file = skillFile(skill);
  if (!fs.existsSync(file)) return [];
  const lines = readLines(file);
  if (lines[0] !== '---') return [];
  const keys = [];
  for (let i = 1; i < lines.length; i += 1) {
    if (lines[i] === '---') break;
    const match = lines[i].match(/^([A-Za-z][A-Za-z0-9_-]*):/);
    if (match) keys.push(match[1]);
  }
  return keys;
}

function auditSkillsParity() {
  for (const skill of SKILLS) {
    if (!fs.existsSync(skillFile(skill))) {
      emitSkill('SK-01', skillDir(skill), 0, `skill "${skill}" is not listed in .agents/skills (parity required)`);
      continue;
    }
    if (fs.existsSync(AGENTS_FILE) && !fs.readFileSync(AGENTS_FILE, 'utf8').includes(`\`${skill}\``)) {
      emitSkill('SK-01', AGENTS_FILE, 0, `skill "${skill}" is not listed in AGENTS.md (parity required)`);
    }
    if (fs.existsSync('README.md') && !fs.readFileSync('README.md', 'utf8').includes(skill)) {
      emitSkill('SK-01', 'README.md', 0, `skill "${skill}" is not listed in README.md (parity required)`);
    }
  }
}

function auditSkillsFrontmatter() {
  const allowed = new Set(['name', 'description', 'argument-hint', 'license', 'metadata']);
  for (const skill of SKILLS) {
    if (!fs.existsSync(skillFile(skill))) continue;
    if (isAdoption() && userOwnedSkill(skill)) continue;
    const description = frontmatterValue(skill, 'description');
    if (
      !description
      || !description.includes('Use when')
      || !description.includes('Triggers on:')
      || !description.includes('Chains into:')
      || description.length < 150
    ) {
      emitSkill('SK-02', skillFile(skill), 0, SKILL_MESSAGES['SK-02'](skill));
      continue;
    }
    if (frontmatterValue(skill, 'name') !== skill) {
      emitSkill('SK-02', skillFile(skill), 0, SKILL_MESSAGES['SK-02'](skill));
      continue;
    }
    for (const key of frontmatterKeys(skill)) {
      if (!allowed.has(key)) emitSkill('SK-02', skillFile(skill), 0, SKILL_MESSAGES['SK-02'](skill));
    }
    const body = fs.readFileSync(skillFile(skill), 'utf8');
    if (!/^## Territory/m.test(body)) emitSkill('SK-02', skillFile(skill), 0, SKILL_MESSAGES['SK-02'](skill));
  }
}

function auditEntrypointParity() {
  const llms = fs.existsSync(LLMS_FILE) ? fs.readFileSync(LLMS_FILE, 'utf8') : '';
  for (const skill of SKILLS) {
    if (fs.existsSync(LLMS_FILE) && !llms.includes(skill)) {
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
  const rows = [];
  let inside = false;
  for (const line of readLines(AGENTS_FILE)) {
    if (/^### 3\.3/.test(line)) {
      inside = true;
      continue;
    }
    if (inside && /^#/.test(line)) inside = false;
    if (!inside || !/^\|/.test(line)) continue;
    const cells = line.split('|');
    if (cells.length < 7) continue;
    const triggers = cells[3].trim();
    const primary = cells[4].replace(/[`\s]/g, '');
    if (primary === '' || primary === 'PrimarySkill') continue;
    rows.push({ primary, triggers });
  }
  return rows;
}

function auditTriggerCoherence() {
  const rows = matrixRows();
  for (const skill of SKILLS) {
    const row = rows.find((entry) => entry.primary === skill);
    if (!row) {
      emitSkill('SK-04', AGENTS_FILE, 0, `skill "${skill}" has no dispatch-matrix row`);
      continue;
    }
    if (isAdoption() && userOwnedSkill(skill)) continue;
    const frontmatter = frontmatterValue(skill, 'description').toLowerCase();
    for (let trigger of row.triggers.split('|')) {
      trigger = trigger.trim().replace(/^"|"$/g, '').toLowerCase();
      if (!trigger) continue;
      if (!frontmatter.includes(trigger)) {
        emitSkill('SK-04', AGENTS_FILE, 0, `trigger "${trigger}" for skill "${skill}" is missing from its frontmatter "Triggers on:"`);
      }
    }
  }
}

function mirrorPresent(dir) {
  try {
    return fs.existsSync(dir) || fs.lstatSync(dir).isSymbolicLink();
  } catch {
    return false;
  }
}

function mirrorOf(dir, skill) {
  if (!mirrorPresent(dir)) return null;
  if (fs.existsSync(path.join(dir, skill, 'SKILL.md'))) return `${dir}/${skill}/SKILL.md`;
  if (fs.existsSync(`${dir}/${skill}.md`)) return `${dir}/${skill}.md`;
  if (fs.existsSync(`${dir}/${skill}.mdc`)) return `${dir}/${skill}.mdc`;
  return null;
}

function auditMirrorParity() {
  for (const dir of MIRROR_DIRS) {
    if (!mirrorPresent(dir)) continue;
    for (const skill of SKILLS) {
      const canonical = skillFile(skill);
      if (!fs.existsSync(canonical)) continue;
      const mirror = mirrorOf(dir, skill);
      if (!mirror) {
        emitSkill('SK-05', dir, 0, SKILL_MESSAGES['SK-05'](dir, skill));
        continue;
      }
      let same = false;
      try {
        same = Buffer.compare(fs.readFileSync(canonical), fs.readFileSync(mirror)) === 0;
      } catch {
        same = false;
      }
      if (!same) emitSkill('SK-05', dir, 0, SKILL_MESSAGES['SK-05'](dir, skill));
    }
  }
}

// --- routing ------------------------------------------------------------------
function candidateForms(token) {
  const forms = [token];
  if (/ies$/.test(token)) forms.push(`${token.slice(0, -3)}y`);
  if (/es$/.test(token)) forms.push(token.slice(0, -2));
  if (/s$/.test(token)) forms.push(token.slice(0, -1));
  if (/ing$/.test(token)) forms.push(token.slice(0, -3));
  if (/ed$/.test(token)) forms.push(token.slice(0, -2));
  if (/ion$/.test(token)) forms.push(token.slice(0, -3));
  return forms;
}

function commonPrefix(left, right) {
  const limit = Math.min(left.length, right.length);
  let position = 0;
  while (position < limit && left[position] === right[position]) position += 1;
  return position;
}

function wordMatch(token, word) {
  if (!word) return false;
  for (const form of candidateForms(token)) {
    if (form === word) return true;
    if (form.length >= 4 && commonPrefix(form, word) >= 4) return true;
  }
  return false;
}

function routePrompt(prompt) {
  const normalized = String(prompt).toLowerCase();
  const tokens = normalized.split(/[^a-z0-9-]+/).filter((token) => token !== '');
  let best = 'ponytail';
  let bestScore = 0;
  for (const skill of SKILLS) {
    let score = 0;
    for (const nameWord of skill.split('-')) {
      for (const token of tokens) {
        if (wordMatch(token, nameWord)) {
          score += 5;
          break;
        }
      }
    }
    for (const trigger of SKILL_TRIGGERS[skill] || []) {
      const weight = Math.min(trigger.length, 8);
      if (trigger.includes(' ')) {
        if (normalized.includes(trigger)) score += 3 + weight;
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
      if (TERRITORY_VOCABULARY.includes(` ${token} `)) score += 1;
    }
    if (score > bestScore) {
      bestScore = score;
      best = skill;
    }
  }
  return bestScore === 0 ? 'ponytail' : best;
}

function skillMeta(skill) {
  return ['ponytail', 'collect-coverage', 'run-static-analysis', 'conformance-audit'].includes(skill) ? '—' : 'ponytail';
}

function recipesContaining(skill) {
  return RECIPES.filter((recipe) => recipe.includes(skill));
}

function runSkillsRoute(query) {
  const primary = routePrompt(query);
  console.log(`Routing: "${query}"`);
  console.log(`Primary skill: ${primary} ${skillDir(primary)}/SKILL.md`);
  console.log(`Meta-skill: ${skillMeta(primary)}`);
  console.log(`Recipes containing ${primary}:`);
  for (const recipe of recipesContaining(primary)) console.log(`  ${recipe}`);
}

function runSkillsSelftest() {
  for (const [prompt, expected] of ROUTING_FIXTURES) {
    const got = routePrompt(prompt);
    if (got !== expected) {
      emitSkill('SK-06', AGENTS_FILE, 0, SKILL_MESSAGES['SK-06'](prompt, got, expected));
    }
  }
}

function runSkillsAudit(args) {
  const selftest = args.includes('--selftest');
  resolveProfile();
  auditSkillsParity();
  auditSkillsFrontmatter();
  auditEntrypointParity();
  auditTriggerCoherence();
  auditMirrorParity();
  if (selftest) runSkillsSelftest();
  console.log(`Skills: ${skFailures} finding(s)`);
  if (skFailures > 0) process.exit(1);
}

function copyRecursive(source, target) {
  fs.mkdirSync(target, { recursive: true });
  for (const entry of fs.readdirSync(source, { withFileTypes: true })) {
    const from = path.join(source, entry.name);
    const to = path.join(target, entry.name);
    if (entry.isDirectory()) copyRecursive(from, to);
    else if (entry.isFile()) fs.copyFileSync(from, to);
  }
}

function runSkillsSyncMirrors(args) {
  const checkOnly = args.includes('--check');
  resolveProfile();
  let repaired = 0;
  for (const dir of MIRROR_DIRS) {
    if (!mirrorPresent(dir)) continue;
    let isSymlink = false;
    try {
      isSymlink = fs.lstatSync(dir).isSymbolicLink();
    } catch {
      isSymlink = false;
    }
    if (isSymlink && fs.readlinkSync(dir) === '../.agents/skills' && fs.existsSync(dir)) {
      console.log(`✅ ${dir} is a symlink to .agents/skills (parity by construction)`);
      continue;
    }
    if (!fs.existsSync(dir) || !fs.statSync(dir).isDirectory()) continue;
    for (const skill of SKILLS) {
      const canonical = skillFile(skill);
      if (!fs.existsSync(canonical)) continue;
      const entry = mirrorOf(dir, skill);
      if (entry) {
        if (!checkOnly && Buffer.compare(fs.readFileSync(canonical), fs.readFileSync(entry)) !== 0) {
          fs.copyFileSync(canonical, entry);
          console.log(`🔧 ${dir}: repaired mirror for ${skill} (canonical catalog is authoritative)`);
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
        console.log(`🔧 ${dir}: created mirror link for ${skill}`);
      } else {
        try {
          fs.rmSync(target, { recursive: true, force: true });
        } catch {
          /* ignore */
        }
        copyRecursive(skillDir(skill), target);
        console.log(`🔧 ${dir}: created mirror copy for ${skill}`);
      }
      repaired += 1;
    }
  }
  skFailures = 0;
  auditMirrorParity();
  if (checkOnly) {
    if (skFailures > 0) {
      console.log(`Mirrors: ${skFailures} divergence(s) detected`);
      process.exit(1);
    }
    console.log('Mirrors: parity verified');
    return;
  }
  if (skFailures > 0) {
    console.log(`Mirrors: ${skFailures} divergence(s) remain (user-owned entries are preserved)`);
    process.exit(1);
  }
  console.log(`Mirrors: ${repaired} entry(ies) synchronized, parity verified`);
}

// ------------------------------------------------------------------------------
// lint / doctor / quality gate / sync / metrics
// ------------------------------------------------------------------------------
function normalizeMirror(file) {
  return readLines(file)
    .filter((line) => !line.startsWith('<!--'))
    .join('')
    .replace(/[ \t\r\n]/g, '');
}

function runLint() {
  resolveProfile();
  let failed = false;

  if (fs.existsSync('AGENTS.md') && fs.existsSync('CLAUDE.md')) {
    if (normalizeMirror('AGENTS.md') !== normalizeMirror('CLAUDE.md')) {
      console.error('❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run "oaef sync".');
      failed = true;
    }
  }

  const secretRe = /(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)/;
  const docsFiles = [];
  if (fs.existsSync('docs')) walkRaw('docs', docsFiles);
  for (const file of docsFiles) {
    if (secretRe.test(fs.readFileSync(file, 'utf8'))) {
      console.error('🚨 [SECURITY] Potential secret detected in docs/!');
      failed = true;
    }
  }

  const suppressionRe = /(\/\/[ \t]*ignore:|\/\*[ \t]*eslint-disable|\/\/[ \t]*eslint-disable|\/\/[ \t]*@ts-ignore|\/\/[ \t]*@ts-nocheck|\/\/[ \t]*@ts-expect-error|\/\/[ \t]*biome-ignore|#[ \t]*noqa|#[ \t]*type:[ \t]*ignore|\/\/nolint|#\[allow\(|@Suppress\(|\/\/[ \t]*swiftlint:disable|#pragma warning disable)/;
  const suppressed = [];
  for (const file of allFiles()) {
    if (file.endsWith('.md')) continue;
    if (!isSourceFile(file)) continue;
    readLines(file).forEach((line, index) => {
      if (!suppressionRe.test(line)) return;
      if (/(deprecated_member_use|type=lint|SA1019|CS0618|CS0612|DEPRECATION|DeprecatedCallableAddReplaceWith|#\[allow\(deprecated\)|@typescript-eslint\/no-deprecated|W1505|B005|deprecated-method|type:[ \t]*ignore\[deprecated\]|DO NOT EDIT|@generated|\.g\.)/.test(line)) return;
      suppressed.push(`${file}:${index + 1}:${line}`);
    });
  }
  if (suppressed.length > 0) {
    console.error('🚨 [LINT] Unallowed linter/compiler suppression comments detected:');
    for (const entry of suppressed) console.error(entry);
    failed = true;
  }

  runCleanCodeReport();
  auditSkillsParity();
  auditSkillsFrontmatter();
  auditEntrypointParity();
  auditTriggerCoherence();
  auditMirrorParity();
  runSkillsSelftest();
  if (skFailures > 0) failed = true;

  if (failed) {
    console.error('❌ LINT FAILED.');
    process.exit(1);
  }
  console.log('✅ [LINT] All integrity and secret audits passed cleanly.');
}

function runConform() {
  resolveProfile();
  const requiredFiles = [
    'AGENTS.md', 'CLAUDE.md', 'llms.txt', 'oaef.context.json', 'docs/INDEX.md', 'docs/MANIFESTO.md',
    'docs/DESIGN.md', 'docs/HARNESSES.md', 'docs/standards/coding_patterns.md', 'docs/standards/testing.md',
    'docs/standards/logging.md', 'docs/standards/clean_code.md', 'docs/standards/solid.md',
    'docs/standards/review.md', 'docs/standards/analytics_and_telemetry.md', 'docs/standards/governance_checks.md',
    'docs/wiki/metrics/baseline.json', 'docs/wiki/memory/handoff.md', 'docs/wiki/log.md',
    '.github/workflows/ci.yml', '.github/pull_request_template.md', '.gitignore', 'CONTRIBUTING.md', 'SECURITY.md',
  ];
  let checks = 0;
  let passed = 0;
  let failed = false;
  const check = (condition, label) => {
    checks += 1;
    if (condition) {
      passed += 1;
      console.log(`✅ ${label}`);
    } else {
      console.error(`❌ ${label}`);
      failed = true;
    }
  };

  console.log('🩺 OAEF Conformance Audit (doctor)...');
  for (const entry of requiredFiles) check(fs.existsSync(entry), `${entry} present`);
  for (const skill of SKILLS) check(fs.existsSync(skillFile(skill)), `.agents/skills/${skill}/SKILL.md present`);

  check(
    fs.existsSync('AGENTS.md') && fs.existsSync('CLAUDE.md') && normalizeMirror('AGENTS.md') === normalizeMirror('CLAUDE.md'),
    'CLAUDE.md mirror parity verified',
  );

  const agentsText = fs.existsSync('AGENTS.md') ? fs.readFileSync('AGENTS.md', 'utf8') : '';
  const llmsText = fs.existsSync('llms.txt') ? fs.readFileSync('llms.txt', 'utf8') : '';
  check(
    !/\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}/.test(agentsText)
      && !/\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}/.test(llmsText),
    'no unresolved template placeholders',
  );

  const beforeMirrors = skFailures;
  auditMirrorParity();
  check(skFailures === beforeMirrors, 'harness skill mirror parity verified');

  const beforeSelftest = skFailures;
  runSkillsSelftest();
  check(skFailures === beforeSelftest, 'routing self-test (SK-06) passed');

  console.log(`\n📊 Conformance: ${passed}/${checks} checks passed`);
  if (failed) process.exit(1);
}

function runQualityGate() {
  resolveProfile();
  console.log('🔍 Initiating OAEF Quality Gate Audit (Expo)...');
  let oversized = 0;
  for (const file of productionFiles()) {
    const count = readLines(file).length;
    if (count > 300) {
      console.error(`⚠️  Oversized file (${count}L > 300L): ${file}`);
      oversized += 1;
    }
  }
  if (oversized > 0) {
    console.error(`❌ Quality Gate Failed: ${oversized} oversized files detected.`);
    process.exit(1);
  }

  runCleanCodeReport();
  const behavior = cleanCodeBehavior();
  console.log(`Clean Code: ${ccTotal} violation(s) (${PROFILE} profile: ${behavior})`);
  if (PROFILE === 'strict' && !isAdoption() && ccTotal > 0) {
    console.error(`❌ Quality Gate Failed: ${ccTotal} clean-code violation(s).`);
    process.exit(1);
  }
  console.log('🎉 Quality Gates PASSED!');
}

function runSync() {
  if (fs.existsSync(AGENTS_FILE)) {
    const banner = [
      '<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->',
      "<!-- To modify rules, edit AGENTS.md and run 'oaef sync'. -->",
      '',
    ].join('\n');
    fs.writeFileSync('CLAUDE.md', `${banner}\n\n${fs.readFileSync(AGENTS_FILE, 'utf8')}`);
    console.log('✅ Synchronized AGENTS.md -> CLAUDE.md');
  }
}

function runMetrics() {
  if (fs.existsSync(BASELINE_FILE)) process.stdout.write(fs.readFileSync(BASELINE_FILE, 'utf8'));
}

// ------------------------------------------------------------------------------
// Command dispatch
// ------------------------------------------------------------------------------
function usage() {
  console.log(`OAEF Governance Tool (Expo Runtime)
Usage: node tool/governance.mjs <command>
Commands:
  quality-gate|audit        Quality Gate audit (coverage, sizing, clean code)
  clean-code                Governance barriers (docs/standards/governance_checks.md)
  ponytail-debt             Report every "// ponytail:" debt marker (PT-01)
  ponytail-audit            Advisory anti-slop audit
  skills-audit [--selftest] Skill activation invariants (SK-01..SK-06)
  skills-route "<query>"    Resolve a prompt to its governing skill and recipe
  skills sync-mirrors [--check] Rebuild or validate the harness skill mirrors
  lint                      Mirror parity, secrets, anti-suppression, skills
  doctor|conform            Conformance audit
  metrics                   Display baseline thresholds
  sync                      Synchronize AGENTS.md to CLAUDE.md`);
}

const [command = '', ...rest] = process.argv.slice(2);

switch (command) {
  case 'quality-gate':
  case 'audit':
    runQualityGate();
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
    runCleanCode(rest);
    break;
  case 'ponytail-debt':
    runPonytailDebt();
    break;
  case 'ponytail':
  case 'ponytail-audit':
    runPonytailAudit();
    break;
  case 'skills-audit':
    runSkillsAudit(rest);
    break;
  case 'skills-route':
    runSkillsRoute(rest.join(' '));
    break;
  case 'skills': {
    const sub = rest[0];
    if (sub === 'sync-mirrors') runSkillsSyncMirrors(rest.slice(1));
    else if (sub === 'audit') runSkillsAudit(rest.slice(1));
    else if (sub === 'route') runSkillsRoute(rest.slice(1).join(' '));
    else {
      usage();
      process.exit(1);
    }
    break;
  }
  default:
    usage();
    process.exit(1);
}
