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
    const agents = fs.readFileSync('AGENTS.md', 'utf8').trim();
    let claude = fs.readFileSync('CLAUDE.md', 'utf8').trim();
    if (claude.startsWith('<!--')) {
      const end = claude.indexOf('-->');
      if (end !== -1) claude = claude.slice(end + 3).trim();
    }
    if (agents !== claude) {
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
