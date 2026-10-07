// ==============================================================================
// OAEF Governance Engine — Dart & Flutter
// Implements docs/standards/governance_checks.md for the `dart-flutter` stack.
// Author: Felipe Carvalho | License: Apache 2.0
// ==============================================================================

import 'dart:convert';
import 'dart:io';

// ------------------------------------------------------------------------------
// Canonical catalog (must stay byte-identical to AGENTS.md section 3)
// ------------------------------------------------------------------------------
const List<String> catalogSkills = <String>[
  'ponytail',
  'nullable-types',
  'architecture-audit',
  'screen-builder',
  'component-author',
  'responsive-layout',
  'ui-preview',
  'fix-layout-issues',
  'test-generator',
  'collect-coverage',
  'run-static-analysis',
  'code-review',
  'conformance-audit',
];

const Map<String, List<String>> skillTriggerTerms = <String, List<String>>{
  'ponytail': <String>[
    'new',
    'refactor',
    'add',
    'simple',
    'minimal',
    'yagni',
    'dead code',
    'delete',
    'remove',
  ],
  'screen-builder': <String>['screen', 'page', 'feature', 'flow', 'view'],
  'component-author': <String>['component', 'widget', 'button', 'card', 'modal'],
  'ui-preview': <String>['preview', 'storybook', 'isolated render'],
  'responsive-layout': <String>[
    'responsive',
    'adaptive',
    'breakpoint',
    'tablet',
    'foldable',
    'viewport',
  ],
  'fix-layout-issues': <String>[
    'overflow',
    'unbounded',
    'layout',
    'layout broken',
    'render error',
  ],
  'test-generator': <String>['test', 'coverage', 'mock', 'fixture'],
  'collect-coverage': <String>[
    'coverage',
    'lcov',
    'jacoco',
    'cobertura',
    'branches',
  ],
  'run-static-analysis': <String>['analyze', 'lint', 'typecheck', 'warnings'],
  'nullable-types': <String>[
    'null',
    'optional',
    'nil',
    'guard clause',
    'defensive',
  ],
  'architecture-audit': <String>[
    'architecture',
    'boundary',
    'coupling',
    'cycle',
  ],
  'conformance-audit': <String>[
    'conformance',
    'doctor',
    'parity',
    'frontmatter',
  ],
  'code-review': <String>['review', 'pr', 'checklist', 'pre-pr'],
};

const List<String> canonicalRecipes = <String>[
  '1. Feature / Screen Construction: ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review',
  '2. Reusable Component / Module Authoring: ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis',
  '3. Bug Fix / Root-Cause Remediation: ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis',
  '4. Domain, Data & Infrastructure: ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis',
  '5. Pre-Submission / Pull Request Cycle: collect-coverage -> run-static-analysis -> code-review',
];

const List<List<String>> routingFixtures = <List<String>>[
  <String>['create a new screen for the booking flow', 'screen-builder'],
  <String>['build a reusable button component', 'component-author'],
  <String>['the layout overflows on small screens', 'fix-layout-issues'],
  <String>['add responsive breakpoints for tablet', 'responsive-layout'],
  <String>['write unit tests for the payment service', 'test-generator'],
  <String>['collect coverage and check the branch floor', 'collect-coverage'],
  <String>['fix all analyzer warnings', 'run-static-analysis'],
  <String>['this optional list parameter is always null', 'nullable-types'],
  <String>['audit module boundaries and cyclic imports', 'architecture-audit'],
  <String>['verify the repo conforms to the framework', 'conformance-audit'],
  <String>['review my PR before I open it', 'code-review'],
  <String>['remove the dead code and the 1-line use case', 'ponytail'],
];

const List<String> mirrorDirectories = <String>[
  '.claude/skills',
  '.cursor/rules',
  '.windsurf/skills',
  '.cline/skills',
  '.grok/agents',
];

const String contextFile = 'oaef.context.json';
const String baselineFile = 'docs/wiki/metrics/baseline.json';
const String adoptionLedgerFile = 'docs/wiki/metrics/adoption.json';
const String agentsFile = 'AGENTS.md';
const String llmsFile = 'llms.txt';

const String sk02MessageSuffix =
    ' frontmatter must declare "Use when", "Triggers on:" and "Chains into:" with >=150 characters and name==directory';

// ------------------------------------------------------------------------------
// Global counters
// ------------------------------------------------------------------------------
final Map<String, int> ccCounts = <String, int>{
  'CC-01': 0,
  'CC-02': 0,
  'CC-03': 0,
  'CC-04': 0,
  'CC-05': 0,
  'CC-06': 0,
  'CC-07': 0,
  'CC-08': 0,
  'CC-09': 0,
  'CC-10': 0,
  'CC-11': 0,
};
int ccTotal = 0;
int skFailures = 0;

String profile = 'strict';
String adoptionMode = 'install';
bool forceStandardProfile = false;

// ------------------------------------------------------------------------------
// Entry point
// ------------------------------------------------------------------------------
Future<void> main(List<String> args) async {
  _enterRepositoryRoot();
  if (args.isEmpty) {
    printUsage();
    exitCode = 1;
    return;
  }
  final command = args.first;
  final rest = args.sublist(1);
  switch (command) {
    case 'quality-gate':
    case 'audit':
      await runQualityGate(
        record: rest.contains('--record') || rest.contains('--ratchet'),
      );
    case 'metrics':
      runMetrics();
    case 'lint':
      runLint();
    case 'conform':
    case 'doctor':
      runConform();
    case 'sync':
      runSync();
    case 'clean-code':
    case 'governance-check':
      runCleanCode(standardOverride: rest.contains('--standard'));
    case 'ponytail-debt':
      runPonytailDebt();
    case 'ponytail-audit':
      runPonytailAudit();
    case 'skills-audit':
      runSkillsAudit(selftest: rest.contains('--selftest'));
    case 'skills-route':
      runSkillsRoute(rest.join(' '));
    case 'skills-sync-mirrors':
      runSkillsSyncMirrors(checkOnly: rest.contains('--check'));
    case 'ponytail':
      final subcommand = rest.isNotEmpty ? rest.first : 'audit';
      if (subcommand == 'debt') {
        runPonytailDebt();
      } else if (subcommand == 'audit') {
        runPonytailAudit();
      } else {
        printUsage();
        exitCode = 1;
      }
    case 'skills':
      final subcommand = rest.isNotEmpty ? rest.first : '';
      switch (subcommand) {
        case 'sync-mirrors':
          runSkillsSyncMirrors(checkOnly: rest.contains('--check'));
        case 'audit':
          runSkillsAudit(selftest: rest.contains('--selftest'));
        case 'route':
          runSkillsRoute(rest.length > 1 ? rest.sublist(1).join(' ') : '');
        default:
          printUsage();
          exitCode = 1;
      }
    default:
      printUsage();
      exitCode = 1;
  }
}

void _enterRepositoryRoot() {
  var root = Directory.current.path;
  try {
    final script = File.fromUri(Platform.script);
    final scriptDirectory = script.parent;
    if (scriptDirectory.path.endsWith('tool') && script.existsSync()) {
      root = scriptDirectory.parent.path;
    }
  } catch (_) {
    // Fall back to the current working directory.
  }
  try {
    Directory.current = root;
  } catch (_) {
    // Keep the current working directory when it cannot be changed.
  }
}

void printUsage() {
  stdout
    ..writeln('OAEF Governance Tool (Dart & Flutter Engine)')
    ..writeln('Usage: dart run tool/governance.dart <command>')
    ..writeln('Commands:')
    ..writeln(
      '  quality-gate|audit        Quality Gate audit (coverage, sizing, clean code)',
    )
    ..writeln(
      '  clean-code                Governance barriers (docs/standards/governance_checks.md)',
    )
    ..writeln(
      '  ponytail-debt             Report every "// ponytail:" debt marker (PT-01)',
    )
    ..writeln('  ponytail-audit            Advisory anti-slop audit')
    ..writeln(
      '  skills-audit [--selftest] Skill activation invariants (SK-01..SK-06)',
    )
    ..writeln(
      '  skills-route "<query>"    Resolve a prompt to its governing skill and recipe',
    )
    ..writeln(
      '  skills sync-mirrors [--check] Rebuild or validate the harness skill mirrors',
    )
    ..writeln(
      '  skills-sync-mirrors [--check] Flat alias of the mirror rebuild/validation',
    )
    ..writeln('  lint                      Mirror parity, secrets, anti-suppression, skills')
    ..writeln('  doctor|conform            Conformance audit')
    ..writeln('  metrics                   Display baseline thresholds')
    ..writeln('  sync                      Synchronize AGENTS.md to CLAUDE.md');
}

// ------------------------------------------------------------------------------
// Generic helpers
// ------------------------------------------------------------------------------
String readFileText(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (_) {
    return '';
  }
}

List<String> readLines(String path) {
  try {
    return File(path).readAsLinesSync();
  } catch (_) {
    return <String>[];
  }
}

String relativePath(String path) {
  var normalized = path.replaceAll('\\', '/');
  final cwd = Directory.current.path.replaceAll('\\', '/');
  if (normalized.startsWith('$cwd/')) {
    normalized = normalized.substring(cwd.length + 1);
  }
  if (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  return normalized;
}

List<String> walkFiles(String directory) {
  final found = <String>[];
  final dir = Directory(directory);
  if (!dir.existsSync()) return found;
  try {
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File) found.add(relativePath(entity.path));
    }
  } catch (_) {
    // Unreadable trees are skipped.
  }
  found.sort();
  return found;
}

dynamic readJson(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    return jsonDecode(file.readAsStringSync());
  } catch (_) {
    return null;
  }
}

String? jsonStringValue(dynamic node, String key) {
  if (node is Map && node[key] is String) return node[key] as String;
  return null;
}

void emit(String id, String path, int line, String message) {
  stdout.writeln('$id $path:$line — $message');
  if (ccCounts.containsKey(id)) ccCounts[id] = ccCounts[id]! + 1;
  if (id.startsWith('CC-')) ccTotal++;
}

void emitSkill(String id, String path, int line, String message) {
  stdout.writeln('$id $path:$line — $message');
  skFailures++;
}

String stripLineComment(String line) {
  final index = line.indexOf('//');
  if (index < 0) return line;
  if (index > 0 && line[index - 1] == ':') return line;
  return line.substring(0, index);
}

bool isBlankOrComment(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return true;
  return trimmed.startsWith('//') ||
      trimmed.startsWith('/*') ||
      trimmed.startsWith('*') ||
      trimmed.startsWith('#');
}

void copyDirectory(String source, String destination) {
  final sourceDirectory = Directory(source);
  if (!sourceDirectory.existsSync()) return;
  Directory(destination).createSync(recursive: true);
  for (final entity in sourceDirectory.listSync(recursive: true, followLinks: false)) {
    final target = '$destination/${entity.path.substring(source.length + 1)}';
    if (entity is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (entity is File) {
      File(target).parent.createSync(recursive: true);
      entity.copySync(target);
    }
  }
}

// ------------------------------------------------------------------------------
// Profile & adoption resolution
// ------------------------------------------------------------------------------
void resolveProfile() {
  final context = readJson(contextFile);
  final baseline = readJson(baselineFile);
  profile = 'strict';
  final strictness = jsonStringValue(context, 'strictness');
  if (strictness != null && strictness.isNotEmpty) {
    profile = strictness;
  } else {
    final baselineProfile = jsonStringValue(baseline, 'profile');
    if (baselineProfile != null && baselineProfile.isNotEmpty) {
      profile = baselineProfile;
    }
  }
  final mode = jsonStringValue(context, 'adoption_mode');
  adoptionMode = (mode == null || mode.isEmpty) ? 'install' : mode;
  if (forceStandardProfile) profile = 'standard';
}

bool isAdoptionMode() => adoptionMode != 'install';

bool isUserOwnedSkill(String skill) {
  final ledger = readJson(adoptionLedgerFile);
  if (ledger is! Map) return false;
  final userSkills = ledger['user_skills'];
  if (userSkills is! List) return false;
  for (final entry in userSkills) {
    if (entry is String && entry == skill) return true;
  }
  return false;
}

bool ccBlocks(String id) {
  if (id == 'CC-04') return true;
  if (id == 'CC-11') return false;
  if (isAdoptionMode()) return false;
  return profile == 'strict';
}

int ccThreshold(String id) {
  const Map<String, String> thresholdKeys = <String, String>{
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
    'CC-11': 'max_avoidable_allocations',
  };
  final key = thresholdKeys[id];
  if (key == null) return 0;
  final baseline = readJson(baselineFile);
  if (baseline is Map && baseline['baseline'] is Map) {
    final cleanCode = (baseline['baseline'] as Map)['clean_code'];
    if (cleanCode is Map && cleanCode[key] is num) {
      return (cleanCode[key] as num).toInt();
    }
  }
  return 0;
}

// ------------------------------------------------------------------------------
// File discovery & scope (production root: lib/ ; test trees: test/)
// ------------------------------------------------------------------------------
const Set<String> excludedSegments = <String>{
  '.git',
  '.github',
  '.agents',
  '.claude',
  '.cursor',
  '.windsurf',
  '.cline',
  '.grok',
  '.oaef',
  'node_modules',
  'vendor',
  'build',
  'dist',
  'target',
  'obj',
  'bin',
  'tool',
  'docs',
  'templates',
  'examples',
  'coverage',
  'generated',
  '.venv',
  'venv',
  '__pycache__',
  '.dart_tool',
  '.gradle',
  '.idea',
};

const Set<String> testSegments = <String>{
  'test',
  'tests',
  '__tests__',
  'spec',
  'specs',
  'androidTest',
  'iosTest',
};

bool isExcludedPath(String path) {
  for (final segment in path.split('/')) {
    if (excludedSegments.contains(segment)) return true;
  }
  final name = path.split('/').last;
  if (name.contains('.g.')) return true;
  if (name.endsWith('_pb2.py') || name.endsWith('_pb2_grpc.py')) return true;
  if (name.endsWith('.min.js')) return true;
  if (name.contains('.generated.')) return true;
  if (name.contains('.freezed.')) return true;
  if (name.contains('.designer.')) return true;
  return false;
}

bool isTestPath(String path) {
  for (final segment in path.split('/')) {
    if (testSegments.contains(segment)) return true;
  }
  final name = path.split('/').last;
  if (RegExp(r'_test\.[^/]+$').hasMatch(name)) return true;
  if (RegExp(r'\.spec\.[^/]+$').hasMatch(name)) return true;
  if (RegExp(r'\.test\.[^/]+$').hasMatch(name)) return true;
  if (RegExp(r'^test_.*\.py$').hasMatch(name)) return true;
  if (RegExp(r'Tests\.cs$').hasMatch(name)) return true;
  if (RegExp(r'Test\.kt$').hasMatch(name)) return true;
  return false;
}

List<String> _dartFiles(String root) {
  return walkFiles(root)
      .where((path) => path.endsWith('.dart'))
      .where((path) => !isExcludedPath(path))
      .toList();
}

List<String> productionFiles() {
  return _dartFiles('lib').where((path) => !isTestPath(path)).toList();
}

List<String> testFiles() => _dartFiles('test');

List<String> allSourceFiles() {
  final files = <String>{..._dartFiles('lib'), ..._dartFiles('test')}.toList();
  files.sort();
  return files;
}

List<String> allocationFiles() {
  final files = <String>{...productionFiles(), ...testFiles()}.toList();
  files.sort();
  return files;
}

// ------------------------------------------------------------------------------
// CC-01 / CC-02 : identifier discipline
// ------------------------------------------------------------------------------
const Set<String> crypticIdentifiers = <String>{
  'cb',
  'fn',
  'res',
  'req',
  'btn',
  'val',
  'tmp',
  'ctx',
  'el',
  'usr',
  'mgr',
  'idx',
  'cnt',
  'buf',
  'str',
  'num',
  'doc',
  'elem',
  'curr',
  'prev',
};

const Set<String> controlKeywords = <String>{
  'if',
  'while',
  'for',
  'switch',
  'catch',
  'assert',
  'return',
  'case',
  'else',
  'do',
  'in',
  'is',
  'await',
  'yield',
  'on',
  'when',
  'throw',
  'new',
  'super',
  'this',
  'typedef',
  'extension',
  'with',
  'mixin',
};

void checkIdentifierDiscipline(String path, List<String> lines) {
  final declaration = RegExp(r'\b(final|var|const)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=');
  final closureParameter =
      RegExp(r'\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)\s*(?:async\*?\s*)?(?:=>|\{)');
  final catchBinding =
      RegExp(r'\bcatch\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*[,)]');
  final precedingWord = RegExp(r'([A-Za-z_][A-Za-z0-9_]*)$');

  for (var index = 0; index < lines.length; index++) {
    final line = stripLineComment(lines[index]);
    if (line.trim().isEmpty) continue;

    final names = <String>{};
    for (final match in declaration.allMatches(line)) {
      names.add(match.group(2)!);
    }
    for (final match in closureParameter.allMatches(line)) {
      final before = line.substring(0, match.start).trimRight();
      final previous = precedingWord.firstMatch(before)?.group(1);
      if (previous != null && controlKeywords.contains(previous)) continue;
      names.add(match.group(1)!);
    }
    for (final match in catchBinding.allMatches(line)) {
      names.add(match.group(1)!);
    }

    for (final name in names) {
      if (name == '_') continue;
      if (name.length == 1) {
        if ((name == 'i' || name == 'j') && line.contains('for')) continue;
        emit(
          'CC-01',
          path,
          index + 1,
          'prohibited single-letter identifier "$name"; use a descriptive name',
        );
      } else if (crypticIdentifiers.contains(name.toLowerCase())) {
        emit(
          'CC-02',
          path,
          index + 1,
          'prohibited cryptic abbreviation "$name"; use the full identifier',
        );
      }
    }
  }
}

// ------------------------------------------------------------------------------
// CC-03 : mutable lazy initialization
// ------------------------------------------------------------------------------
void checkLazyInit(String path, List<String> lines) {
  const lazyFields = <String>['client', 'instance', 'service', 'provider'];
  for (var index = 0; index < lines.length; index++) {
    final line = stripLineComment(lines[index]);
    if (!line.contains('??=')) continue;
    final lowered = line.toLowerCase();
    if (lazyFields.any(lowered.contains)) {
      emit(
        'CC-03',
        path,
        index + 1,
        'prohibited mutable lazy initialization; inject the dependency via constructor',
      );
    }
  }
}

// ------------------------------------------------------------------------------
// CC-04 : hardcoded placeholder / secret (blocking under every profile)
// ------------------------------------------------------------------------------
void checkSecrets(String path, List<String> lines) {
  final placeholder = RegExp(r'dummy_|dummy(?=[A-Z])|changeme|TODO_KEY');
  final assignment = RegExp(
    r'([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:const\s+)?(["\x27])([^"\x27]*)\2',
    caseSensitive: false,
  );
  const keyNames = <String>[
    'api_key',
    'apikey',
    'api-key',
    'secret',
    'password',
    'token',
  ];
  for (var index = 0; index < lines.length; index++) {
    final line = stripLineComment(lines[index]);
    if (line.trim().isEmpty) continue;
    if (placeholder.hasMatch(line)) {
      emit(
        'CC-04',
        path,
        index + 1,
        'prohibited hardcoded placeholder/secret; source it from configuration/environment',
      );
      continue;
    }
    final match = assignment.firstMatch(line);
    if (match == null) continue;
    final name = match.group(1)!.toLowerCase();
    if (!keyNames.any(name.contains)) continue;
    final value = match.group(3)!;
    if (value.contains(r'$')) continue;
    emit(
      'CC-04',
      path,
      index + 1,
      'prohibited hardcoded placeholder/secret; source it from configuration/environment',
    );
  }
}

// ------------------------------------------------------------------------------
// CC-05 : raw print / debug output
// ------------------------------------------------------------------------------
void checkRawPrints(String path, List<String> lines) {
  final rawPrint = RegExp(r'(^|[^A-Za-z0-9_.])print\s*\(');
  for (var index = 0; index < lines.length; index++) {
    final line = stripLineComment(lines[index]);
    if (line.trim().isEmpty) continue;
    if (rawPrint.hasMatch(line)) {
      emit(
        'CC-05',
        path,
        index + 1,
        'prohibited raw print/debug output in production code; use the logging interface',
      );
    }
  }
}

// ------------------------------------------------------------------------------
// CC-06 : silent exception swallowing
// ------------------------------------------------------------------------------
void checkSilentCatches(String path, List<String> lines) {
  final inlineEmpty = RegExp(r'\bcatch\s*(\([^)]*\))?\s*\{\s*\}');
  final openHandler = RegExp(r'\bcatch\s*(\([^)]*\))?\s*\{\s*$');
  const message =
      'prohibited silent exception swallowing; log with error+stack trace or rethrow';
  for (var index = 0; index < lines.length; index++) {
    final line = stripLineComment(lines[index]);
    if (inlineEmpty.hasMatch(line)) {
      emit('CC-06', path, index + 1, message);
      continue;
    }
    if (!openHandler.hasMatch(line.trimRight())) continue;
    var emptied = true;
    for (var lookahead = 1; lookahead <= 3; lookahead++) {
      final upcoming = index + lookahead;
      if (upcoming >= lines.length) break;
      final text = lines[upcoming];
      if (isBlankOrComment(text)) continue;
      if (text.trimLeft().startsWith('}')) break;
      emptied = false;
      break;
    }
    if (emptied) emit('CC-06', path, index + 1, message);
  }
}

// ------------------------------------------------------------------------------
// CC-07 : service-locator confinement
// ------------------------------------------------------------------------------
bool isServiceLocatorAllowedPath(String path) {
  final segments = path.split('/');
  if (segments.contains('di') ||
      segments.contains('presentation') ||
      segments.contains('debug')) {
    return true;
  }
  final name = segments.last;
  if (name.startsWith('main.')) return true;
  for (final suffix in <String>['_screen.', '_view.', '_widget.', '_mixin.']) {
    if (name.contains(suffix)) return true;
  }
  return false;
}

void checkServiceLocator(String path, List<String> lines) {
  if (isServiceLocatorAllowedPath(path)) return;
  final container = RegExp(r'\bgetIt\s*[<(]|\bGetIt\.instance\s*<');
  for (var index = 0; index < lines.length; index++) {
    final line = stripLineComment(lines[index]);
    if (container.hasMatch(line)) {
      emit(
        'CC-07',
        path,
        index + 1,
        'prohibited service-locator resolution outside the composition root/presentation layer; inject via constructor',
      );
    }
  }
}

// ------------------------------------------------------------------------------
// CC-08 : nullable collection parameter
// ------------------------------------------------------------------------------
void checkNullableCollections(String path, List<String> lines) {
  final nullableCollection = RegExp(r'\b(List|Map|Set)\s*<');
  final parameterName = RegExp(r'^(\s*)([A-Za-z_][A-Za-z0-9_]*)');
  final constantEmptyDefault = RegExp(
    r'^\s*[A-Za-z_][A-Za-z0-9_]*\s*=\s*(?:const\s+)?(?:<[^<>]*>\s*)?(?:\[]|\{\})',
  );
  for (var index = 0; index < lines.length; index++) {
    final line = stripLineComment(lines[index]);
    if (line.contains('copyWith')) continue;
    for (final match in nullableCollection.allMatches(line)) {
      var depth = 0;
      var cursor = match.end - 1;
      var closed = false;
      while (cursor < line.length) {
        final character = line[cursor];
        if (character == '<') {
          depth++;
        } else if (character == '>') {
          depth--;
          if (depth == 0) {
            cursor++;
            closed = true;
            break;
          }
        }
        cursor++;
      }
      if (!closed) continue;
      var probe = cursor;
      while (probe < line.length &&
          (line[probe] == ' ' || line[probe] == '\t')) {
        probe++;
      }
      if (probe >= line.length || line[probe] != '?') continue;
      probe++;
      while (probe < line.length &&
          (line[probe] == ' ' || line[probe] == '\t')) {
        probe++;
      }
      final remainder = line.substring(probe);
      final nameMatch = parameterName.firstMatch(remainder);
      if (nameMatch == null) continue;
      if (constantEmptyDefault.hasMatch(remainder)) continue;
      emit(
        'CC-08',
        path,
        index + 1,
        'prohibited nullable collection parameter; default to a constant empty collection',
      );
    }
  }
}

// ------------------------------------------------------------------------------
// CC-09 : unimplemented placeholder
// ------------------------------------------------------------------------------
void checkUnimplemented(String path, List<String> lines) {
  final placeholder = RegExp(r'UnimplementedError\s*\(');
  for (var index = 0; index < lines.length; index++) {
    final line = stripLineComment(lines[index]);
    if (placeholder.hasMatch(line)) {
      emit(
        'CC-09',
        path,
        index + 1,
        'prohibited unimplemented placeholder in production contract; implement the contract (LSP)',
      );
    }
  }
}

// ------------------------------------------------------------------------------
// CC-10 : concrete network-client instantiation
// ------------------------------------------------------------------------------
bool isCompositionRootPath(String path) {
  final segments = path.split('/');
  if (segments.contains('di') || segments.contains('presentation')) return true;
  return segments.last.startsWith('main.');
}

void checkConcreteClients(String path, List<String> lines) {
  if (isCompositionRootPath(path)) return;
  final client = RegExp(r'(?:^|[^A-Za-z0-9_])(?:new\s+)?(?:HttpClient|Dio)\s*\(');
  for (var index = 0; index < lines.length; index++) {
    final line = stripLineComment(lines[index]);
    if (client.hasMatch(line)) {
      emit(
        'CC-10',
        path,
        index + 1,
        'prohibited concrete network-client instantiation outside the composition root; depend on an abstraction (DIP)',
      );
    }
  }
}

// ------------------------------------------------------------------------------
// CC-11 : avoidable allocation on a hot path (advisory; also scans tests)
// ------------------------------------------------------------------------------
int braceDelta(String line) {
  var delta = 0;
  for (var index = 0; index < line.length; index++) {
    final character = line[index];
    if (character == '{') delta++;
    if (character == '}') delta--;
  }
  return delta;
}

void checkAllocations(String path, List<String> lines) {
  final copyConstructor = RegExp(r'\b(List|Map)\.from\s*\(');
  final spread = RegExp(r'\[[^\]]*\.\.\.');
  final loopHeader = RegExp(r'\b(for|while)\s*\(');
  const message =
      '[advisory] avoidable allocation on hot path; inspect without copying and return the original reference';
  var depth = 0;
  final loopDepths = <int>[];
  for (var index = 0; index < lines.length; index++) {
    final line = stripLineComment(lines[index]);
    final insideLoop = loopDepths.any((entry) => depth >= entry);
    final isLoopHeader = loopHeader.hasMatch(line);
    if (copyConstructor.hasMatch(line)) {
      emit('CC-11', path, index + 1, message);
    } else if ((insideLoop || isLoopHeader) && spread.hasMatch(line)) {
      emit('CC-11', path, index + 1, message);
    }
    if (isLoopHeader) loopDepths.add(depth + 1);
    depth += braceDelta(line);
    loopDepths.removeWhere((entry) => depth < entry);
  }
}

// ------------------------------------------------------------------------------
// Clean-code report / suite
// ------------------------------------------------------------------------------
void runAllChecks() {
  for (final path in productionFiles()) {
    final lines = readLines(path);
    checkIdentifierDiscipline(path, lines);
    checkLazyInit(path, lines);
    checkSecrets(path, lines);
    checkRawPrints(path, lines);
    checkSilentCatches(path, lines);
    checkUnimplemented(path, lines);
    checkServiceLocator(path, lines);
    checkNullableCollections(path, lines);
    checkConcreteClients(path, lines);
  }
  for (final path in allocationFiles()) {
    checkAllocations(path, readLines(path));
  }
}

int blockingTotal() {
  var total = 0;
  ccCounts.forEach((id, count) {
    if (count > 0 && ccBlocks(id) && count > ccThreshold(id)) total += count;
  });
  return total;
}

String cleanCodeBehavior() {
  return (profile == 'strict' && !isAdoptionMode()) ? 'blocking' : 'advisory';
}

void printCleanCodeSummary() {
  stdout.writeln(
    'Clean Code: $ccTotal violation(s) ($profile profile: ${cleanCodeBehavior()})',
  );
}

void runCleanCode({bool standardOverride = false}) {
  resolveProfile();
  if (standardOverride) profile = 'standard';
  runAllChecks();
  printCleanCodeSummary();
  if (blockingTotal() > 0) exitCode = 1;
}

// ------------------------------------------------------------------------------
// PT-01 : ponytail debt markers
// ------------------------------------------------------------------------------
void scanDebtMarkers() {
  final commentIntro = RegExp(r'(//|#|--|/\*|<!--)');
  for (final path in allSourceFiles()) {
    final lines = readLines(path);
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final marker = line.indexOf('ponytail:');
      if (marker < 0) continue;
      final before = line.substring(0, marker);
      if (!commentIntro.hasMatch(before)) continue;
      final reason = line.substring(marker + 'ponytail:'.length).trim();
      stdout.writeln('PT-01 $path:${index + 1} — $reason');
    }
  }
}

void runPonytailDebt() {
  resolveProfile();
  scanDebtMarkers();
}

void runPonytailAudit() {
  resolveProfile();
  scanDebtMarkers();
  final narration = RegExp(
    r'^\s*(//|#)\s*(increment|decrement|set|assign|call|return|loop|iterate|initialize|create|check|store)\s',
  );
  final delegation = RegExp(
    r'=>\s*[A-Za-z_][A-Za-z0-9_.]*\([^)]*\)[;]?\s*$',
  );
  final blockDelegation = RegExp(
    r'^\s*\{\s*return\s+[A-Za-z_][A-Za-z0-9_.]*\([^)]*\);\s*\}\s*$',
  );
  for (final path in productionFiles()) {
    final lines = readLines(path);
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (narration.hasMatch(line)) {
        stdout.writeln(
          '[advisory] [DELETE] $path:${index + 1} — narration comment restates the next line',
        );
      }
      if (delegation.hasMatch(line) || blockDelegation.hasMatch(line)) {
        stdout.writeln(
          '[advisory] [SHRINK] $path:${index + 1} — single-statement delegation; verify a caller justifies the layer',
        );
      }
    }
  }
}

// ------------------------------------------------------------------------------
// SK-01 .. SK-06 : skill activation invariants
// ------------------------------------------------------------------------------
String skillDirectory(String skill) => '.agents/skills/$skill';

String skillFile(String skill) => '${skillDirectory(skill)}/SKILL.md';

String frontmatterValue(String skill, String key) {
  final file = File(skillFile(skill));
  if (!file.existsSync()) return '';
  final lines = readLines(skillFile(skill));
  if (lines.isEmpty || lines.first.trimRight() != '---') return '';
  var value = '';
  var collecting = false;
  for (var index = 1; index < lines.length; index++) {
    final line = lines[index];
    if (line.trimRight() == '---') break;
    if (line.startsWith('$key:')) {
      value = line.substring(key.length + 1).trim();
      collecting = true;
      continue;
    }
    if (collecting) {
      if (line.startsWith(' ') || line.startsWith('\t')) {
        final trimmed = line.trim();
        if (value.isEmpty || RegExp(r'^[>|][-+]?$').hasMatch(value)) {
          value = trimmed;
        } else {
          value = '$value $trimmed';
        }
        continue;
      }
      collecting = false;
    }
  }
  return value.trim();
}

List<String> frontmatterKeys(String skill) {
  final keys = <String>[];
  final lines = readLines(skillFile(skill));
  if (lines.isEmpty || lines.first.trimRight() != '---') return keys;
  final keyPattern = RegExp(r'^[A-Za-z][A-Za-z0-9_-]*:');
  for (var index = 1; index < lines.length; index++) {
    final line = lines[index];
    if (line.trimRight() == '---') break;
    if (keyPattern.hasMatch(line)) {
      keys.add(line.substring(0, line.indexOf(':')));
    }
  }
  return keys;
}

void auditSkillsParity() {
  for (final skill in catalogSkills) {
    if (!File(skillFile(skill)).existsSync()) {
      emitSkill(
        'SK-01',
        skillDirectory(skill),
        0,
        'skill "$skill" is not listed in .agents/skills (parity required)',
      );
      continue;
    }
    if (File(agentsFile).existsSync() &&
        !readFileText(agentsFile).contains('`$skill`')) {
      emitSkill(
        'SK-01',
        agentsFile,
        0,
        'skill "$skill" is not listed in AGENTS.md (parity required)',
      );
    }
    if (File('README.md').existsSync() &&
        !readFileText('README.md').contains(skill)) {
      emitSkill(
        'SK-01',
        'README.md',
        0,
        'skill "$skill" is not listed in README.md (parity required)',
      );
    }
  }
}

void auditSkillsFrontmatter() {
  const allowedKeys = <String>{
    'name',
    'description',
    'argument-hint',
    'license',
    'metadata',
  };
  for (final skill in catalogSkills) {
    if (!File(skillFile(skill)).existsSync()) continue;
    if (isAdoptionMode() && isUserOwnedSkill(skill)) continue;
    final description = frontmatterValue(skill, 'description');
    final invalid = description.isEmpty ||
        !description.contains('Use when') ||
        !description.contains('Triggers on:') ||
        !description.contains('Chains into:') ||
        description.length < 150;
    if (invalid) {
      emitSkill('SK-02', skillFile(skill), 0, 'skill "$skill"$sk02MessageSuffix');
      continue;
    }
    if (frontmatterValue(skill, 'name') != skill) {
      emitSkill('SK-02', skillFile(skill), 0, 'skill "$skill"$sk02MessageSuffix');
      continue;
    }
    var unknownKey = false;
    for (final key in frontmatterKeys(skill)) {
      if (!allowedKeys.contains(key)) unknownKey = true;
    }
    if (unknownKey) {
      emitSkill('SK-02', skillFile(skill), 0, 'skill "$skill"$sk02MessageSuffix');
    }
    final body = readFileText(skillFile(skill));
    if (!RegExp(r'^## Territory', multiLine: true).hasMatch(body)) {
      emitSkill('SK-02', skillFile(skill), 0, 'skill "$skill"$sk02MessageSuffix');
    }
  }
}

void auditEntrypointParity() {
  for (final skill in catalogSkills) {
    if (File(llmsFile).existsSync() &&
        !readFileText(llmsFile).contains(skill)) {
      emitSkill('SK-03', llmsFile, 0, 'skill "$skill" is not listed in llms.txt');
    }
  }
  for (final entry in <String>[
    'README.md',
    'docs/INDEX.md',
    'docs/MANIFESTO.md',
  ]) {
    if (!File(entry).existsSync()) continue;
    if (!readFileText(entry).contains('llms.txt')) {
      emitSkill('SK-03', entry, 0, 'entrypoint $entry does not reference llms.txt');
    }
  }
}

class MatrixRow {
  MatrixRow(this.primary, this.triggers);

  final String primary;
  final String triggers;
}

List<MatrixRow> matrixRows() {
  final rows = <MatrixRow>[];
  final file = File(agentsFile);
  if (!file.existsSync()) return rows;
  var inside = false;
  final headingPattern = RegExp(r'^### 3\.3');
  for (final line in readLines(agentsFile)) {
    if (headingPattern.hasMatch(line)) {
      inside = true;
      continue;
    }
    if (inside && line.startsWith('#')) inside = false;
    if (!inside) continue;
    if (!line.startsWith('|')) continue;
    final cells = line.split('|');
    if (cells.length < 7) continue;
    final primary = cells[4].replaceAll(RegExp(r'[`\s]'), '');
    if (primary.isEmpty || primary == 'PrimarySkill') continue;
    rows.add(MatrixRow(primary, cells[3].trim()));
  }
  return rows;
}

void auditTriggerCoherence() {
  final quoted = RegExp(r'"([^"]+)"');
  final rows = matrixRows();
  for (final skill in catalogSkills) {
    MatrixRow? row;
    for (final candidate in rows) {
      if (candidate.primary == skill) {
        row = candidate;
        break;
      }
    }
    if (row == null) {
      emitSkill(
        'SK-04',
        agentsFile,
        0,
        'skill "$skill" has no dispatch-matrix row',
      );
      continue;
    }
    if (isAdoptionMode() && isUserOwnedSkill(skill)) continue;
    final frontmatter = frontmatterValue(skill, 'description').toLowerCase();
    for (final match in quoted.allMatches(row.triggers)) {
      final trigger = match.group(1)!.toLowerCase();
      if (trigger.isEmpty) continue;
      if (!frontmatter.contains(trigger)) {
        emitSkill(
          'SK-04',
          agentsFile,
          0,
          'trigger "$trigger" for skill "$skill" is missing from its frontmatter "Triggers on:"',
        );
      }
    }
  }
}

bool mirrorPresent(String dir) {
  return FileSystemEntity.typeSync(dir) != FileSystemEntityType.notFound;
}

String? mirrorOf(String dir, String skill) {
  if (!mirrorPresent(dir)) return null;
  final directoryEntry = '$dir/$skill/SKILL.md';
  if (File(directoryEntry).existsSync()) return directoryEntry;
  final markdownEntry = '$dir/$skill.md';
  if (File(markdownEntry).existsSync()) return markdownEntry;
  final cursorEntry = '$dir/$skill.mdc';
  if (File(cursorEntry).existsSync()) return cursorEntry;
  return null;
}

bool sameBytes(String left, String right) {
  try {
    final leftBytes = File(left).readAsBytesSync();
    final rightBytes = File(right).readAsBytesSync();
    if (leftBytes.length != rightBytes.length) return false;
    for (var index = 0; index < leftBytes.length; index++) {
      if (leftBytes[index] != rightBytes[index]) return false;
    }
    return true;
  } catch (_) {
    return false;
  }
}

int auditMirrorParity({bool report = true}) {
  var divergences = 0;
  for (final dir in mirrorDirectories) {
    if (!mirrorPresent(dir)) continue;
    for (final skill in catalogSkills) {
      final canonical = skillFile(skill);
      if (!File(canonical).existsSync()) continue;
      final mirror = mirrorOf(dir, skill);
      if (mirror == null || !sameBytes(canonical, mirror)) {
        divergences++;
        if (report) {
          emitSkill(
            'SK-05',
            dir,
            0,
            'harness mirror "$dir" diverges from .agents/skills for skill "$skill" (run: oaef skills sync-mirrors)',
          );
        }
      }
    }
  }
  return divergences;
}

// --- routing (docs/standards/governance_checks.md section 7.1) -----------------
const Set<String> territoryVocabulary = <String>{
  'features',
  'screens',
  'pages',
  'components',
  'shared',
  'ui',
  'core',
  'domain',
  'data',
  'infra',
  'test',
  'tests',
};

int commonPrefix(String left, String right) {
  final limit = left.length < right.length ? left.length : right.length;
  var position = 0;
  while (position < limit && left[position] == right[position]) {
    position++;
  }
  return position;
}

List<String> candidateForms(String token) {
  final forms = <String>[token];
  if (token.endsWith('ies')) {
    forms.add('${token.substring(0, token.length - 3)}y');
  }
  if (token.endsWith('es')) forms.add(token.substring(0, token.length - 2));
  if (token.endsWith('s')) forms.add(token.substring(0, token.length - 1));
  if (token.endsWith('ing')) forms.add(token.substring(0, token.length - 3));
  if (token.endsWith('ed')) forms.add(token.substring(0, token.length - 2));
  if (token.endsWith('ion')) forms.add(token.substring(0, token.length - 3));
  return forms;
}

bool wordMatch(String token, String word) {
  if (word.isEmpty) return false;
  for (final candidate in candidateForms(token)) {
    if (candidate == word) return true;
    if (candidate.length >= 4 && commonPrefix(candidate, word) >= 4) return true;
  }
  return false;
}

String routePrompt(String prompt) {
  final normalized = prompt.toLowerCase();
  final tokens = normalized.split(RegExp(r'[^a-z0-9-]+'));
  var best = 'ponytail';
  var bestScore = 0;
  for (final skill in catalogSkills) {
    var score = 0;
    for (final nameWord in skill.split('-')) {
      for (final token in tokens) {
        if (token.isEmpty) continue;
        if (wordMatch(token, nameWord)) {
          score += 5;
          break;
        }
      }
    }
    for (final trigger in skillTriggerTerms[skill]!) {
      final weight = trigger.length > 8 ? 8 : trigger.length;
      if (trigger.contains(' ')) {
        if (normalized.contains(trigger)) score += 3 + weight;
      } else {
        for (final token in tokens) {
          if (token.isEmpty) continue;
          if (wordMatch(token, trigger)) {
            score += 3 + weight;
            break;
          }
        }
      }
    }
    for (final token in tokens) {
      if (territoryVocabulary.contains(token)) score += 1;
    }
    if (score > bestScore) {
      bestScore = score;
      best = skill;
    }
  }
  return bestScore == 0 ? 'ponytail' : best;
}

String skillMeta(String skill) {
  switch (skill) {
    case 'ponytail':
    case 'collect-coverage':
    case 'run-static-analysis':
    case 'conformance-audit':
      return '—';
    default:
      return 'ponytail';
  }
}

List<String> recipesContaining(String skill) {
  return canonicalRecipes
      .where((recipe) => recipe.contains(skill))
      .toList();
}

void runSkillsRoute(String query) {
  final primary = routePrompt(query);
  stdout.writeln('Routing: "$query"');
  stdout.writeln(
    'Primary skill: $primary ${skillDirectory(primary)}/SKILL.md',
  );
  stdout.writeln('Meta-skill: ${skillMeta(primary)}');
  stdout.writeln('Recipes containing $primary:');
  for (final recipe in recipesContaining(primary)) {
    stdout.writeln('  $recipe');
  }
}

void runSkillsSelftest() {
  for (final fixture in routingFixtures) {
    final prompt = fixture[0];
    final expected = fixture[1];
    final got = routePrompt(prompt);
    if (got != expected) {
      emitSkill(
        'SK-06',
        agentsFile,
        0,
        'routing self-test failed: prompt "$prompt" resolved to "$got" but expected "$expected"',
      );
    }
  }
}

void runSkillsAudit({required bool selftest}) {
  resolveProfile();
  auditSkillsParity();
  auditSkillsFrontmatter();
  auditEntrypointParity();
  auditTriggerCoherence();
  auditMirrorParity();
  if (selftest) runSkillsSelftest();
  stdout.writeln('Skills: $skFailures finding(s)');
  if (skFailures > 0) exitCode = 1;
}

void runSkillsSyncMirrors({required bool checkOnly}) {
  resolveProfile();
  var synchronized = 0;
  for (final dir in mirrorDirectories) {
    if (!mirrorPresent(dir)) continue;
    if (FileSystemEntity.isLinkSync(dir)) {
      try {
        if (Link(dir).targetSync() == '../.agents/skills' &&
            Directory(dir).existsSync()) {
          stdout.writeln(
            '✅ $dir is a symlink to .agents/skills (parity by construction)',
          );
          continue;
        }
      } catch (_) {
        // Fall through to per-entry handling.
      }
    }
    if (!Directory(dir).existsSync()) continue;
    for (final skill in catalogSkills) {
      final canonical = skillFile(skill);
      if (!File(canonical).existsSync()) continue;
      final entry = mirrorOf(dir, skill);
      if (entry != null) {
        if (!checkOnly && !sameBytes(canonical, entry)) {
          try {
            File(canonical).copySync(entry);
            stdout.writeln(
              '🔧 $dir: repaired mirror for $skill (canonical catalog is authoritative)',
            );
            synchronized++;
          } catch (_) {
            // Preserve the entry when it cannot be written.
          }
        }
        continue;
      }
      if (checkOnly) continue;
      final target = '$dir/$skill';
      var linked = false;
      try {
        Link(target).createSync('../.agents/skills/$skill');
        linked =
            FileSystemEntity.typeSync(target) != FileSystemEntityType.notFound;
      } catch (_) {
        linked = false;
      }
      if (linked) {
        stdout.writeln('🔧 $dir: created mirror link for $skill');
      } else {
        try {
          copyDirectory(skillDirectory(skill), target);
          stdout.writeln('🔧 $dir: created mirror copy for $skill');
        } catch (_) {
          // Preserve user-owned content when the copy fails.
        }
      }
      synchronized++;
    }
  }
  skFailures = 0;
  final divergences = auditMirrorParity();
  if (checkOnly) {
    if (divergences > 0) {
      stdout.writeln('Mirrors: $divergences divergence(s) detected');
      exitCode = 1;
      return;
    }
    stdout.writeln('Mirrors: parity verified');
    return;
  }
  if (divergences > 0) {
    stdout.writeln(
      'Mirrors: $divergences divergence(s) remain (user-owned entries are preserved)',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('Mirrors: $synchronized entry(ies) synchronized, parity verified');
}

// ------------------------------------------------------------------------------
// lint / doctor / quality gate / sync / metrics
// ------------------------------------------------------------------------------
String normalizeMirror(String text) {
  return text
      .split('\n')
      .where((line) => !line.startsWith('<!--'))
      .join()
      .replaceAll(RegExp(r'\s+'), '');
}

const List<String> suppressionPatterns = <String>[
  r'//\s*ignore:',
  r'/\*\s*eslint-disable',
  r'//\s*@ts-ignore',
  r'#\s*noqa',
  r'#\s*type:\s*ignore',
  r'//nolint',
  r'#\[allow\(',
  r'@Suppress\(',
  r'//\s*swiftlint:disable',
  r'#pragma warning disable',
];

const List<String> suppressionAllowed = <String>[
  'deprecated_member_use',
  'type=lint',
  'SA1019',
  'CS0618',
  'CS0612',
  'DEPRECATION',
  'DeprecatedCallableAddReplaceWith',
  '#[allow(deprecated)',
  '@typescript-eslint/no-deprecated',
  'W1505',
  'B005',
  'deprecated-method',
  'type: ignore[deprecated]',
  'DO NOT EDIT',
  '@generated',
  '.g.',
];

const Set<String> secretScanExtensions = <String>{
  '.dart',
  '.ts',
  '.tsx',
  '.js',
  '.mjs',
  '.cjs',
  '.jsx',
  '.py',
  '.go',
  '.rs',
  '.kt',
  '.kts',
  '.swift',
  '.cs',
  '.sh',
  '.bash',
  '.yml',
  '.yaml',
  '.json',
};

List<String> walkAuditFiles() {
  final results = <String>[];
  const excludedDirs = <String>{
    '.git',
    'node_modules',
    'build',
    'dist',
    'docs',
    'tool',
    'templates',
    '.agents',
  };
  void visit(Directory directory) {
    List<FileSystemEntity> entities;
    try {
      entities = directory.listSync(followLinks: false);
    } catch (_) {
      return;
    }
    for (final entity in entities) {
      final name = entity.path.split('/').last;
      if (entity is Directory) {
        if (excludedDirs.contains(name)) continue;
        visit(entity);
      } else if (entity is File) {
        if (name.endsWith('.md')) continue;
        final dot = name.lastIndexOf('.');
        final extension = dot < 0 ? '' : name.substring(dot);
        if (extension.isNotEmpty && !secretScanExtensions.contains(extension)) {
          continue;
        }
        results.add(relativePath(entity.path));
      }
    }
  }

  visit(Directory('.'));
  results.sort();
  return results;
}

void runLint() {
  resolveProfile();
  var failed = false;

  if (File(agentsFile).existsSync() && File('CLAUDE.md').existsSync()) {
    if (normalizeMirror(readFileText(agentsFile)) !=
        normalizeMirror(readFileText('CLAUDE.md'))) {
      stderr.writeln(
        '❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run "oaef sync".',
      );
      failed = true;
    }
  }

  final secretPatterns = <RegExp>[
    RegExp(r'sk-[a-zA-Z0-9]{20,}'),
    RegExp(r'ghp_[a-zA-Z0-9]{20,}'),
    RegExp(r'AKIA[0-9A-Z]{16}'),
    RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
  ];
  if (Directory('docs').existsSync()) {
    for (final path in walkFiles('docs')) {
      final content = readFileText(path);
      if (content.isEmpty) continue;
      for (final pattern in secretPatterns) {
        if (pattern.hasMatch(content)) {
          stdout.writeln('$path: potential secret match');
          stderr.writeln('🚨 [SECURITY] Potential secret detected in docs/!');
          failed = true;
        }
      }
    }
  }

  final suppressionHits = <String>[];
  for (final path in walkAuditFiles()) {
    final lines = readLines(path);
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      var matched = false;
      for (final pattern in suppressionPatterns) {
        if (RegExp(pattern).hasMatch(line)) {
          matched = true;
          break;
        }
      }
      if (!matched) continue;
      if (suppressionAllowed.any(line.contains)) continue;
      suppressionHits.add('$path:${index + 1}: ${line.trim()}');
    }
  }
  if (suppressionHits.isNotEmpty) {
    stderr.writeln(
      '🚨 [LINT] Unallowed linter/compiler suppression comments detected:',
    );
    for (final hit in suppressionHits) {
      stderr.writeln(hit);
    }
    failed = true;
  }

  runAllChecks();
  auditSkillsParity();
  auditSkillsFrontmatter();
  auditEntrypointParity();
  auditTriggerCoherence();
  auditMirrorParity();
  runSkillsSelftest();
  if (skFailures > 0) failed = true;

  if (failed) {
    stderr.writeln('❌ LINT FAILED.');
    exitCode = 1;
    return;
  }
  stdout.writeln('✅ [LINT] All integrity and secret audits passed cleanly.');
}

void runConform() {
  resolveProfile();
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

  stdout.writeln('🩺 OAEF Conformance Audit (doctor)...');

  const requiredFiles = <String>[
    'AGENTS.md',
    'CLAUDE.md',
    'llms.txt',
    'oaef.context.json',
    'docs/INDEX.md',
    'docs/MANIFESTO.md',
    'docs/DESIGN.md',
    'docs/HARNESSES.md',
    'docs/standards/coding_patterns.md',
    'docs/standards/testing.md',
    'docs/standards/logging.md',
    'docs/standards/clean_code.md',
    'docs/standards/solid.md',
    'docs/standards/review.md',
    'docs/standards/analytics_and_telemetry.md',
    'docs/standards/governance_checks.md',
    'docs/wiki/metrics/baseline.json',
    'docs/wiki/memory/handoff.md',
    'docs/wiki/log.md',
    '.github/workflows/ci.yml',
    '.github/pull_request_template.md',
    '.gitignore',
    'CONTRIBUTING.md',
    'SECURITY.md',
  ];
  for (final entry in requiredFiles) {
    check(File(entry).existsSync(), '$entry present');
  }

  for (final skill in catalogSkills) {
    check(
      File(skillFile(skill)).existsSync(),
      '.agents/skills/$skill/SKILL.md present',
    );
  }

  check(
    File(agentsFile).existsSync() &&
        File('CLAUDE.md').existsSync() &&
        normalizeMirror(readFileText(agentsFile)) ==
            normalizeMirror(readFileText('CLAUDE.md')),
    'CLAUDE.md mirror parity verified',
  );

  final placeholders = RegExp(
    r'\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}',
  );
  var unresolved = false;
  for (final candidate in <String>[agentsFile, llmsFile]) {
    if (File(candidate).existsSync() &&
        placeholders.hasMatch(readFileText(candidate))) {
      unresolved = true;
    }
  }
  check(!unresolved, 'no unresolved template placeholders');

  check(
    auditMirrorParity(report: false) == 0,
    'harness skill mirror parity verified',
  );

  runSkillsSelftest();
  check(skFailures == 0, 'routing self-test (SK-06) passed');

  stdout.writeln('\n📊 Conformance: $passed/$checks checks passed');
  if (failed) exitCode = 1;
}

Future<void> runQualityGate({bool record = false}) async {
  resolveProfile();
  stdout.writeln('🔍 Initiating OAEF Quality Gate Audit (Dart & Flutter)...');

  final baseline = readJson(baselineFile);
  Map<String, dynamic> baselineRoot = <String, dynamic>{};
  if (baseline is Map && baseline['baseline'] is Map) {
    baselineRoot = Map<String, dynamic>.from(baseline['baseline'] as Map);
  }
  final coverageConfig =
      baselineRoot['coverage'] is Map
          ? Map<String, dynamic>.from(baselineRoot['coverage'] as Map)
          : <String, dynamic>{};
  final minLineCoverage =
      (coverageConfig['lines_min_percentage'] as num?)?.toDouble() ?? 95.0;
  final minBranchCoverage =
      (coverageConfig['branches_min_percentage'] as num?)?.toDouble() ?? 90.0;
  final sizingConfig =
      baselineRoot['clean_sizing'] is Map
          ? Map<String, dynamic>.from(baselineRoot['clean_sizing'] as Map)
          : <String, dynamic>{};
  final maxFileLines = (sizingConfig['file_max_lines'] as num?)?.toInt() ?? 300;

  stdout.writeln('ℹ️  Running test suite with coverage...');
  ProcessResult testResult;
  if (File('pubspec.yaml').existsSync()) {
    final pubspec = readFileText('pubspec.yaml');
    if (pubspec.contains('flutter:')) {
      testResult = await Process.run('flutter', <String>['test', '--coverage']);
    } else {
      testResult = await Process.run('dart', <String>[
        'test',
        '--coverage=coverage',
      ]);
    }
  } else {
    testResult = await Process.run('dart', <String>['test']);
  }

  if (testResult.exitCode != 0) {
    stderr
      ..writeln('❌ Tests failed:')
      ..writeln(testResult.stderr)
      ..writeln(testResult.stdout);
    exitCode = 1;
    return;
  }

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

  final linePercent =
      linesFound == 0 ? 100.0 : (linesHit / linesFound) * 100.0;
  stdout.writeln(
    '📊 Line Coverage: ${linePercent.toStringAsFixed(1)}% (Floor: $minLineCoverage%)',
  );

  final branchPercent =
      branchesFound == 0 ? 100.0 : (branchesHit / branchesFound) * 100.0;
  if (branchesFound > 0) {
    stdout.writeln(
      '📊 Branch Coverage: ${branchPercent.toStringAsFixed(1)}% (Floor: $minBranchCoverage%)',
    );
  }

  var oversizedFiles = 0;
  for (final path in productionFiles()) {
    final lineCount = readLines(path).length;
    if (lineCount > maxFileLines) {
      oversizedFiles++;
      stderr.writeln('⚠️  Oversized file (${lineCount}L > ${maxFileLines}L): $path');
    }
  }

  var passed = true;
  if (linePercent < minLineCoverage) {
    stderr.writeln(
      '❌ Quality Gate Failed: Line coverage $linePercent% < $minLineCoverage%',
    );
    passed = false;
  }
  if (branchesFound > 0 && branchPercent < minBranchCoverage) {
    stderr.writeln(
      '❌ Quality Gate Failed: Branch coverage $branchPercent% < $minBranchCoverage%',
    );
    passed = false;
  }
  if (oversizedFiles > 0) {
    stderr.writeln(
      '❌ Quality Gate Failed: $oversizedFiles oversized files detected',
    );
    passed = false;
  }

  if (!passed) {
    exitCode = 1;
    return;
  }

  runAllChecks();
  printCleanCodeSummary();
  if (profile == 'strict' && !isAdoptionMode() && ccTotal > 0) {
    stderr.writeln(
      '❌ Quality Gate Failed: $ccTotal clean-code violation(s).',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('\n🎉 Quality Gates PASSED!');
  if (record) {
    stdout.writeln(
      '📝 Recording session in metrics history and applying Monotonic Ratchet...',
    );
    if (linePercent > minLineCoverage) {
      coverageConfig['lines_min_percentage'] =
          double.parse(linePercent.toStringAsFixed(1));
      baselineRoot['coverage'] = coverageConfig;
      if (baseline is Map) {
        final updated = Map<String, dynamic>.from(baseline);
        updated['baseline'] = baselineRoot;
        File(baselineFile).writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(updated),
        );
      }
      stdout.writeln(
        '🔒 Monotonic Ratchet: Updated baseline floor to ${linePercent.toStringAsFixed(1)}%',
      );
    }
  }
}

void runSync() {
  if (!File(agentsFile).existsSync()) return;
  final content = readFileText(agentsFile);
  File('CLAUDE.md').writeAsStringSync(
    '<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n'
    '<!-- To modify rules, edit AGENTS.md and run "oaef sync". -->\n\n'
    '$content',
  );
  stdout.writeln('✅ Synchronized AGENTS.md -> CLAUDE.md');
}

void runMetrics() {
  if (File(baselineFile).existsSync()) {
    stdout.writeln(readFileText(baselineFile));
  }
}
