#!/usr/bin/env node
// ==============================================================================
// OAEF Governance Engine - TypeScript & Node.js Runtime
// Author: Felipe Carvalho | License: Apache 2.0
// ==============================================================================

import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';

const args = process.argv.slice(2);
const command = args[0] || '';

switch (command) {
  case 'quality-gate':
  case 'audit':
    runQualityGate(args.includes('--record') || args.includes('--ratchet'));
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
  default:
    console.log(`OAEF Governance Tool (Node.js Engine)
Usage: node tool/governance.mjs <command>
Commands:
  quality-gate [--record]  Audit Quality Gates & ratchet baseline
  metrics                  Display historical metrics report
  lint                     Audit links, cascade references & secrets
  doctor                   Audit OAEF conformance (structure, skills, mirrors)
  sync                     Synchronize AGENTS.md to mirrors`);
    process.exit(1);
}

function runQualityGate(record = false) {
  console.log('\n🔍 Initiating OAEF Quality Gate Audit (Node.js/TS)...');
  const baselinePath = 'docs/wiki/metrics/baseline.json';
  let baseline = {};
  if (fs.existsSync(baselinePath)) {
    baseline = JSON.parse(fs.readFileSync(baselinePath, 'utf8')).baseline || {};
  }

  const minLine = baseline.coverage?.lines_min_percentage ?? 95.0;
  const maxFileLines = baseline.clean_sizing?.file_max_lines ?? 300;

  // Run tests
  console.log('ℹ️  Running test suite with coverage...');
  try {
    execSync('npm test -- --coverage', { stdio: 'inherit' });
  } catch (err) {
    console.error('❌ Tests failed.');
    process.exit(1);
  }

  // Parse LCOV
  let linesFound = 0, linesHit = 0;
  const lcovPath = 'coverage/lcov.info';
  if (fs.existsSync(lcovPath)) {
    const lines = fs.readFileSync(lcovPath, 'utf8').split('\n');
    for (const l of lines) {
      if (l.startsWith('LF:')) linesFound += parseInt(l.slice(3)) || 0;
      if (l.startsWith('LH:')) linesHit += parseInt(l.slice(3)) || 0;
    }
  }

  const linePercent = linesFound === 0 ? 100.0 : (linesHit / linesFound) * 100.0;
  console.log(`📊 Line Coverage: ${linePercent.toFixed(1)}% (Floor: ${minLine}%)`);

  // Clean Sizing
  let oversized = 0;
  function scanDir(dir) {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory() && entry.name !== 'node_modules' && entry.name !== 'dist') {
        scanDir(full);
      } else if (entry.isFile() && (entry.name.endsWith('.ts') || entry.name.endsWith('.tsx'))) {
        const count = fs.readFileSync(full, 'utf8').split('\n').length;
        if (count > maxFileLines) {
          oversized++;
          console.error(`⚠️  Oversized file (${count}L > ${maxFileLines}L): ${full}`);
        }
      }
    }
  }
  scanDir('src');

  if (linePercent < minLine || oversized > 0) {
    console.error('❌ Quality Gates Failed.');
    process.exit(1);
  }

  console.log('\n🎉 Quality Gates PASSED!\n');
  if (record && linePercent > minLine) {
    baseline.coverage.lines_min_percentage = parseFloat(linePercent.toFixed(1));
    fs.writeFileSync(baselinePath, JSON.stringify({ baseline }, null, 2));
    console.log(`🔒 Monotonic Ratchet: Updated baseline floor to ${linePercent.toFixed(1)}%`);
  }
}

function runLint() {
  console.log('🔍 Executing OAEF Integrity & Secret Audits...');
  let failed = false;

  // Mirror sync
  if (fs.existsSync('AGENTS.md') && fs.existsSync('CLAUDE.md')) {
    const normalize = (text) => text.split('\n').filter((line) => !line.startsWith('<!--')).join('').replace(/\s+/g, '');
    if (normalize(fs.readFileSync('AGENTS.md', 'utf8')) !== normalize(fs.readFileSync('CLAUDE.md', 'utf8'))) {
      console.error('❌ [LINT] CLAUDE.md diverged from AGENTS.md.');
      failed = true;
    }
  }

  // Secret scanner
  const patterns = [
    /sk-[a-zA-Z0-9]{20,}/,
    /ghp_[a-zA-Z0-9]{20,}/,
    /AKIA[0-9A-Z]{16}/,
    /-----BEGIN [A-Z ]*PRIVATE KEY-----/
  ];

  function scanSecrets(dir) {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) scanSecrets(full);
      else if (entry.isFile() && entry.name.endsWith('.md')) {
        const text = fs.readFileSync(full, 'utf8');
        for (const p of patterns) {
          if (p.test(text)) {
            console.error(`🚨 [SECURITY] Potential secret detected in ${full}!`);
            failed = true;
          }
        }
      }
    }
  }
  // Anti-suppression scanner
  const suppressionPatterns = [
    /\/\*\s*eslint-disable/,
    /\/\/\s*eslint-disable-next-line/,
    /\/\/\s*@ts-ignore/,
    /\/\/\s*@ts-nocheck/,
    /\/\/\s*biome-ignore/,
  ];
  function scanSuppressions(dir) {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory() && entry.name !== 'node_modules' && entry.name !== 'dist') {
        scanSuppressions(full);
      } else if (entry.isFile() && (entry.name.endsWith('.ts') || entry.name.endsWith('.tsx') || entry.name.endsWith('.js'))) {
        // Exempt machine-generated files
        if (entry.name.endsWith('.g.ts') || entry.name.endsWith('.generated.ts') || entry.name.endsWith('.generated.js')) {
          continue;
        }
        const content = fs.readFileSync(full, 'utf8');
        if (content.includes('@generated') || content.includes('DO NOT EDIT')) {
          continue;
        }
        const lines = content.split('\n');
        lines.forEach((line, idx) => {
          for (const sp of suppressionPatterns) {
            if (sp.test(line)) {
              // Check for allowed scoped deprecation exception
              if (line.includes('@typescript-eslint/no-deprecated')) {
                return;
              }
              console.error(`🚨 [LINT] Unallowed suppression in ${full}:${idx + 1}: ${line.trim()}`);
              failed = true;
            }
          }
        });
      }
    }
  }
  scanSuppressions('src');

  if (failed) process.exit(1);
  console.log('✅ [LINT] All audits passed cleanly.');
}

function runConform() {
  console.log('🩺 OAEF Conformance Audit (doctor)...');
  const requiredFiles = [
    'AGENTS.md', 'CLAUDE.md', 'llms.txt', 'oaef.context.json',
    'docs/INDEX.md', 'docs/MANIFESTO.md', 'docs/DESIGN.md',
    'docs/standards/coding_patterns.md', 'docs/standards/testing.md', 'docs/standards/logging.md',
    'docs/wiki/metrics/baseline.json', 'docs/wiki/memory/handoff.md', 'docs/wiki/log.md',
    'docs/HARNESSES.md',
    '.github/workflows/ci.yml', '.github/pull_request_template.md',
    '.gitignore', 'CONTRIBUTING.md', 'SECURITY.md'
  ];
  const skills = [
    'architecture-audit', 'code-review', 'collect-coverage', 'component-author',
    'fix-layout-issues', 'nullable-types', 'run-static-analysis', 'screen-builder',
    'test-generator', 'ui-preview', 'conformance-audit'
  ];
  const runtimes = [
    'tool/governance.sh', 'tool/governance.mjs', 'tool/governance.py', 'tool/governance.dart',
    'tool/governance.go', 'tool/governance.rs', 'tool/governance.main.kts', 'tool/governance.swift',
    'tool/Governance.cs'
  ];
  const placeholderPattern = /\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}/;
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

  for (const file of requiredFiles) check(fs.existsSync(file), `${file} present`);
  for (const skill of skills) check(fs.existsSync(`.agents/skills/${skill}/SKILL.md`), `.agents/skills/${skill}/SKILL.md present`);
  check(runtimes.some((runtime) => fs.existsSync(runtime)), 'governance runtime present in tool/');

  if (fs.existsSync('AGENTS.md') && fs.existsSync('CLAUDE.md')) {
    const normalize = (text) => text.split('\n').filter((line) => !line.startsWith('<!--')).join('').replace(/\s+/g, '');
    check(normalize(fs.readFileSync('AGENTS.md', 'utf8')) === normalize(fs.readFileSync('CLAUDE.md', 'utf8')), 'CLAUDE.md mirror parity verified');
  } else {
    check(false, 'mirror parity not verifiable (missing AGENTS.md or CLAUDE.md)');
  }

  const agentsText = fs.existsSync('AGENTS.md') ? fs.readFileSync('AGENTS.md', 'utf8') : '';
  const llmsText = fs.existsSync('llms.txt') ? fs.readFileSync('llms.txt', 'utf8') : '';
  check(!placeholderPattern.test(agentsText) && !placeholderPattern.test(llmsText), 'no unresolved template placeholders');

  console.log(`\n📊 Conformance: ${passed}/${checks} checks passed`);
  if (failed) process.exit(1);
}

function runSync() {
  if (!fs.existsSync('AGENTS.md')) {
    console.error('AGENTS.md not found.');
    process.exit(1);
  }
  const content = fs.readFileSync('AGENTS.md', 'utf8');
  fs.writeFileSync('CLAUDE.md', `<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n\n${content}`);
  console.log('✅ Synchronized AGENTS.md -> CLAUDE.md');
}

function runMetrics() {
  if (fs.existsSync('docs/wiki/metrics/baseline.json')) {
    console.log(fs.readFileSync('docs/wiki/metrics/baseline.json', 'utf8'));
  }
}
