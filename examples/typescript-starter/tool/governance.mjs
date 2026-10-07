#!/usr/bin/env node
// ==============================================================================
// OAEF Governance Engine — TypeScript & Web
// Implements docs/standards/governance_checks.md for the `typescript-web` stack.
// Author: Felipe Carvalho | License: Apache License 2.0
// ==============================================================================

import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
process.chdir(ROOT);

// A closed pipe (for example `oaef lint | head`) is not a governance failure.
process.stdout.on('error', (error) => {
  if (error && error.code === 'EPIPE') process.exit(0);
});

// ------------------------------------------------------------------------------
// Canonical catalog (must stay byte-identical to AGENTS.md section 3)
// ------------------------------------------------------------------------------
const SKILLS = [
  'ponytail', 'nullable-types', 'architecture-audit', 'screen-builder', 'component-author',
  'responsive-layout', 'ui-preview', 'fix-layout-issues', 'test-generator', 'collect-coverage',
  'run-static-analysis', 'code-review', 'conformance-audit',
];

const SKILL_TRIGGERS = {
  ponytail: 'new|refactor|add|simple|minimal|yagni|dead code|delete|remove',
  'screen-builder': 'screen|page|feature|flow|view',
  'component-author': 'component|widget|button|card|modal',
  'ui-preview': 'preview|storybook|isolated render',
  'responsive-layout': 'responsive|adaptive|breakpoint|tablet|foldable|viewport',
  'fix-layout-issues': 'overflow|unbounded|layout|layout broken|render error',
  'test-generator': 'test|coverage|mock|fixture',
  'collect-coverage': 'coverage|lcov|jacoco|cobertura|branches',
  'run-static-analysis': 'analyze|lint|typecheck|warnings',
  'nullable-types': 'null|optional|nil|guard clause|defensive',
  'architecture-audit': 'architecture|boundary|coupling|cycle',
  'conformance-audit': 'conformance|doctor|parity|frontmatter',
  'code-review': 'review|pr|checklist|pre-pr',
};

const META_SKILLS = ['ponytail', 'collect-coverage', 'run-static-analysis', 'conformance-audit'];

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

const TERRITORY_VOCABULARY = ['features', 'screens', 'pages', 'components', 'shared', 'ui', 'core', 'domain', 'data', 'infra', 'test', 'tests'];

const MIRROR_DIRS = ['.claude/skills', '.cursor/rules', '.windsurf/skills', '.cline/skills', '.grok/agents'];

const AGENTS_FILE = 'AGENTS.md';
const LLMS_FILE = 'llms.txt';
const CONTEXT_FILE = 'oaef.context.json';
const BASELINE_FILE = 'docs/wiki/metrics/baseline.json';
const ADOPTION_LEDGER = 'docs/wiki/metrics/adoption.json';

const CRYPTIC = ['cb', 'fn', 'res', 'req', 'btn', 'val', 'tmp', 'ctx', 'el', 'usr', 'mgr', 'idx', 'cnt', 'buf', 'str', 'num', 'doc', 'elem', 'curr', 'prev'];

const skillDir = (skill) => `.agents/skills/${skill}`;

// ------------------------------------------------------------------------------
// Profile & adoption resolution
// ------------------------------------------------------------------------------
let PROFILE = 'strict';
let ADOPTION_MODE = 'install';
let FORCE_STANDARD = false;

function readJson(file) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    return null;
  }
}

function resolveProfile() {
  const context = readJson(CONTEXT_FILE) || {};
  const baseline = readJson(BASELINE_FILE) || {};
  PROFILE = context.strictness || baseline.profile || 'strict';
  ADOPTION_MODE = context.adoption_mode || 'install';
  if (FORCE_STANDARD) PROFILE = 'standard';
}

const isAdoption = () => ADOPTION_MODE !== 'install';

const profileLabel = () => (isAdoption() ? ADOPTION_MODE : PROFILE);

function userOwnedSkill(skill) {
  const ledger = readJson(ADOPTION_LEDGER);
  if (!ledger || !Array.isArray(ledger.user_skills)) return false;
  return ledger.user_skills.includes(skill);
}

function ccBlocking(id) {
  if (id === 'CC-04') return true;
  if (isAdoption()) return false;
  return PROFILE === 'strict';
}

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

function ccThreshold(id) {
  const key = THRESHOLD_KEYS[id];
  if (!key) return 0;
  const baseline = readJson(BASELINE_FILE);
  const value = baseline && baseline.baseline && baseline.baseline.clean_code
    ? baseline.baseline.clean_code[key]
    : undefined;
  return typeof value === 'number' ? value : 0;
}

// ------------------------------------------------------------------------------
// File discovery (production scope: src/ ; tests: **/*.spec.*, test/)
// ------------------------------------------------------------------------------
const EXCLUDED_SEGMENTS = new Set([
  '.git', '.github', '.agents', '.claude', '.cursor', '.windsurf', '.cline', '.grok', '.oaef',
  'node_modules', 'vendor', 'build', 'dist', 'target', 'obj', 'bin', 'tool', 'docs', 'templates',
  'examples', 'coverage', 'generated', '.venv', 'venv', '__pycache__', '.dart_tool', '.gradle', '.idea',
]);
const TEST_SEGMENTS = new Set(['test', 'tests', '__tests__', 'spec', 'specs', 'androidTest', 'iosTest']);
const SOURCE_EXTENSIONS = new Set(['.ts', '.tsx', '.js', '.mjs', '.cjs', '.jsx']);
const GENERATED_FILE = /\.(g|generated|freezed|designer)\.[^./]+$|_pb2(_grpc)?\.py$|\.min\.js$/;

const segments = (rel) => rel.split('/');

function isSourceBasename(name) {
  if (GENERATED_FILE.test(name)) return false;
  return SOURCE_EXTENSIONS.has(path.extname(name));
}

function isExcludedPath(rel) {
  return segments(rel).some((segment) => EXCLUDED_SEGMENTS.has(segment));
}

function isTestPath(rel) {
  if (segments(rel).some((segment) => TEST_SEGMENTS.has(segment))) return true;
  const base = path.basename(rel);
  return /_test\.[^./]+$|\.spec\.[^./]+$|\.test\.[^./]+$|^test_.*\.py$|Tests\.cs$|Test\.kt$/.test(base);
}

function walk(dir, out) {
  if (!fs.existsSync(dir)) return out;
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  entries.sort((left, right) => (left.name < right.name ? -1 : left.name > right.name ? 1 : 0));
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    const rel = full.split(path.sep).join('/');
    if (EXCLUDED_SEGMENTS.has(entry.name)) continue;
    let isDirectory = entry.isDirectory();
    if (entry.isSymbolicLink()) {
      try {
        isDirectory = fs.statSync(full).isDirectory();
      } catch {
        continue;
      }
    }
    if (isDirectory) {
      walk(full, out);
      continue;
    }
    if (isExcludedPath(rel)) continue;
    if (!isSourceBasename(entry.name)) continue;
    out.push(rel);
  }
  return out;
}

const PRODUCTION_ROOTS = ['src'];
const TEST_ROOTS = ['test'];

function productionFiles() {
  return walk(PRODUCTION_ROOTS[0], []).filter((rel) => !isTestPath(rel));
}

function productionAndTestFiles() {
  const files = walk(PRODUCTION_ROOTS[0], []).concat(walk(TEST_ROOTS[0], []));
  return [...new Set(files)].sort();
}

function cc11Files() {
  return productionAndTestFiles();
}

// ------------------------------------------------------------------------------
// Finding emission
// ------------------------------------------------------------------------------
const ccCounts = new Map();
let ccTotal = 0;
let skFailures = 0;

function emit(id, file, line, message) {
  process.stdout.write(`${id} ${file}:${line} — ${message}\n`);
  ccCounts.set(id, (ccCounts.get(id) || 0) + 1);
  ccTotal += 1;
}

function emitSkill(id, file, line, message) {
  process.stdout.write(`${id} ${file}:${line} — ${message}\n`);
  skFailures += 1;
}

const ccCount = (id) => ccCounts.get(id) || 0;

function readLines(rel) {
  try {
    return fs.readFileSync(rel, 'utf8').split('\n');
  } catch {
    return null;
  }
}

const isCommentLine = (line) => /^\s*(\/\/|\/\*|\*)/.test(line);

function stripLineComment(line) {
  let quote = null;
  for (let index = 0; index < line.length; index += 1) {
    const char = line[index];
    if (quote) {
      if (char === '\\') index += 1;
      else if (char === quote) quote = null;
      continue;
    }
    if (char === '"' || char === "'" || char === '`') {
      quote = char;
      continue;
    }
    if (char === '/' && line[index + 1] === '/') return line.slice(0, index);
  }
  return line;
}

// ------------------------------------------------------------------------------
// CC-01 / CC-02 : identifier discipline
// ------------------------------------------------------------------------------
function bindingSites(line) {
  const sites = [];
  const declaration = /\b(?:const|let|var)\s+([A-Za-z_$][A-Za-z0-9_$]*)/g;
  const parenthesized = /\(([^()]*)\)\s*=>/g;
  const bare = /(?:^|[^\w$.])(?:\.\.\.)?([A-Za-z_$][A-Za-z0-9_$]*)\s*=>/g;
  const caught = /catch\s*\(\s*([A-Za-z_$][A-Za-z0-9_$]*)/g;
  let match;
  while ((match = declaration.exec(line))) sites.push(match[1]);
  while ((match = parenthesized.exec(line))) {
    for (const part of match[1].split(',')) {
      const param = /^\s*(?:\.\.\.)?([A-Za-z_$][A-Za-z0-9_$]*)/.exec(part);
      if (param) sites.push(param[1]);
    }
  }
  while ((match = bare.exec(line))) sites.push(match[1]);
  while ((match = caught.exec(line))) sites.push(match[1]);
  return sites;
}

function checkIdentifierDiscipline(file, lines) {
  lines.forEach((rawLine, index) => {
    if (!rawLine.trim()) return;
    if (isCommentLine(rawLine)) return;
    const line = stripLineComment(rawLine);
    const seen = new Set();
    for (const name of bindingSites(line)) {
      if (seen.has(name)) continue;
      seen.add(name);
      if (name.length === 1) {
        if (name === '_') continue;
        if ((name === 'i' || name === 'j') && /\bfor\b/.test(line)) continue;
        emit('CC-01', file, index + 1, `prohibited single-letter identifier "${name}"; use a descriptive name`);
      } else if (CRYPTIC.includes(name.toLowerCase())) {
        emit('CC-02', file, index + 1, `prohibited cryptic abbreviation "${name}"; use the full identifier`);
      }
    }
  });
}

// ------------------------------------------------------------------------------
// CC-03 : mutable lazy initialization
// ------------------------------------------------------------------------------
function checkLazyInit(file, lines) {
  lines.forEach((rawLine, index) => {
    if (!rawLine.includes('??=')) return;
    if (!/(client|instance|service|provider)/i.test(rawLine)) return;
    emit('CC-03', file, index + 1, 'prohibited mutable lazy initialization; inject the dependency via constructor');
  });
}

// ------------------------------------------------------------------------------
// CC-04 : hardcoded placeholder / secret (blocking under every profile)
// ------------------------------------------------------------------------------
function checkSecrets(file, lines) {
  lines.forEach((rawLine, index) => {
    const line = stripLineComment(rawLine);
    let hit = /\bdummy_|\bchangeme\b|\bTODO_KEY\b/.test(line);
    if (!hit) {
      const assignment = /\b(?:api[_-]?key|secret|password|token)\s*[:=]\s*(["'`])([^"'`]*)\1/gi;
      let match;
      while ((match = assignment.exec(line))) {
        const value = match[2];
        if (value.includes('{') || value.includes('$') || /\benv\b|process\.env|import\.meta/.test(value)) continue;
        hit = true;
      }
    }
    if (!hit) return;
    emit('CC-04', file, index + 1, 'prohibited hardcoded placeholder/secret; source it from configuration/environment');
  });
}

// ------------------------------------------------------------------------------
// CC-05 : raw print / debug output
// ------------------------------------------------------------------------------
function checkRawPrints(file, lines) {
  lines.forEach((rawLine, index) => {
    if (index === 0 && rawLine.startsWith('#!')) return;
    const line = stripLineComment(rawLine);
    if (!/\bconsole\.(log|debug|warn)\s*\(/.test(line)) return;
    emit('CC-05', file, index + 1, 'prohibited raw print/debug output in production code; use the logging interface');
  });
}

// ------------------------------------------------------------------------------
// CC-06 : silent exception swallowing
// ------------------------------------------------------------------------------
const CATCH_OPEN = /catch\s*(\([^)]*\))?\s*\{\s*$/;
const CATCH_EMPTY_INLINE = /catch\s*(\([^)]*\))?\s*\{\s*\}\s*;?\s*$/;
const CATCH_PROMISE_EMPTY = /\.catch\s*\(\s*(?:\([^)]*\)|[A-Za-z_$][A-Za-z0-9_$]*)\s*=>\s*\{\s*\}\s*\)|\.catch\s*\(\s*function\s*\([^)]*\)\s*\{\s*\}\s*\)/;

function checkSilentCatches(file, lines) {
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (CATCH_EMPTY_INLINE.test(line) || CATCH_PROMISE_EMPTY.test(line)) {
      emit('CC-06', file, index + 1, 'prohibited silent exception swallowing; log with error+stack trace or rethrow');
      continue;
    }
    if (!CATCH_OPEN.test(line)) continue;
    let emptied = true;
    for (let lookahead = 1; lookahead <= 3; lookahead += 1) {
      const upcoming = lines[index + lookahead];
      if (upcoming === undefined) break;
      if (!upcoming.trim()) continue;
      if (isCommentLine(upcoming)) continue;
      if (/^\s*\}/.test(upcoming)) break;
      emptied = false;
      break;
    }
    if (emptied) emit('CC-06', file, index + 1, 'prohibited silent exception swallowing; log with error+stack trace or rethrow');
  }
}

// ------------------------------------------------------------------------------
// CC-07 : service-locator confinement
// ------------------------------------------------------------------------------
const BANNED_DI_SEGMENTS = new Set(['domain', 'data', 'services', 'repositories']);
const DI_TOKENS = /\bcontainer\.get\s*\(|\bContainer\.get\s*\(|\bcontainer\.resolve\s*\(|\bgetService\s*\(/;

function checkServiceLocator(file, lines) {
  if (!segments(file).some((segment) => BANNED_DI_SEGMENTS.has(segment))) return;
  lines.forEach((rawLine, index) => {
    const line = stripLineComment(rawLine);
    if (!DI_TOKENS.test(line)) return;
    emit('CC-07', file, index + 1, 'prohibited service-locator resolution outside the composition root/presentation layer; inject via constructor');
  });
}

// ------------------------------------------------------------------------------
// CC-08 : nullable collection parameter
// ------------------------------------------------------------------------------
function nullableCollectionParams(line) {
  const hits = [];
  const groups = /\(([^()]*)\)/g;
  let match;
  while ((match = groups.exec(line))) {
    for (const raw of match[1].split(',')) {
      const param = raw.trim();
      if (!param) continue;
      const parsed = /^(?:(?:public|private|protected|readonly|static)\s+)*([A-Za-z_$][A-Za-z0-9_$]*)(\?)?\s*:\s*(.+)$/.exec(param);
      if (!parsed) continue;
      const optional = parsed[2] === '?';
      const type = parsed[3].trim();
      const collection = /^(?:ReadonlyArray|Array|Map|Set)\b/.test(type) || /\[\]/.test(type);
      if (!collection) continue;
      if (optional || /\|\s*undefined\b/.test(type)) hits.push(parsed[1]);
    }
  }
  return hits;
}

function checkNullableCollections(file, lines) {
  lines.forEach((rawLine, index) => {
    const line = stripLineComment(rawLine);
    for (const name of nullableCollectionParams(line)) {
      emit('CC-08', file, index + 1, 'prohibited nullable collection parameter; default to a constant empty collection');
    }
  });
}

// ------------------------------------------------------------------------------
// CC-09 : unimplemented placeholder
// ------------------------------------------------------------------------------
const UNIMPLEMENTED = /throw\s+new\s+Error\s*\(\s*["'`]Not implemented/;

function checkUnimplemented(file, lines) {
  lines.forEach((rawLine, index) => {
    const line = stripLineComment(rawLine);
    if (!UNIMPLEMENTED.test(line)) return;
    emit('CC-09', file, index + 1, 'prohibited unimplemented placeholder in production contract; implement the contract (LSP)');
  });
}

// ------------------------------------------------------------------------------
// CC-10 : concrete network-client instantiation (DIP)
// ------------------------------------------------------------------------------
const NETWORK_CLIENTS = /axios\.create\s*\(|new\s+XMLHttpRequest\s*\(|new\s+HttpClient\s*\(/;

function isCompositionRoot(file) {
  const base = path.basename(file);
  return /(^|\/)di\//.test(file)
    || /^main\.[cm]?[jt]sx?$/.test(base)
    || /composition_root/.test(base);
}

function checkConcreteClients(file, lines) {
  if (isCompositionRoot(file)) return;
  lines.forEach((rawLine, index) => {
    const line = stripLineComment(rawLine);
    if (!NETWORK_CLIENTS.test(line)) return;
    emit('CC-10', file, index + 1, 'prohibited concrete network-client instantiation outside the composition root; depend on an abstraction (DIP)');
  });
}

// ------------------------------------------------------------------------------
// CC-11 : avoidable allocation on a hot path (advisory, also scans test files)
// ------------------------------------------------------------------------------
const HOT_RENDER_SEGMENTS = new Set(['components', 'ui', 'screens', 'views', 'presentation']);
const ALLOCATION_TOKENS = /\[\s*\.\.\.|\.(?:map|filter)\s*\(/;

function loopLineFlags(lines) {
  const inside = new Array(lines.length).fill(false);
  const stack = [];
  const opener = /(^|[^\w.$])(?:for|while)\s*\(|\.forEach\s*\(|(^|[^\w.$])do\s*\{/;
  let depth = 0;
  for (let index = 0; index < lines.length; index += 1) {
    const line = stripLineComment(lines[index]);
    const opens = opener.test(line);
    inside[index] = stack.length > 0 || opens;
    let delta = 0;
    for (const char of line) {
      if (char === '{') delta += 1;
      else if (char === '}') delta -= 1;
    }
    const before = depth;
    depth += delta;
    if (opens && depth > before) stack.push(depth);
    while (stack.length && depth < stack[stack.length - 1]) stack.pop();
  }
  return inside;
}

function checkAvoidableAllocation(file, lines) {
  const inLoop = loopLineFlags(lines);
  const hotRenderPath = segments(file).some((segment) => HOT_RENDER_SEGMENTS.has(segment));
  lines.forEach((rawLine, index) => {
    const line = stripLineComment(rawLine);
    if (!ALLOCATION_TOKENS.test(line)) return;
    if (!inLoop[index] && !hotRenderPath) return;
    emit('CC-11', file, index + 1, '[advisory] avoidable allocation on hot path; inspect without copying and return the original reference');
  });
}

// ------------------------------------------------------------------------------
// clean-code suite
// ------------------------------------------------------------------------------
function scanProductionFile(file) {
  const lines = readLines(file);
  if (!lines) return;
  checkIdentifierDiscipline(file, lines);
  checkLazyInit(file, lines);
  checkSecrets(file, lines);
  checkRawPrints(file, lines);
  checkSilentCatches(file, lines);
  checkServiceLocator(file, lines);
  checkNullableCollections(file, lines);
  checkUnimplemented(file, lines);
  checkConcreteClients(file, lines);
  checkAvoidableAllocation(file, lines);
}

function runCleanCodeReport() {
  for (const file of productionFiles()) scanProductionFile(file);
  for (const file of cc11Files()) {
    if (!isTestPath(file)) continue;
    const lines = readLines(file);
    if (lines) checkAvoidableAllocation(file, lines);
  }
}

function blockingTotal() {
  let total = 0;
  for (const id of Object.keys(THRESHOLD_KEYS)) {
    const count = ccCount(id);
    if (count <= 0) continue;
    if (ccBlocking(id) && count > ccThreshold(id)) total += count;
  }
  return total;
}

function runCleanCode() {
  resolveProfile();
  runCleanCodeReport();
  const behavior = ccBlocking('CC-01') ? 'blocking' : 'advisory';
  process.stdout.write(`Clean Code: ${ccTotal} violation(s) (${profileLabel()} profile: ${behavior})\n`);
  if (blockingTotal() > 0) process.exit(1);
}

// ------------------------------------------------------------------------------
// PT-01 : ponytail debt markers
// ------------------------------------------------------------------------------
const DEBT_MARKER = /(^|[^A-Za-z])(?:\/\/|#|--|\/\*|\/\/\/|<!--)[^\n]*ponytail:/;

function scanDebtMarkers() {
  for (const file of productionAndTestFiles()) {
    const lines = readLines(file);
    if (!lines) continue;
    lines.forEach((line, index) => {
      if (!DEBT_MARKER.test(line)) return;
      const reason = line.slice(line.indexOf('ponytail:') + 'ponytail:'.length).trim();
      process.stdout.write(`PT-01 ${file}:${index + 1} — ${reason}\n`);
    });
  }
}

function runPonytailDebt() {
  scanDebtMarkers();
}

const NARRATION_COMMENT = /^\s*(?:\/\/|#)\s*(?:increment|decrement|set|assign|call|return|loop|iterate|initialize|create|check|store)\s/;
const SINGLE_STATEMENT_DELEGATION = /=>\s*[A-Za-z_][A-Za-z0-9_.]*\([^)]*\);?\s*$|^\s*\{\s*return\s+[A-Za-z_][A-Za-z0-9_.]*\([^)]*\);\s*\}\s*$/;

function runPonytailAudit() {
  scanDebtMarkers();
  for (const file of productionFiles()) {
    const lines = readLines(file);
    if (!lines) continue;
    lines.forEach((line, index) => {
      if (NARRATION_COMMENT.test(line)) {
        process.stdout.write(`[advisory] [DELETE] ${file}:${index + 1} — narration comment restates the next line\n`);
      }
      if (SINGLE_STATEMENT_DELEGATION.test(line)) {
        process.stdout.write(`[advisory] [SHRINK] ${file}:${index + 1} — single-statement delegation; verify a caller justifies the layer\n`);
      }
    });
  }
}

// ------------------------------------------------------------------------------
// SK-01 .. SK-06 : skill activation invariants
// ------------------------------------------------------------------------------
const ALLOWED_FRONTMATTER_KEYS = new Set(['name', 'description', 'argument-hint', 'license', 'metadata']);
const SK02_MESSAGE = (skill) => `skill "${skill}" frontmatter must declare "Use when", "Triggers on:" and "Chains into:" with >=150 characters and name==directory`;

function readFrontmatter(skill) {
  const file = `${skillDir(skill)}/SKILL.md`;
  if (!fs.existsSync(file)) return null;
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  const keys = [];
  const values = new Map();
  if (lines[0].trim() !== '---') return { keys, values };
  let current = null;
  for (let index = 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (line.trim() === '---') break;
    const entry = /^([A-Za-z][A-Za-z0-9_-]*):(.*)$/.exec(line);
    if (entry) {
      current = entry[1];
      keys.push(current);
      const rest = entry[2].trim();
      values.set(current, /^[>|][-+]?$/.test(rest) ? '' : rest);
      continue;
    }
    if (current && /^\s+\S/.test(line)) {
      const previous = values.get(current) || '';
      values.set(current, previous ? `${previous} ${line.trim()}` : line.trim());
    }
  }
  return { keys, values };
}

function frontmatterValue(skill, key) {
  const frontmatter = readFrontmatter(skill);
  if (!frontmatter) return '';
  return frontmatter.values.get(key) || '';
}

function auditSkillsParity() {
  for (const skill of SKILLS) {
    const file = `${skillDir(skill)}/SKILL.md`;
    if (!fs.existsSync(file)) {
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
  for (const skill of SKILLS) {
    const file = `${skillDir(skill)}/SKILL.md`;
    if (!fs.existsSync(file)) continue;
    if (isAdoption() && userOwnedSkill(skill)) continue;
    const frontmatter = readFrontmatter(skill);
    const description = frontmatterValue(skill, 'description');
    const coherent = description
      && description.includes('Use when')
      && description.includes('Triggers on:')
      && description.includes('Chains into:')
      && description.length >= 150;
    if (!coherent) {
      emitSkill('SK-02', file, 0, SK02_MESSAGE(skill));
      continue;
    }
    if (frontmatterValue(skill, 'name') !== skill) {
      emitSkill('SK-02', file, 0, SK02_MESSAGE(skill));
      continue;
    }
    if (frontmatter.keys.some((key) => !ALLOWED_FRONTMATTER_KEYS.has(key))) {
      emitSkill('SK-02', file, 0, SK02_MESSAGE(skill));
      continue;
    }
    const body = fs.readFileSync(file, 'utf8');
    if (!/^## Territory\s*$/m.test(body)) emitSkill('SK-02', file, 0, SK02_MESSAGE(skill));
  }
}

function auditEntrypointParity() {
  const llms = fs.existsSync(LLMS_FILE) ? fs.readFileSync(LLMS_FILE, 'utf8') : null;
  if (llms !== null) {
    for (const skill of SKILLS) {
      if (!llms.includes(skill)) emitSkill('SK-03', LLMS_FILE, 0, `skill "${skill}" is not listed in llms.txt`);
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
  const lines = fs.readFileSync(AGENTS_FILE, 'utf8').split('\n');
  const rows = [];
  let inside = false;
  for (const line of lines) {
    if (/^### 3\.3/.test(line)) {
      inside = true;
      continue;
    }
    if (inside && /^#/.test(line)) inside = false;
    if (!inside || !line.startsWith('|')) continue;
    const cells = line.split('|');
    if (cells.length < 7) continue;
    const triggers = cells[3];
    const primary = cells[4].replace(/[`\s]/g, '');
    if (!primary || primary === 'PrimarySkill') continue;
    rows.push({ skill: primary, triggers });
  }
  return rows;
}

function triggerKeywords(cell) {
  const quoted = [...cell.matchAll(/"([^"]+)"/g)].map((match) => match[1]);
  if (quoted.length) return quoted;
  return cell.split(',').map((part) => part.replace(/["'`\s]/g, '')).filter(Boolean);
}

function auditTriggerCoherence() {
  const rows = matrixRows();
  for (const skill of SKILLS) {
    const row = rows.find((candidate) => candidate.skill === skill);
    if (!row) {
      emitSkill('SK-04', AGENTS_FILE, 0, `skill "${skill}" has no dispatch-matrix row`);
      continue;
    }
    if (isAdoption() && userOwnedSkill(skill)) continue;
    const description = frontmatterValue(skill, 'description').toLowerCase();
    for (const keyword of triggerKeywords(row.triggers)) {
      const needle = keyword.toLowerCase();
      if (!needle) continue;
      if (!description.includes(needle)) {
        emitSkill('SK-04', AGENTS_FILE, 0, `trigger "${needle}" for skill "${skill}" is missing from its frontmatter "Triggers on:"`);
      }
    }
  }
}

function mirrorPresent(dir) {
  try {
    fs.lstatSync(dir);
    return true;
  } catch {
    return false;
  }
}

function mirrorOf(dir, skill) {
  if (!mirrorPresent(dir)) return null;
  if (fs.existsSync(`${dir}/${skill}/SKILL.md`)) return `${dir}/${skill}/SKILL.md`;
  if (fs.existsSync(`${dir}/${skill}.md`)) return `${dir}/${skill}.md`;
  if (fs.existsSync(`${dir}/${skill}.mdc`)) return `${dir}/${skill}.mdc`;
  return null;
}

function auditMirrorParity() {
  for (const dir of MIRROR_DIRS) {
    if (!mirrorPresent(dir)) continue;
    for (const skill of SKILLS) {
      const canonical = `${skillDir(skill)}/SKILL.md`;
      if (!fs.existsSync(canonical)) continue;
      const mirror = mirrorOf(dir, skill);
      const diverges = !mirror || !fs.readFileSync(canonical).equals(fs.readFileSync(mirror));
      if (diverges) {
        emitSkill('SK-05', dir, 0, `harness mirror "${dir}" diverges from .agents/skills for skill "${skill}" (run: oaef skills sync-mirrors)`);
      }
    }
  }
}

// ------------------------------------------------------------------------------
// Routing (docs/standards/governance_checks.md section 7.1)
// ------------------------------------------------------------------------------
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
  const normalized = prompt.toLowerCase();
  const tokens = normalized.split(/[^a-z0-9-]+/).filter(Boolean);
  let best = 'ponytail';
  let bestScore = 0;
  for (const skill of SKILLS) {
    let score = 0;
    for (const nameWord of skill.split('-')) {
      if (tokens.some((token) => wordMatch(token, nameWord))) score += 5;
    }
    for (const trigger of (SKILL_TRIGGERS[skill] || '').split('|')) {
      if (!trigger) continue;
      const weight = Math.min(trigger.length, 8);
      if (trigger.includes(' ')) {
        if (normalized.includes(trigger)) score += 3 + weight;
      } else if (tokens.some((token) => wordMatch(token, trigger))) {
        score += 3 + weight;
      }
    }
    for (const token of tokens) {
      if (TERRITORY_VOCABULARY.includes(token)) score += 1;
    }
    if (score > bestScore) {
      bestScore = score;
      best = skill;
    }
  }
  return bestScore === 0 ? 'ponytail' : best;
}

function recipesContaining(skill) {
  return RECIPES.filter((recipe) => recipe.includes(skill));
}

function runSkillsRoute(query) {
  const primary = routePrompt(query);
  process.stdout.write(`Routing: "${query}"\n`);
  process.stdout.write(`Primary skill: ${primary} ${skillDir(primary)}/SKILL.md\n`);
  process.stdout.write(`Meta-skill: ${META_SKILLS.includes(primary) ? '—' : 'ponytail'}\n`);
  process.stdout.write(`Recipes containing ${primary}:\n`);
  for (const recipe of recipesContaining(primary)) process.stdout.write(`  ${recipe}\n`);
}

function runSkillsSelftest() {
  for (const [prompt, expected] of ROUTING_FIXTURES) {
    const got = routePrompt(prompt);
    if (got !== expected) {
      emitSkill('SK-06', AGENTS_FILE, 0, `routing self-test failed: prompt "${prompt}" resolved to "${got}" but expected "${expected}"`);
    }
  }
}

function runSkillsAudit(selftest) {
  resolveProfile();
  auditSkillsParity();
  auditSkillsFrontmatter();
  auditEntrypointParity();
  auditTriggerCoherence();
  auditMirrorParity();
  if (selftest) runSkillsSelftest();
  process.stdout.write(`Skills: ${skFailures} finding(s)\n`);
  if (skFailures > 0) process.exit(1);
}

function runSkillsSyncMirrors(checkOnly) {
  resolveProfile();
  let repaired = 0;
  for (const dir of MIRROR_DIRS) {
    if (!mirrorPresent(dir)) continue;
    const stats = fs.lstatSync(dir);
    if (stats.isSymbolicLink() && fs.readlinkSync(dir) === '../.agents/skills') {
      process.stdout.write(`✅ ${dir} is a symlink to .agents/skills (parity by construction)\n`);
      continue;
    }
    let isDirectory = false;
    try {
      isDirectory = fs.statSync(dir).isDirectory();
    } catch {
      isDirectory = false;
    }
    if (!isDirectory) continue;
    for (const skill of SKILLS) {
      const canonical = `${skillDir(skill)}/SKILL.md`;
      if (!fs.existsSync(canonical)) continue;
      const entry = mirrorOf(dir, skill);
      if (entry) {
        if (!checkOnly && !fs.readFileSync(canonical).equals(fs.readFileSync(entry))) {
          fs.copyFileSync(canonical, entry);
          process.stdout.write(`🔧 ${dir}: repaired mirror for ${skill} (canonical catalog is authoritative)\n`);
          repaired += 1;
        }
        continue;
      }
      if (checkOnly) continue;
      const target = `${dir}/${skill}`;
      try {
        fs.symlinkSync(path.relative(dir, `${skillDir(skill)}`).split(path.sep).join('/'), target);
        process.stdout.write(`🔧 ${dir}: created mirror link for ${skill}\n`);
      } catch {
        fs.rmSync(target, { recursive: true, force: true });
        fs.cpSync(skillDir(skill), target, { recursive: true });
        process.stdout.write(`🔧 ${dir}: created mirror copy for ${skill}\n`);
      }
      repaired += 1;
    }
  }
  skFailures = 0;
  auditMirrorParity();
  if (skFailures > 0) {
    if (checkOnly) {
      process.stdout.write(`Mirrors: ${skFailures} divergence(s) detected\n`);
    } else {
      process.stdout.write(`Mirrors: ${skFailures} divergence(s) remain (user-owned entries are preserved)\n`);
    }
    process.exit(1);
  }
  if (checkOnly) {
    process.stdout.write('Mirrors: parity verified\n');
    return;
  }
  process.stdout.write(`Mirrors: ${repaired} entry(ies) synchronized, parity verified\n`);
}

// ------------------------------------------------------------------------------
// lint / doctor / quality gate / sync / metrics
// ------------------------------------------------------------------------------
function normalizeMirror(file) {
  return fs.readFileSync(file, 'utf8').split('\n')
    .filter((line) => !line.startsWith('<!--'))
    .join('')
    .replace(/\s+/g, '');
}

const SUPPRESSION_PATTERNS = [
  /\/\*\s*eslint-disable/,
  /\/\/\s*eslint-disable/,
  /\/\/\s*@ts-ignore/,
  /\/\/\s*@ts-nocheck/,
  /\/\/\s*biome-ignore/,
  /\/\/\s*nolint/,
];

function scanSecretPatterns(dir, patterns, onHit) {
  if (!fs.existsSync(dir)) return;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (EXCLUDED_SEGMENTS.has(entry.name) && entry.name !== 'docs') continue;
      scanSecretPatterns(full, patterns, onHit);
      continue;
    }
    if (!entry.isFile() || !entry.name.endsWith('.md')) continue;
    const text = fs.readFileSync(full, 'utf8');
    for (const pattern of patterns) {
      if (pattern.test(text)) onHit(full);
    }
  }
}

function scanSuppressions(files, onHit) {
  for (const file of files) {
    const lines = readLines(file);
    if (!lines) continue;
    if (/@generated|DO NOT EDIT/.test(lines.slice(0, 5).join('\n'))) continue;
    lines.forEach((line, index) => {
      for (const pattern of SUPPRESSION_PATTERNS) {
        if (!pattern.test(line)) continue;
        if (line.includes('@typescript-eslint/no-deprecated') || line.includes('type: lint')) return;
        onHit(`${file}:${index + 1}: ${line.trim()}`);
        return;
      }
    });
  }
}

function runLint() {
  resolveProfile();
  let failed = false;

  if (fs.existsSync('AGENTS.md') && fs.existsSync('CLAUDE.md')) {
    if (normalizeMirror('AGENTS.md') !== normalizeMirror('CLAUDE.md')) {
      process.stderr.write('❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run "oaef sync".\n');
      failed = true;
    }
  }

  scanSecretPatterns('docs', [
    /sk-[a-zA-Z0-9]{20,}/,
    /ghp_[a-zA-Z0-9]{20,}/,
    /AKIA[0-9A-Z]{16}/,
    /-----BEGIN [A-Z ]*PRIVATE KEY-----/,
  ], (file) => {
    process.stderr.write(`🚨 [SECURITY] Potential secret detected in ${file}!\n`);
    failed = true;
  });

  const suppressions = [];
  scanSuppressions(productionFiles(), (hit) => suppressions.push(hit));
  if (suppressions.length) {
    process.stderr.write('🚨 [LINT] Unallowed linter/compiler suppression comments detected:\n');
    for (const hit of suppressions) process.stderr.write(`${hit}\n`);
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
    process.stderr.write('❌ LINT FAILED.\n');
    process.exit(1);
  }
  process.stdout.write('✅ [LINT] All integrity and secret audits passed cleanly.\n');
}

const REQUIRED_FILES = [
  'AGENTS.md', 'CLAUDE.md', 'llms.txt', 'oaef.context.json',
  'docs/INDEX.md', 'docs/MANIFESTO.md', 'docs/DESIGN.md', 'docs/HARNESSES.md',
  'docs/standards/coding_patterns.md', 'docs/standards/testing.md', 'docs/standards/logging.md',
  'docs/standards/clean_code.md', 'docs/standards/solid.md', 'docs/standards/review.md',
  'docs/standards/analytics_and_telemetry.md', 'docs/standards/governance_checks.md',
  'docs/wiki/metrics/baseline.json', 'docs/wiki/memory/handoff.md', 'docs/wiki/log.md',
  '.github/workflows/ci.yml', '.github/pull_request_template.md',
  '.gitignore', 'CONTRIBUTING.md', 'SECURITY.md',
];

const PLACEHOLDER_PATTERN = /\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}/;

function runConform() {
  resolveProfile();
  let checks = 0;
  let passed = 0;
  let failed = false;
  process.stdout.write('🩺 OAEF Conformance Audit (doctor)...\n');

  const check = (condition, label) => {
    checks += 1;
    if (condition) {
      passed += 1;
      process.stdout.write(`✅ ${label}\n`);
    } else {
      process.stderr.write(`❌ ${label}\n`);
      failed = true;
    }
  };

  for (const entry of REQUIRED_FILES) check(fs.existsSync(entry), `${entry} present`);
  for (const skill of SKILLS) check(fs.existsSync(`${skillDir(skill)}/SKILL.md`), `.agents/skills/${skill}/SKILL.md present`);
  check(fs.existsSync('tool/governance.mjs'), 'governance runtime present in tool/');

  const mirrorParity = fs.existsSync('AGENTS.md') && fs.existsSync('CLAUDE.md')
    && normalizeMirror('AGENTS.md') === normalizeMirror('CLAUDE.md');
  check(mirrorParity, 'CLAUDE.md mirror parity verified');

  const targets = [AGENTS_FILE, LLMS_FILE].filter((file) => fs.existsSync(file));
  const unresolved = targets.some((file) => PLACEHOLDER_PATTERN.test(fs.readFileSync(file, 'utf8')));
  check(!unresolved, 'no unresolved template placeholders');

  runSkillsSelftest();
  if (skFailures === 0) check(true, 'routing self-test (SK-06) passed');
  else check(false, 'routing self-test (SK-06) failed');

  process.stdout.write(`\n📊 Conformance: ${passed}/${checks} checks passed\n`);
  if (failed) process.exit(1);
}

function runQualityGate(record) {
  resolveProfile();
  process.stdout.write('\n🔍 Initiating OAEF Quality Gate Audit (Node.js/TS)...\n');
  const baselineDocument = readJson(BASELINE_FILE) || { baseline: {} };
  const baseline = baselineDocument.baseline || {};
  const minLine = baseline.coverage?.lines_min_percentage ?? 95.0;
  const maxFileLines = baseline.clean_sizing?.file_max_lines ?? 300;

  if (fs.existsSync('package.json')) {
    process.stdout.write('ℹ️  Running test suite with coverage...\n');
    try {
      execSync('npm test -- --coverage', { stdio: 'inherit' });
    } catch {
      process.stderr.write('❌ Tests failed.\n');
      process.exit(1);
    }
    let linesFound = 0;
    let linesHit = 0;
    const lcovPath = 'coverage/lcov.info';
    if (fs.existsSync(lcovPath)) {
      const lines = fs.readFileSync(lcovPath, 'utf8').split('\n');
      for (const line of lines) {
        if (line.startsWith('LF:')) linesFound += parseInt(line.slice(3), 10) || 0;
        if (line.startsWith('LH:')) linesHit += parseInt(line.slice(3), 10) || 0;
      }
      const linePercent = linesFound === 0 ? 100.0 : (linesHit / linesFound) * 100.0;
      process.stdout.write(`📊 Line Coverage: ${linePercent.toFixed(1)}% (Floor: ${minLine}%)\n`);
      if (linePercent < minLine) {
        process.stderr.write('❌ Quality Gates Failed: coverage floor missed.\n');
        process.exit(1);
      }
      if (record && linePercent > minLine) {
        baseline.coverage.lines_min_percentage = parseFloat(linePercent.toFixed(1));
        baselineDocument.baseline = baseline;
        fs.writeFileSync(BASELINE_FILE, `${JSON.stringify(baselineDocument, null, 2)}\n`);
        process.stdout.write(`🔒 Monotonic Ratchet: Updated baseline floor to ${linePercent.toFixed(1)}%\n`);
      }
    }
  } else {
    process.stdout.write('ℹ️  No Node.js test suite configured (package.json absent); skipping tests and coverage.\n');
  }

  let oversized = 0;
  for (const file of productionFiles()) {
    const lines = readLines(file);
    if (!lines) continue;
    const count = lines.length - (lines[lines.length - 1] === '' ? 1 : 0);
    if (count > maxFileLines) {
      process.stderr.write(`⚠️  Oversized file (${count}L > ${maxFileLines}L): ${file}\n`);
      oversized += 1;
    }
  }
  if (oversized > 0) {
    process.stderr.write(`❌ Quality Gates Failed: ${oversized} oversized files detected.\n`);
    process.exit(1);
  }

  runCleanCodeReport();
  const behavior = ccBlocking('CC-01') ? 'blocking' : 'advisory';
  process.stdout.write(`Clean Code: ${ccTotal} violation(s) (${profileLabel()} profile: ${behavior})\n`);
  const blocking = blockingTotal();
  if (blocking > 0) {
    process.stderr.write(`❌ Quality Gate Failed: ${blocking} clean-code violation(s).\n`);
    process.exit(1);
  }
  process.stdout.write('\n🎉 Quality Gates PASSED!\n');
}

function runSync() {
  if (!fs.existsSync(AGENTS_FILE)) return;
  const content = fs.readFileSync(AGENTS_FILE, 'utf8');
  fs.writeFileSync(
    'CLAUDE.md',
    `<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n<!-- To modify rules, edit AGENTS.md and run "oaef sync". -->\n\n${content}`,
  );
  process.stdout.write('✅ Synchronized AGENTS.md -> CLAUDE.md\n');
}

function runMetrics() {
  if (fs.existsSync(BASELINE_FILE)) process.stdout.write(fs.readFileSync(BASELINE_FILE, 'utf8'));
}

// ------------------------------------------------------------------------------
// Dispatch
// ------------------------------------------------------------------------------
function usage() {
  process.stdout.write(`OAEF Governance Tool (TypeScript & Web Engine)
Usage: node tool/governance.mjs <command>
Commands:
  quality-gate|audit [--record]   Quality Gate audit (tests, coverage, sizing, clean code)
  clean-code [--standard]         Governance barriers (docs/standards/governance_checks.md)
  ponytail-debt                   Report every "// ponytail:" debt marker (PT-01)
  ponytail-audit                  Advisory anti-slop sweep
  ponytail [debt|audit]           Nested aliases for the ponytail reports
  skills-audit [--selftest]       Skill activation invariants (SK-01..SK-06)
  skills-route "<query>"          Resolve a prompt to its governing skill and recipe
  skills sync-mirrors [--check]   Rebuild or validate the harness skill mirrors
  lint                            Mirror parity, secrets, anti-suppression, clean code, skills
  doctor|conform                  Conformance audit
  metrics                         Display baseline thresholds
  sync                            Synchronize AGENTS.md to CLAUDE.md
`);
}

const args = process.argv.slice(2);
const command = args[0] || '';
const rest = args.slice(1);
if (args.includes('--standard')) FORCE_STANDARD = true;

switch (command) {
  case 'quality-gate':
  case 'audit':
    runQualityGate(args.includes('--record') || args.includes('--ratchet'));
    break;
  case 'clean-code':
  case 'governance-check':
    runCleanCode();
    break;
  case 'ponytail-debt':
    runPonytailDebt();
    break;
  case 'ponytail-audit':
    runPonytailAudit();
    break;
  case 'ponytail':
    if (rest[0] === 'debt') runPonytailDebt();
    else runPonytailAudit();
    break;
  case 'skills-audit':
    runSkillsAudit(rest.includes('--selftest'));
    break;
  case 'skills-route':
    runSkillsRoute(rest.join(' '));
    break;
  case 'skills':
    switch (rest[0]) {
      case 'sync-mirrors':
        runSkillsSyncMirrors(rest.includes('--check'));
        break;
      case 'audit':
        runSkillsAudit(rest.includes('--selftest'));
        break;
      case 'route':
        runSkillsRoute(rest.slice(1).join(' '));
        break;
      default:
        usage();
        process.exit(1);
    }
    break;
  case 'lint':
    runLint();
    break;
  case 'conform':
  case 'doctor':
    runConform();
    break;
  case 'metrics':
    runMetrics();
    break;
  case 'sync':
    runSync();
    break;
  default:
    usage();
    process.exit(1);
}
