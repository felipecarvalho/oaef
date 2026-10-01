import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    exit(1);
  }

  final command = args.first;
  switch (command) {
    case 'quality-gate':
    case 'audit':
      final record = args.contains('--record') || args.contains('--ratchet');
      await runQualityGate(record: record);
    case 'metrics':
      await runMetricsReport();
    case 'lint':
      await runLint();
    case 'conform':
    case 'doctor':
      await runConform();
    case 'sync':
      await runSync();
    default:
      stdout.writeln('Unknown command: $command');
      _printUsage();
      exit(1);
  }
}

void _printUsage() {
  stdout
    ..writeln('OAEF Governance Tool (Dart Engine)')
    ..writeln('Usage: dart run tool/governance.dart <command>')
    ..writeln('Commands:')
    ..writeln('  quality-gate [--record]  Audit Quality Gates & ratchet baseline')
    ..writeln('  metrics                  Display historical metrics report')
    ..writeln('  lint                     Audit links, cascade references & secrets')
    ..writeln('  doctor                   Audit OAEF conformance (structure, skills, mirrors)')
    ..writeln('  sync                     Synchronize AGENTS.md to mirrors');
}

/// ---------------------------------------------------------------------------
/// QUALITY GATES & METRICS
/// ---------------------------------------------------------------------------

Future<void> runQualityGate({bool record = false}) async {
  stdout.writeln('\n🔍 Initiating OAEF Quality Gate Audit...');

  final baselineFile = File('docs/wiki/metrics/baseline.json');

  var baseline = <String, dynamic>{};
  if (baselineFile.existsSync()) {
    final decoded = jsonDecode(baselineFile.readAsStringSync());
    if (decoded is Map<String, dynamic>) {
      baseline = decoded['baseline'] as Map<String, dynamic>? ?? {};
    }
  }

  final coverageConfig = baseline['coverage'] as Map<String, dynamic>? ?? {};
  final minLineCov = (coverageConfig['lines_min_percentage'] as num?)?.toDouble() ?? 95.0;
  final minBranchCov = (coverageConfig['branches_min_percentage'] as num?)?.toDouble() ?? 90.0;

  final sizingConfig = baseline['clean_sizing'] as Map<String, dynamic>? ?? {};
  final maxFileLines = (sizingConfig['file_max_lines'] as num?)?.toInt() ?? 300;

  // 1. Run Tests with Coverage
  stdout.writeln('ℹ️  Running test suite with coverage...');
  ProcessResult testResult;
  if (File('pubspec.yaml').existsSync()) {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    if (pubspec.contains('flutter:')) {
      testResult = await Process.run('flutter', ['test', '--coverage']);
    } else {
      testResult = await Process.run('dart', ['test', '--coverage=coverage']);
    }
  } else {
    testResult = await Process.run('dart', ['test']);
  }

  if (testResult.exitCode != 0) {
    stderr
      ..writeln('❌ Tests failed:')
      ..writeln(testResult.stderr)
      ..writeln(testResult.stdout);
    exit(1);
  }

  // 2. Parse LCOV
  final lcovFile = File('coverage/lcov.info');
  var linesFound = 0;
  var linesHit = 0;
  var branchesFound = 0;
  var branchesHit = 0;
  if (lcovFile.existsSync()) {
    for (final line in lcovFile.readAsLinesSync()) {
      if (line.startsWith('LF:')) {
        linesFound += int.tryParse(line.substring(3)) ?? 0;
      } else if (line.startsWith('LH:')) {
        linesHit += int.tryParse(line.substring(3)) ?? 0;
      } else if (line.startsWith('BRF:')) {
        branchesFound += int.tryParse(line.substring(4)) ?? 0;
      } else if (line.startsWith('BRH:')) {
        branchesHit += int.tryParse(line.substring(4)) ?? 0;
      }
    }
  }

  final linePercent = linesFound == 0 ? 100.0 : (linesHit / linesFound) * 100.0;
  stdout.writeln('📊 Line Coverage: ${linePercent.toStringAsFixed(1)}% (Floor: $minLineCov%)');

  final branchPercent = branchesFound == 0 ? 100.0 : (branchesHit / branchesFound) * 100.0;
  if (branchesFound > 0) {
    stdout.writeln('📊 Branch Coverage: ${branchPercent.toStringAsFixed(1)}% (Floor: $minBranchCov%)');
  }

  // 3. Clean Sizing Audit
  var oversizedFiles = 0;
  final libDir = Directory('lib');
  if (libDir.existsSync()) {
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('.g.dart')) {
        final lineCount = entity.readAsLinesSync().length;
        if (lineCount > maxFileLines) {
          oversizedFiles++;
          stderr.writeln('⚠️  Oversized file (${lineCount}L > ${maxFileLines}L): ${entity.path}');
        }
      }
    }
  }

  // 4. Verification verdict
  var passed = true;
  if (linePercent < minLineCov) {
    stderr.writeln('❌ Quality Gate Failed: Line coverage $linePercent% < $minLineCov%');
    passed = false;
  }
  if (branchesFound > 0 && branchPercent < minBranchCov) {
    stderr.writeln('❌ Quality Gate Failed: Branch coverage $branchPercent% < $minBranchCov%');
    passed = false;
  }
  if (oversizedFiles > 0) {
    stderr.writeln('❌ Quality Gate Failed: $oversizedFiles oversized files detected');
    passed = false;
  }

  if (passed) {
    stdout.writeln('\n🎉 Quality Gates PASSED! All thresholds satisfied.\n');
    if (record) {
      stdout.writeln('📝 Recording session in metrics history and applying Monotonic Ratchet...');
      // Ratchet baseline if coverage improved
      if (linePercent > minLineCov) {
        coverageConfig['lines_min_percentage'] = double.parse(linePercent.toStringAsFixed(1));
        baseline['coverage'] = coverageConfig;
        baselineFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({'baseline': baseline}));
        stdout.writeln('🔒 Monotonic Ratchet: Updated baseline floor to ${linePercent.toStringAsFixed(1)}%');
      }
    }
  } else {
    exit(1);
  }
}

Future<void> runMetricsReport() async {
  final baselineFile = File('docs/wiki/metrics/baseline.json');
  if (!baselineFile.existsSync()) {
    stdout.writeln('baseline.json not found.');
    return;
  }
  stdout.writeln(baselineFile.readAsStringSync());
}

/// ---------------------------------------------------------------------------
/// LINT, LINKS & SECRET SCANNING
/// ---------------------------------------------------------------------------

Future<void> runLint() async {
  stdout.writeln('🔍 Executing OAEF Integrity & Secret Audits...');
  var failed = false;

  // 1. Mirror Parity Check (AGENTS.md vs CLAUDE.md)
  final agentsFile = File('AGENTS.md');
  final claudeFile = File('CLAUDE.md');
  if (agentsFile.existsSync() && claudeFile.existsSync()) {
    final agentsText = normalizeMirrorText(agentsFile.readAsStringSync());
    final claudeText = normalizeMirrorText(claudeFile.readAsStringSync());
    if (agentsText != claudeText) {
      stderr.writeln('❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run "oaef sync".');
      failed = true;
    } else {
      stdout.writeln('✅ [LINT] Mirror parity AGENTS.md <-> CLAUDE.md verified.');
    }
  }

  // 2. Secret & PII Scanner
  final secretPatterns = [
    RegExp(r'sk-[a-zA-Z0-9]{20,}'),
    RegExp(r'ghp_[a-zA-Z0-9]{20,}'),
    RegExp(r'AKIA[0-9A-Z]{16}'),
    RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
  ];

  final docsDir = Directory('docs');
  if (docsDir.existsSync()) {
    for (final entity in docsDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        final content = entity.readAsStringSync();
        for (final pattern in secretPatterns) {
          if (pattern.hasMatch(content)) {
            stderr.writeln('🚨 [SECURITY] Potential secret detected in ${entity.path}!');
            failed = true;
          }
        }
      }
    }
  }

  // 3. Anti-Suppression Scanner (Strict Zero-Tolerance)
  final libDir = Directory('lib');
  if (libDir.existsSync()) {
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('.g.dart')) {
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('// ignore:') || line.contains('// ignore_for_file:')) {
            if (!line.contains('deprecated_member_use') && !line.contains('type=lint')) {
              stderr.writeln('🚨 [LINT] Unallowed ignore directive in ${entity.path}:${i + 1}: ${line.trim()}');
              failed = true;
            }
          }
        }
      }
    }
  }

  if (failed) {
    stderr.writeln('\n❌ LINT FAILED.');
    exit(1);
  } else {
    stdout.writeln('✅ [LINT] All integrity and secret audits passed cleanly.\n');
  }
}

String normalizeMirrorText(String text) {
  return text
      .split('\n')
      .where((line) => !line.startsWith('<!--'))
      .join('')
      .replaceAll(RegExp(r'\s+'), '');
}

Future<void> runConform() async {
  stdout.writeln('🩺 OAEF Conformance Audit (doctor)...');
  const requiredFiles = [
    'AGENTS.md', 'CLAUDE.md', 'llms.txt', 'oaef.context.json',
    'docs/INDEX.md', 'docs/MANIFESTO.md', 'docs/DESIGN.md',
    'docs/standards/coding_patterns.md', 'docs/standards/testing.md', 'docs/standards/logging.md',
    'docs/wiki/metrics/baseline.json', 'docs/wiki/memory/handoff.md', 'docs/wiki/log.md',
    'docs/HARNESSES.md',
    '.github/workflows/ci.yml', '.github/pull_request_template.md',
    '.gitignore', 'CONTRIBUTING.md', 'SECURITY.md',
  ];
  const skills = [
    'architecture-audit', 'code-review', 'collect-coverage', 'component-author',
    'fix-layout-issues', 'nullable-types', 'run-static-analysis', 'screen-builder',
    'test-generator', 'ui-preview', 'conformance-audit',
  ];
  const runtimes = [
    'tool/governance.sh', 'tool/governance.mjs', 'tool/governance.py', 'tool/governance.dart',
    'tool/governance.go', 'tool/governance.rs', 'tool/governance.main.kts', 'tool/governance.swift',
    'tool/Governance.cs',
  ];

  var checks = 0;
  var passed = 0;
  var failed = false;

  void check(bool condition, String label) {
    checks++;
    if (condition) {
      passed++;
      stdout.writeln('✅ $label');
    } else {
      stderr.writeln('❌ $label');
      failed = true;
    }
  }

  for (final requiredFile in requiredFiles) {
    check(File(requiredFile).existsSync(), '$requiredFile present');
  }
  for (final skill in skills) {
    check(File('.agents/skills/$skill/SKILL.md').existsSync(), '.agents/skills/$skill/SKILL.md present');
  }
  check(runtimes.any((runtime) => File(runtime).existsSync()), 'governance runtime present in tool/');

  final agentsFile = File('AGENTS.md');
  final claudeFile = File('CLAUDE.md');
  if (agentsFile.existsSync() && claudeFile.existsSync()) {
    check(
      normalizeMirrorText(agentsFile.readAsStringSync()) == normalizeMirrorText(claudeFile.readAsStringSync()),
      'CLAUDE.md mirror parity verified',
    );
  } else {
    check(false, 'mirror parity not verifiable (missing AGENTS.md or CLAUDE.md)');
  }

  final placeholderPattern = RegExp(r'\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}');
  var placeholderHits = false;
  for (final candidate in ['AGENTS.md', 'llms.txt']) {
    final candidateFile = File(candidate);
    if (candidateFile.existsSync() && placeholderPattern.hasMatch(candidateFile.readAsStringSync())) {
      placeholderHits = true;
    }
  }
  check(!placeholderHits, 'no unresolved template placeholders');

  stdout.writeln('\n📊 Conformance: $passed/$checks checks passed');
  if (failed) {
    exit(1);
  }
}

Future<void> runSync() async {
  final agentsFile = File('AGENTS.md');
  if (!agentsFile.existsSync()) {
    stderr.writeln('AGENTS.md not found in root.');
    exit(1);
  }
  final agentsContent = agentsFile.readAsStringSync();
  final claudeFile = File('CLAUDE.md');
  claudeFile.writeAsStringSync(
    '<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n'
    '<!-- To modify rules, edit AGENTS.md and run "oaef sync". -->\n\n'
    '$agentsContent',
  );
  stdout.writeln('✅ Synchronized AGENTS.md -> CLAUDE.md');
}
