// ==============================================================================
// OAEF Governance Engine - Swift Runtime
// Implements docs/standards/governance_checks.md for the `swift` stack.
// Author: Felipe Carvalho | License: Apache 2.0
// Run with: swift tool/governance.swift <command>
// ==============================================================================

import Foundation

// ------------------------------------------------------------------------------
// Working directory: anchor to the repository root derived from the script path.
// ------------------------------------------------------------------------------
let arguments = CommandLine.arguments
if let scriptPath = arguments.first, scriptPath.contains("/"), scriptPath.hasSuffix("governance.swift") {
    let scriptURL = URL(fileURLWithPath: scriptPath).standardizedFileURL
    let rootURL = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
    FileManager.default.changeCurrentDirectoryPath(rootURL.path)
}

// ------------------------------------------------------------------------------
// Canonical catalog (byte-identical to AGENTS.md section 3)
// ------------------------------------------------------------------------------
let SKILLS = [
    "ponytail", "nullable-types", "architecture-audit", "screen-builder", "component-author",
    "responsive-layout", "ui-preview", "fix-layout-issues", "test-generator", "collect-coverage",
    "run-static-analysis", "code-review", "conformance-audit",
]

func skillTriggers(_ skill: String) -> [String] {
    switch skill {
    case "ponytail": return ["new", "refactor", "add", "simple", "minimal", "yagni", "dead code", "delete", "remove"]
    case "screen-builder": return ["screen", "page", "feature", "flow", "view"]
    case "component-author": return ["component", "widget", "button", "card", "modal"]
    case "ui-preview": return ["preview", "storybook", "isolated render"]
    case "responsive-layout": return ["responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport"]
    case "fix-layout-issues": return ["overflow", "unbounded", "layout", "layout broken", "render error"]
    case "test-generator": return ["test", "coverage", "mock", "fixture"]
    case "collect-coverage": return ["coverage", "lcov", "jacoco", "cobertura", "branches"]
    case "run-static-analysis": return ["analyze", "lint", "typecheck", "warnings"]
    case "nullable-types": return ["null", "optional", "nil", "guard clause", "defensive"]
    case "architecture-audit": return ["architecture", "boundary", "coupling", "cycle"]
    case "conformance-audit": return ["conformance", "doctor", "parity", "frontmatter"]
    case "code-review": return ["review", "pr", "checklist", "pre-pr"]
    default: return []
    }
}

func skillMeta(_ skill: String) -> String {
    switch skill {
    case "ponytail", "collect-coverage", "run-static-analysis", "conformance-audit": return "—"
    default: return "ponytail"
    }
}

let RECIPES = [
    "1. Feature / Screen Construction: ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review",
    "2. Reusable Component / Module Authoring: ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis",
    "3. Bug Fix / Root-Cause Remediation: ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis",
    "4. Domain, Data & Infrastructure: ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis",
    "5. Pre-Submission / Pull Request Cycle: collect-coverage -> run-static-analysis -> code-review",
]

let ROUTING_FIXTURES: [(prompt: String, expected: String)] = [
    ("create a new screen for the booking flow", "screen-builder"),
    ("build a reusable button component", "component-author"),
    ("the layout overflows on small screens", "fix-layout-issues"),
    ("add responsive breakpoints for tablet", "responsive-layout"),
    ("write unit tests for the payment service", "test-generator"),
    ("collect coverage and check the branch floor", "collect-coverage"),
    ("fix all analyzer warnings", "run-static-analysis"),
    ("this optional list parameter is always null", "nullable-types"),
    ("audit module boundaries and cyclic imports", "architecture-audit"),
    ("verify the repo conforms to the framework", "conformance-audit"),
    ("review my PR before I open it", "code-review"),
    ("remove the dead code and the 1-line use case", "ponytail"),
]

let MIRROR_DIRS = [".claude/skills", ".cursor/rules", ".windsurf/skills", ".cline/skills", ".grok/agents"]
let AGENTS_FILE = "AGENTS.md"
let LLMS_FILE = "llms.txt"
let BASELINE_FILE = "docs/wiki/metrics/baseline.json"
let ADOPTION_LEDGER = "docs/wiki/metrics/adoption.json"

// ------------------------------------------------------------------------------
// Small IO + regex helpers
// ------------------------------------------------------------------------------
func out(_ text: String) {
    FileHandle.standardOutput.write((text + "\n").data(using: .utf8)!)
}

func err(_ text: String) {
    FileHandle.standardError.write((text + "\n").data(using: .utf8)!)
}

func readText(_ path: String) -> String? {
    return try? String(contentsOfFile: path, encoding: .utf8)
}

func readLines(_ path: String) -> [String] {
    return (readText(path) ?? "").components(separatedBy: "\n")
}

func fileExists(_ path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path)
}

var regexCache: [String: NSRegularExpression] = [:]

func compiled(_ pattern: String, _ options: NSRegularExpression.Options = []) -> NSRegularExpression? {
    let key = pattern + "|" + String(options.rawValue)
    if let cached = regexCache[key] { return cached }
    guard let expression = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
    regexCache[key] = expression
    return expression
}

func firstGroup(_ pattern: String, _ text: String, group: Int = 1, options: NSRegularExpression.Options = []) -> String? {
    guard let expression = compiled(pattern, options) else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = expression.firstMatch(in: text, options: [], range: range) else { return nil }
    guard match.numberOfRanges > group, let captured = Range(match.range(at: group), in: text) else { return nil }
    return String(text[captured])
}

func test(_ pattern: String, _ text: String, options: NSRegularExpression.Options = []) -> Bool {
    guard let expression = compiled(pattern, options) else { return false }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return expression.firstMatch(in: text, options: [], range: range) != nil
}

func allGroups(_ pattern: String, _ text: String) -> [String] {
    guard let expression = compiled(pattern) else { return [] }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return expression.matches(in: text, options: [], range: range).compactMap { match in
        guard match.numberOfRanges > 1, let captured = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[captured])
    }
}

// ------------------------------------------------------------------------------
// Path helpers
// ------------------------------------------------------------------------------
func segments(_ path: String) -> [String] {
    return path.split(separator: "/").map(String.init)
}

func basename(_ path: String) -> String {
    return path.split(separator: "/").last.map(String.init) ?? path
}

let EXCLUDED_SEGMENTS: Set<String> = [
    ".git", ".github", ".agents", ".claude", ".cursor", ".windsurf", ".cline", ".grok", ".oaef",
    "node_modules", "vendor", "build", "dist", "target", "obj", "bin", "tool", "docs", "templates",
    "examples", "coverage", "generated", ".venv", "venv", "__pycache__", ".dart_tool", ".gradle", ".idea",
]

let TEST_SEGMENTS: Set<String> = ["test", "tests", "Tests", "__tests__", "spec", "specs", "androidTest", "iosTest"]

func isTestPath(_ path: String) -> Bool {
    for segment in segments(path) where TEST_SEGMENTS.contains(segment) { return true }
    let base = basename(path)
    let patterns = [#"^test_.*\.py$"#, #".*_test\..*$"#, #".*\.spec\..*$"#, #".*\.test\..*$"#, #".*Tests\.cs$"#, #".*Test\.kt$"#]
    for pattern in patterns where test(pattern, base) { return true }
    return false
}

func collectFiles() -> [String] {
    var files: [String] = []
    let manager = FileManager.default
    guard let enumerator = manager.enumerator(atPath: ".") else { return [] }
    for case let entry as String in enumerator {
        var isDirectory: ObjCBool = false
        manager.fileExists(atPath: entry, isDirectory: &isDirectory)
        let parts = segments(entry)
        if isDirectory.boolValue {
            if parts.contains(where: { EXCLUDED_SEGMENTS.contains($0) }) { enumerator.skipDescendants() }
            continue
        }
        if parts.contains(where: { EXCLUDED_SEGMENTS.contains($0) }) { continue }
        if test(#"\.[A-Za-z0-9]+$"#, entry) == false { continue }
        let base = basename(entry)
        if test(#"\.g\..*$"#, base) || test(#"_pb2\.py$"#, base) || test(#"_pb2_grpc\.py$"#, base)
            || test(#"\.min\.js$"#, base) || test(#"\.generated\..*$"#, base)
            || test(#"\.freezed\..*$"#, base) || test(#"\.designer\..*$"#, base) { continue }
        files.append(entry)
    }
    return files.sorted()
}

/// Swift production scope: `Sources/`, `Source/` and root-level `*.swift`.
func inProductionScope(_ path: String) -> Bool {
    if path.hasPrefix("Sources/") || path.hasPrefix("Source/") { return true }
    if !path.contains("/") { return true }
    return false
}

/// Full Swift scanning universe: production scope plus the `Tests/` tree (CC-11 only).
func inSwiftUniverse(_ path: String) -> Bool {
    if inProductionScope(path) || path.hasPrefix("Tests/") { return true }
    return false
}

var cachedAllFiles: [String]?
func allSwiftFiles() -> [String] {
    if let cached = cachedAllFiles { return cached }
    let result = collectFiles().filter { $0.hasSuffix(".swift") && inSwiftUniverse($0) }
    cachedAllFiles = result
    return result
}

func productionFiles() -> [String] {
    return allSwiftFiles().filter { inProductionScope($0) && !isTestPath($0) }
}

// ------------------------------------------------------------------------------
// Profile & adoption resolution
// ------------------------------------------------------------------------------
var PROFILE = "strict"
var ADOPTION_MODE = "install"

func jsonStringValue(_ key: String, _ file: String) -> String? {
    guard let text = readText(file) else { return nil }
    return firstGroup(#"\"\#(key)\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""#, text)
}

func resolveProfile(overrideStandard: Bool = false) {
    if let contextProfile = jsonStringValue("strictness", "oaef.context.json"), !contextProfile.isEmpty {
        PROFILE = contextProfile
    } else if let baselineProfile = jsonStringValue("profile", BASELINE_FILE), !baselineProfile.isEmpty {
        PROFILE = baselineProfile
    }
    ADOPTION_MODE = jsonStringValue("adoption_mode", "oaef.context.json") ?? "install"
    if ADOPTION_MODE.isEmpty { ADOPTION_MODE = "install" }
    if overrideStandard { PROFILE = "standard" }
}

func isAdoption() -> Bool {
    return ADOPTION_MODE != "install"
}

func userOwnedSkill(_ skill: String) -> Bool {
    guard let text = readText(ADOPTION_LEDGER) else { return false }
    guard let marker = text.range(of: "\"user_skills\"") else { return false }
    let after = text[marker.upperBound...]
    guard let end = after.firstIndex(of: "]") else { return false }
    return String(after[..<end]).contains("\"\(skill)\"")
}

func ccBlocking(_ id: String) -> Bool {
    if id == "CC-04" { return true }
    if id == "CC-11" { return false }
    if isAdoption() { return false }
    if PROFILE != "strict" { return false }
    return true
}

func ccThreshold(_ id: String) -> Int {
    let keys: [String: String] = [
        "CC-01": "max_single_letter_identifiers",
        "CC-02": "max_cryptic_abbreviations",
        "CC-03": "max_mutable_lazy_initializations",
        "CC-04": "max_dummy_keys",
        "CC-05": "max_raw_prints",
        "CC-06": "max_silent_catches",
        "CC-07": "max_service_locator_leaks",
        "CC-08": "max_nullable_collections",
        "CC-09": "max_unimplemented_placeholders",
        "CC-10": "max_concrete_client_instantiations",
    ]
    guard let key = keys[id] else { return 0 }
    guard let text = readText(BASELINE_FILE) else { return 0 }
    guard let value = firstGroup(#"\"\#(key)\"[[:space:]]*:[[:space:]]*([0-9][0-9.]*)"#, text) else { return 0 }
    return Int(Double(value) ?? 0)
}

// ------------------------------------------------------------------------------
// Finding emission
// ------------------------------------------------------------------------------
var ccCounts: [String: Int] = [:]
var ccTotal = 0
var skFailures = 0

let CC_IDS = ["CC-01", "CC-02", "CC-03", "CC-04", "CC-05", "CC-06", "CC-07", "CC-08", "CC-09", "CC-10", "CC-11"]

func emit(_ id: String, _ path: String, _ line: Int, _ message: String) {
    out("\(id) \(path):\(line) — \(message)")
    if id.hasPrefix("CC-") {
        ccCounts[id, default: 0] += 1
        ccTotal += 1
    }
}

func emitSkill(_ id: String, _ path: String, _ line: Int, _ message: String) {
    out("\(id) \(path):\(line) — \(message)")
    skFailures += 1
}

// ------------------------------------------------------------------------------
// CC-01 / CC-02 : identifier discipline
// ------------------------------------------------------------------------------
let CRYPTIC: Set<String> = [
    "cb", "fn", "res", "req", "btn", "val", "tmp", "ctx", "el", "usr", "mgr", "idx", "cnt",
    "buf", "str", "num", "doc", "elem", "curr", "prev",
]

func isCommentLine(_ line: String) -> Bool {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    return trimmed.hasPrefix("//") || trimmed.hasPrefix("/*") || trimmed.hasPrefix("*") || trimmed.hasPrefix("#!")
}

func identifierCandidate(_ line: String) -> (name: String, isLoop: Bool)? {
    if let name = firstGroup(#"\bfor[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]+in\b"#, line) {
        return (name, true)
    }
    if let name = firstGroup(#"catch[[:space:]]+let[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)"#, line) {
        return (name, false)
    }
    if let name = firstGroup(#"\b(?:let|var)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*[:=]"#, line) {
        return (name, false)
    }
    if let name = firstGroup(#"\{[[:space:]]*\(?[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*(?:,|\)|:)?[[:space:]]*in\b"#, line) {
        return (name, false)
    }
    return nil
}

func checkIdentifierDiscipline(_ file: String) {
    let lines = readLines(file)
    for (index, line) in lines.enumerated() {
        if isCommentLine(line) { continue }
        guard let candidate = identifierCandidate(line) else { continue }
        let name = candidate.name
        if name.count == 1 {
            if name == "_" { continue }
            if (name == "i" || name == "j") && candidate.isLoop { continue }
            emit("CC-01", file, index + 1, "prohibited single-letter identifier \"\(name)\"; use a descriptive name")
        } else if CRYPTIC.contains(name.lowercased()) {
            emit("CC-02", file, index + 1, "prohibited cryptic abbreviation \"\(name)\"; use the full identifier")
        }
    }
}

// ------------------------------------------------------------------------------
// CC-03 : mutable lazy initialization (documented no-op for Swift)
// ------------------------------------------------------------------------------
func checkLazyInit(_ file: String) {
    // Documented no-op: Swift has no idiomatic mutable lazy-init barrier in this catalog.
}

// ------------------------------------------------------------------------------
// CC-04 : hardcoded placeholder / secret
// ------------------------------------------------------------------------------
func checkSecrets(_ file: String) {
    let pattern = #"(dummy_|changeme|TODO_KEY|(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*"[^"]*"|(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*'[^']*')"#
    let exclusion = #"(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*"[^"]*(\\\(|\$|ProcessInfo|environment)[^"]*""#
    let lines = readLines(file)
    for (index, line) in lines.enumerated() {
        if test(pattern, line) && !test(exclusion, line) {
            emit("CC-04", file, index + 1, "prohibited hardcoded placeholder/secret; source it from configuration/environment")
        }
    }
}

// ------------------------------------------------------------------------------
// CC-05 : raw print / debug output
// ------------------------------------------------------------------------------
func checkRawPrints(_ file: String) {
    let pattern = #"(^|[^A-Za-z0-9_.])print\("#
    let lines = readLines(file)
    for (index, line) in lines.enumerated() {
        if isCommentLine(line) { continue }
        if test(pattern, line) {
            emit("CC-05", file, index + 1, "prohibited raw print/debug output in production code; use the logging interface")
        }
    }
}

// ------------------------------------------------------------------------------
// CC-06 : silent exception swallowing
// ------------------------------------------------------------------------------
func isBlankOrComment(_ line: String) -> Bool {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    return trimmed.isEmpty || trimmed.hasPrefix("//") || trimmed.hasPrefix("/*") || trimmed.hasPrefix("*")
}

func checkSilentCatches(_ file: String) {
    let lines = readLines(file)
    var index = 0
    while index < lines.count {
        let line = lines[index]
        if test(#"catch\b.*\{[[:space:]]*\}[[:space:]]*$"#, line) {
            emit("CC-06", file, index + 1, "prohibited silent exception swallowing; log with error+stack trace or rethrow")
            index += 1
            continue
        }
        if test(#"catch\b.*\{[[:space:]]*$"#, line) {
            var emptied = true
            var look = index + 1
            var steps = 0
            while look < lines.count && steps < 3 {
                let upcoming = lines[look]
                if isBlankOrComment(upcoming) { look += 1; steps += 1; continue }
                if upcoming.trimmingCharacters(in: .whitespaces).hasPrefix("}") { break }
                emptied = false
                break
            }
            if emptied {
                emit("CC-06", file, index + 1, "prohibited silent exception swallowing; log with error+stack trace or rethrow")
            }
            index += 1
            continue
        }
        index += 1
    }
}

// ------------------------------------------------------------------------------
// CC-07 : service-locator confinement
// ------------------------------------------------------------------------------
func cc07Allowed(_ path: String) -> Bool {
    if segments(path).contains(where: { $0.hasPrefix("App") }) { return true }
    if segments(path).contains("DI") { return true }
    if basename(path).hasSuffix("Assembly.swift") { return true }
    return false
}

func checkServiceLocator(_ file: String) {
    if cc07Allowed(file) { return }
    let tokens = ["Resolver.resolve(", "DependencyContainer.shared", "container.resolve("]
    let lines = readLines(file)
    for (index, line) in lines.enumerated() {
        if tokens.contains(where: { line.contains($0) }) {
            emit("CC-07", file, index + 1, "prohibited service-locator resolution outside the composition root/presentation layer; inject via constructor")
        }
    }
}

// ------------------------------------------------------------------------------
// CC-08 : nullable collection parameter
// ------------------------------------------------------------------------------
func checkNullableCollections(_ file: String) {
    let pattern = #"[A-Za-z_][A-Za-z0-9_]*[[:space:]]*:[[:space:]]*(\[[^\]]*\][[:space:]]*\?|Set<[^>]*>[[:space:]]*\?|Dictionary<[^>]*>[[:space:]]*\?)"#
    let lines = readLines(file)
    for (index, line) in lines.enumerated() {
        if test(pattern, line) {
            emit("CC-08", file, index + 1, "prohibited nullable collection parameter; default to a constant empty collection")
        }
    }
}

// ------------------------------------------------------------------------------
// CC-09 : unimplemented placeholder
// ------------------------------------------------------------------------------
func checkUnimplemented(_ file: String) {
    let tokens = [#"fatalError\("TODO"#, #"preconditionFailure\("#]
    let lines = readLines(file)
    for (index, line) in lines.enumerated() {
        if tokens.contains(where: { test($0, line) }) {
            emit("CC-09", file, index + 1, "prohibited unimplemented placeholder in production contract; implement the contract (LSP)")
        }
    }
}

// ------------------------------------------------------------------------------
// CC-10 : concrete network-client instantiation
// ------------------------------------------------------------------------------
func cc10Allowed(_ path: String) -> Bool {
    if segments(path).contains(where: { $0.hasPrefix("App") }) { return true }
    if segments(path).contains("DI") { return true }
    let base = basename(path)
    if base == "AppDelegate.swift" || base == "main.swift" || base == "Main.swift" { return true }
    if base.hasSuffix("Assembly.swift") { return true }
    if base.contains("CompositionRoot") { return true }
    return false
}

func checkConcreteClients(_ file: String) {
    if cc10Allowed(file) { return }
    let lines = readLines(file)
    for (index, line) in lines.enumerated() {
        if line.contains("URLSession.shared") {
            emit("CC-10", file, index + 1, "prohibited concrete network-client instantiation outside the composition root; depend on an abstraction (DIP)")
        }
    }
}

// ------------------------------------------------------------------------------
// CC-11 : avoidable allocation on a hot path (advisory)
// ------------------------------------------------------------------------------
func checkAllocations(_ file: String) {
    let lines = readLines(file)
    var loopStack: [Bool] = []
    for (index, line) in lines.enumerated() {
        if isCommentLine(line) { continue }
        var buffer = ""
        for character in line {
            if character == "{" {
                loopStack.append(test(#"\b(for|while)\b"#, buffer))
                buffer = ""
            } else if character == "}" {
                if !loopStack.isEmpty { loopStack.removeLast() }
                buffer = ""
            } else if character == "(" {
                if buffer.hasSuffix("Array") {
                    let prefix = Array(buffer)
                    let boundary = prefix.count - 5
                    let precededByWord = boundary > 0 && (prefix[boundary - 1].isLetter || prefix[boundary - 1].isNumber || prefix[boundary - 1] == "_" || prefix[boundary - 1] == ".")
                    if !precededByWord && loopStack.contains(true) {
                        emit("CC-11", file, index + 1, "[advisory] avoidable allocation on hot path; inspect without copying and return the original reference")
                    }
                }
                buffer.append(character)
            } else {
                buffer.append(character)
            }
        }
    }
}

// ------------------------------------------------------------------------------
// CC scan driver
// ------------------------------------------------------------------------------
func runCCChecks() {
    for file in productionFiles() {
        checkIdentifierDiscipline(file)
        checkLazyInit(file)
        checkSecrets(file)
        checkRawPrints(file)
        checkSilentCatches(file)
        checkServiceLocator(file)
        checkNullableCollections(file)
        checkUnimplemented(file)
        checkConcreteClients(file)
    }
    for file in allSwiftFiles() {
        checkAllocations(file)
    }
}

// ------------------------------------------------------------------------------
// PT-01 : ponytail debt markers
// ------------------------------------------------------------------------------
func scanDebtMarkers(_ emitLine: (String, Int, String) -> Void) {
    for file in allSwiftFiles() {
        let lines = readLines(file)
        for (index, line) in lines.enumerated() {
            guard line.contains("ponytail:") else { continue }
            if test(#"(^|[^A-Za-z])(//|///|/\*|#|--|<!--)[^\n]*ponytail:"#, line) {
                var reason = line
                if let range = reason.range(of: "ponytail:") { reason = String(reason[range.upperBound...]) }
                reason = reason.trimmingCharacters(in: .whitespaces)
                emitLine(file, index + 1, reason)
            }
        }
    }
}

func runPonytailDebt() {
    scanDebtMarkers { file, line, reason in
        out("PT-01 \(file):\(line) — \(reason)")
    }
}

func runPonytailAudit() {
    scanDebtMarkers { file, line, reason in
        out("PT-01 \(file):\(line) — \(reason)")
    }
    for file in productionFiles() {
        let lines = readLines(file)
        for (index, line) in lines.enumerated() {
            if test(#"^[[:space:]]*(//|///)[[:space:]]*(increment|decrement|set|assign|call|return|loop|iterate|initialize|create|check|store)[[:space:]]"#, line) {
                out("[advisory] [DELETE] \(file):\(index + 1) — narration comment restates the next line")
            }
            if test(#"=>[[:space:]]*[A-Za-z_][A-Za-z0-9_.]*\([^)]*\)[;]?[[:space:]]*$"#, line)
                || test(#"^[[:space:]]*\{[[:space:]]*return[[:space:]]+[A-Za-z_][A-Za-z0-9_.]*\([^)]*\);[[:space:]]*\}[[:space:]]*$"#, line) {
                out("[advisory] [SHRINK] \(file):\(index + 1) — single-statement delegation; verify a caller justifies the layer")
            }
        }
    }
}

// ------------------------------------------------------------------------------
// Frontmatter parsing
// ------------------------------------------------------------------------------
struct Frontmatter {
    var values: [String: String]
    var keys: [String]
    var bodyStart: Int
}

func skillDir(_ skill: String) -> String {
    return ".agents/skills/\(skill)"
}

func parseFrontmatter(_ path: String) -> Frontmatter? {
    guard let text = readText(path) else { return nil }
    let lines = text.components(separatedBy: "\n")
    guard let first = lines.first, first.trimmingCharacters(in: .whitespaces) == "---" else { return nil }
    var values: [String: String] = [:]
    var keys: [String] = []
    var currentKey: String?
    var index = 1
    while index < lines.count {
        let line = lines[index]
        if line.trimmingCharacters(in: .whitespaces) == "---" { index += 1; break }
        if let key = firstGroup(#"^([A-Za-z][A-Za-z0-9_-]*):"#, line) {
            let rest = firstGroup(#"^[A-Za-z][A-Za-z0-9_-]*:(.*)$"#, line) ?? ""
            keys.append(key)
            currentKey = key
            let trimmed = rest.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed == ">" || trimmed == ">-" || trimmed == "|" || trimmed == "|-" {
                values[key] = ""
            } else {
                values[key] = trimmed
            }
        } else if line.hasPrefix(" ") || line.hasPrefix("\t") {
            if let key = currentKey {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    let existing = values[key] ?? ""
                    values[key] = existing.isEmpty ? trimmed : existing + " " + trimmed
                }
            }
        } else {
            currentKey = nil
        }
        index += 1
    }
    return Frontmatter(values: values, keys: keys, bodyStart: index)
}

// ------------------------------------------------------------------------------
// SK-01 .. SK-06 : skill activation invariants
// ------------------------------------------------------------------------------
func auditSkillsParity() {
    for skill in SKILLS {
        let path = "\(skillDir(skill))/SKILL.md"
        if !fileExists(path) {
            emitSkill("SK-01", ".agents/skills/\(skill)", 0, "skill \"\(skill)\" is not listed in .agents/skills (parity required)")
            continue
        }
        if fileExists(AGENTS_FILE), let agents = readText(AGENTS_FILE), !agents.contains("`\(skill)`") {
            emitSkill("SK-01", AGENTS_FILE, 0, "skill \"\(skill)\" is not listed in AGENTS.md (parity required)")
        }
        if fileExists("README.md"), let readme = readText("README.md"), !readme.contains(skill) {
            emitSkill("SK-01", "README.md", 0, "skill \"\(skill)\" is not listed in README.md (parity required)")
        }
    }
}

func auditSkillsFrontmatter() {
    for skill in SKILLS {
        let path = "\(skillDir(skill))/SKILL.md"
        guard fileExists(path) else { continue }
        if isAdoption() && userOwnedSkill(skill) { continue }
        let message = "skill \"\(skill)\" frontmatter must declare \"Use when\", \"Triggers on:\" and \"Chains into:\" with >=150 characters and name==directory"
        guard let frontmatter = parseFrontmatter(path) else {
            emitSkill("SK-02", path, 0, message)
            continue
        }
        let description = frontmatter.values["description"] ?? ""
        if description.isEmpty || !description.contains("Use when") || !description.contains("Triggers on:")
            || !description.contains("Chains into:") || description.count < 150 {
            emitSkill("SK-02", path, 0, message)
            continue
        }
        if (frontmatter.values["name"] ?? "") != skill {
            emitSkill("SK-02", path, 0, message)
            continue
        }
        let allowed: Set<String> = ["name", "description", "argument-hint", "license", "metadata"]
        if frontmatter.keys.contains(where: { !allowed.contains($0) }) {
            emitSkill("SK-02", path, 0, message)
            continue
        }
        let lines = readLines(path)
        let hasTerritory = lines.dropFirst(frontmatter.bodyStart).contains { $0.hasPrefix("## Territory") }
        if !hasTerritory {
            emitSkill("SK-02", path, 0, message)
        }
    }
}

func auditEntrypointParity() {
    for skill in SKILLS {
        if fileExists(LLMS_FILE), let llms = readText(LLMS_FILE), !llms.contains(skill) {
            emitSkill("SK-03", LLMS_FILE, 0, "skill \"\(skill)\" is not listed in llms.txt")
        }
    }
    for entry in ["README.md", "docs/INDEX.md", "docs/MANIFESTO.md"] {
        guard fileExists(entry), let content = readText(entry) else { continue }
        if !content.contains("llms.txt") {
            emitSkill("SK-03", entry, 0, "entrypoint \(entry) does not reference llms.txt")
        }
    }
}

func dispatchMatrix() -> [(primary: String, triggers: [String])] {
    guard let text = readText(AGENTS_FILE) else { return [] }
    var rows: [(String, [String])] = []
    var inside = false
    for line in text.components(separatedBy: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("### 3.3") { inside = true; continue }
        if inside && trimmed.hasPrefix("#") { inside = false; continue }
        guard inside, trimmed.hasPrefix("|") else { continue }
        let cells = trimmed.split(separator: "|", omittingEmptySubsequences: false).map { String($0).trimmingCharacters(in: .whitespaces) }
        guard cells.count >= 6 else { continue }
        let triggersCell = cells[3]
        let primary = cells[4].replacingOccurrences(of: "`", with: "").replacingOccurrences(of: " ", with: "")
        if primary.isEmpty || primary == "PrimarySkill" { continue }
        let triggers = allGroups(#""([^"]+)""#, triggersCell).map { $0.lowercased() }
        rows.append((primary, triggers))
    }
    return rows
}

func auditTriggerCoherence() {
    let rows = dispatchMatrix()
    var byPrimary: [String: [String]] = [:]
    for row in rows where byPrimary[row.primary] == nil { byPrimary[row.primary] = row.triggers }
    for skill in SKILLS {
        guard let triggers = byPrimary[skill] else {
            emitSkill("SK-04", AGENTS_FILE, 0, "skill \"\(skill)\" has no dispatch-matrix row")
            continue
        }
        if isAdoption() && userOwnedSkill(skill) { continue }
        let description = (parseFrontmatter("\(skillDir(skill))/SKILL.md")?.values["description"] ?? "").lowercased()
        for trigger in triggers {
            if trigger.isEmpty { continue }
            if !description.contains(trigger) {
                emitSkill("SK-04", AGENTS_FILE, 0, "trigger \"\(trigger)\" for skill \"\(skill)\" is missing from its frontmatter \"Triggers on:\"")
            }
        }
    }
}

func mirrorOf(_ dir: String, _ skill: String) -> String? {
    if !fileExists(dir) { return nil }
    if fileExists("\(dir)/\(skill)/SKILL.md") { return "\(dir)/\(skill)/SKILL.md" }
    if fileExists("\(dir)/\(skill).md") { return "\(dir)/\(skill).md" }
    if fileExists("\(dir)/\(skill).mdc") { return "\(dir)/\(skill).mdc" }
    return nil
}

func sameContent(_ left: String, _ right: String) -> Bool {
    guard let leftData = FileManager.default.contents(atPath: left),
          let rightData = FileManager.default.contents(atPath: right) else { return false }
    return leftData == rightData
}

func auditMirrorParity() {
    for dir in MIRROR_DIRS {
        if !fileExists(dir) { continue }
        for skill in SKILLS {
            let canonical = "\(skillDir(skill))/SKILL.md"
            guard fileExists(canonical) else { continue }
            guard let mirror = mirrorOf(dir, skill), sameContent(canonical, mirror) else {
                emitSkill("SK-05", dir, 0, "harness mirror \"\(dir)\" diverges from .agents/skills for skill \"\(skill)\" (run: oaef skills sync-mirrors)")
                continue
            }
        }
    }
}

// ------------------------------------------------------------------------------
// Routing (docs/standards/governance_checks.md section 7.1)
// ------------------------------------------------------------------------------
let TERRITORY_WORDS: Set<String> = ["features", "screens", "pages", "components", "shared", "ui", "core", "domain", "data", "infra", "test", "tests"]

func tokenize(_ text: String) -> [String] {
    var tokens: [String] = []
    var current = ""
    for character in text.lowercased() {
        if (character >= "a" && character <= "z") || (character >= "0" && character <= "9") || character == "-" {
            current.append(character)
        } else if !current.isEmpty {
            tokens.append(current)
            current = ""
        }
    }
    if !current.isEmpty { tokens.append(current) }
    return tokens
}

func candidateForms(_ token: String) -> [String] {
    var forms = [token]
    if token.hasSuffix("ies") { forms.append(String(token.dropLast(3)) + "y") }
    if token.hasSuffix("es") { forms.append(String(token.dropLast(2))) }
    if token.hasSuffix("s") { forms.append(String(token.dropLast(1))) }
    if token.hasSuffix("ing") { forms.append(String(token.dropLast(3))) }
    if token.hasSuffix("ed") { forms.append(String(token.dropLast(2))) }
    if token.hasSuffix("ion") { forms.append(String(token.dropLast(3))) }
    return forms
}

func commonPrefix(_ left: String, _ right: String) -> Int {
    let leftCharacters = Array(left)
    let rightCharacters = Array(right)
    let limit = min(leftCharacters.count, rightCharacters.count)
    var index = 0
    while index < limit && leftCharacters[index] == rightCharacters[index] { index += 1 }
    return index
}

func wordMatch(_ token: String, _ word: String) -> Bool {
    if word.isEmpty { return false }
    for form in candidateForms(token) {
        if form == word { return true }
        if form.count >= 4 && commonPrefix(form, word) >= 4 { return true }
    }
    return false
}

func routePrompt(_ rawPrompt: String) -> String {
    let prompt = rawPrompt.lowercased()
    let tokens = tokenize(prompt).filter { !$0.isEmpty }
    var best = "ponytail"
    var bestScore = 0
    for skill in SKILLS {
        var score = 0
        for nameWord in skill.split(separator: "-").map(String.init) {
            for token in tokens {
                if wordMatch(token, nameWord) { score += 5; break }
            }
        }
        for trigger in skillTriggers(skill) {
            if trigger.isEmpty { continue }
            let weight = min(trigger.count, 8)
            if trigger.contains(" ") {
                if prompt.contains(trigger) { score += 3 + weight }
            } else {
                for token in tokens {
                    if wordMatch(token, trigger) { score += 3 + weight; break }
                }
            }
        }
        for token in tokens where TERRITORY_WORDS.contains(token) { score += 1 }
        if score > bestScore { bestScore = score; best = skill }
    }
    return bestScore == 0 ? "ponytail" : best
}

func runSkillsRoute(_ query: String) {
    let primary = routePrompt(query)
    out("Routing: \"\(query)\"")
    out("Primary skill: \(primary) .agents/skills/\(primary)/SKILL.md")
    out("Meta-skill: \(skillMeta(primary))")
    out("Recipes containing \(primary):")
    for recipe in RECIPES where recipe.contains(primary) {
        out("  \(recipe)")
    }
}

func runSkillsSelftest() {
    for fixture in ROUTING_FIXTURES {
        let got = routePrompt(fixture.prompt)
        if got != fixture.expected {
            emitSkill("SK-06", AGENTS_FILE, 0, "routing self-test failed: prompt \"\(fixture.prompt)\" resolved to \"\(got)\" but expected \"\(fixture.expected)\"")
        }
    }
}

func runSkillsAudit(selftest: Bool) {
    resolveProfile()
    auditSkillsParity()
    auditSkillsFrontmatter()
    auditEntrypointParity()
    auditTriggerCoherence()
    auditMirrorParity()
    if selftest { runSkillsSelftest() }
    out("Skills: \(skFailures) finding(s)")
    if skFailures > 0 { exit(1) }
}

func runSkillsSyncMirrors(checkOnly: Bool) {
    resolveProfile()
    var repaired = 0
    let manager = FileManager.default
    for dir in MIRROR_DIRS {
        if !fileExists(dir) { continue }
        if let target = try? manager.destinationOfSymbolicLink(atPath: dir), target == "../.agents/skills" {
            out("✅ \(dir) is a symlink to .agents/skills (parity by construction)")
            continue
        }
        var isDirectory: ObjCBool = false
        guard manager.fileExists(atPath: dir, isDirectory: &isDirectory), isDirectory.boolValue else { continue }
        for skill in SKILLS {
            let canonical = "\(skillDir(skill))/SKILL.md"
            guard fileExists(canonical) else { continue }
            if let entry = mirrorOf(dir, skill) {
                if !checkOnly && !sameContent(canonical, entry) {
                    try? manager.removeItem(atPath: entry)
                    try? manager.copyItem(atPath: canonical, toPath: entry)
                    out("🔧 \(dir): repaired mirror for \(skill) (canonical catalog is authoritative)")
                    repaired += 1
                }
                continue
            }
            if checkOnly { continue }
            let target = "\(dir)/\(skill)"
            try? manager.createSymbolicLink(atPath: target, withDestinationPath: "../.agents/skills/\(skill)")
            if fileExists(target) {
                out("🔧 \(dir): created mirror link for \(skill)")
            } else {
                try? manager.removeItem(atPath: target)
                try? manager.copyItem(atPath: skillDir(skill), toPath: target)
                out("🔧 \(dir): created mirror copy for \(skill)")
            }
            repaired += 1
        }
    }
    skFailures = 0
    auditMirrorParity()
    if checkOnly {
        if skFailures > 0 {
            out("Mirrors: \(skFailures) divergence(s) detected")
            exit(1)
        }
        out("Mirrors: parity verified")
        return
    }
    if skFailures > 0 {
        out("Mirrors: \(skFailures) divergence(s) remain (user-owned entries are preserved)")
        exit(1)
    }
    out("Mirrors: \(repaired) entry(ies) synchronized, parity verified")
}

// ------------------------------------------------------------------------------
// lint / doctor / quality gate / sync / metrics
// ------------------------------------------------------------------------------
func normalizeMirror(_ path: String) -> String {
    let text = readText(path) ?? ""
    let withoutComments = text.components(separatedBy: "\n").filter { !$0.hasPrefix("<!--") }.joined()
    return withoutComments.components(separatedBy: .whitespacesAndNewlines).joined()
}

func runLint() {
    resolveProfile()
    var failed = false
    if fileExists(AGENTS_FILE) && fileExists("CLAUDE.md") {
        if normalizeMirror(AGENTS_FILE) != normalizeMirror("CLAUDE.md") {
            err("❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run \"oaef sync\".")
            failed = true
        }
    }

    let secretPattern = #"(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)"#
    var secretFound = false
    for file in collectFiles() where file.hasPrefix("docs/") {
        guard let content = readText(file) else { continue }
        if test(secretPattern, content) { secretFound = true }
    }
    if secretFound {
        err("🚨 [SECURITY] Potential secret detected in docs/!")
        failed = true
    }

    let suppressionPattern = #"(//[[:space:]]*ignore:|/\*[[:space:]]*eslint-disable|//[[:space:]]*@ts-ignore|#[[:space:]]*noqa|#[[:space:]]*type:[[:space:]]*ignore|//nolint|#\[allow\(|@Suppress\(|//[[:space:]]*swiftlint:disable|#pragma warning disable)"#
    let allowedSuppression = #"(deprecated_member_use|type=lint|SA1019|CS0618|CS0612|DEPRECATION|DeprecatedCallableAddReplaceWith|#\[allow\(deprecated\)|@typescript-eslint/no-deprecated|W1505|B005|deprecated-method|DO NOT EDIT|@generated|\.g\.)"#
    var suppressions: [String] = []
    for file in collectFiles() where !file.hasSuffix(".md") {
        let lines = readLines(file)
        for (index, line) in lines.enumerated() {
            if test(suppressionPattern, line) && !test(allowedSuppression, line) {
                suppressions.append("\(file):\(index + 1):\(line)")
            }
        }
    }
    if !suppressions.isEmpty {
        err("🚨 [LINT] Unallowed linter/compiler suppression comments detected:")
        for finding in suppressions { err(finding) }
        failed = true
    }

    runCCChecks()
    auditSkillsParity()
    auditSkillsFrontmatter()
    auditEntrypointParity()
    auditTriggerCoherence()
    auditMirrorParity()
    runSkillsSelftest()
    if skFailures > 0 { failed = true }

    if failed {
        err("❌ LINT FAILED.")
        exit(1)
    }
    out("✅ [LINT] All integrity and secret audits passed cleanly.")
}

func runConform() {
    resolveProfile()
    var checks = 0
    var passed = 0
    var failed = false
    let requiredFiles = [
        "AGENTS.md", "CLAUDE.md", "llms.txt", "oaef.context.json", "docs/INDEX.md", "docs/MANIFESTO.md",
        "docs/DESIGN.md", "docs/HARNESSES.md", "docs/standards/coding_patterns.md", "docs/standards/testing.md",
        "docs/standards/logging.md", "docs/standards/clean_code.md", "docs/standards/solid.md",
        "docs/standards/review.md", "docs/standards/analytics_and_telemetry.md", "docs/standards/governance_checks.md",
        "docs/wiki/metrics/baseline.json", "docs/wiki/memory/handoff.md", "docs/wiki/log.md",
        ".github/workflows/ci.yml", ".github/pull_request_template.md", ".gitignore", "CONTRIBUTING.md", "SECURITY.md",
    ]
    out("🩺 OAEF Conformance Audit (doctor)...")
    for entry in requiredFiles {
        checks += 1
        if fileExists(entry) {
            passed += 1
            out("✅ \(entry) present")
        } else {
            err("❌ \(entry) missing")
            failed = true
        }
    }
    for skill in SKILLS {
        checks += 1
        if fileExists("\(skillDir(skill))/SKILL.md") {
            passed += 1
            out("✅ .agents/skills/\(skill)/SKILL.md present")
        } else {
            err("❌ .agents/skills/\(skill)/SKILL.md missing")
            failed = true
        }
    }
    checks += 1
    if fileExists(AGENTS_FILE) && fileExists("CLAUDE.md") && normalizeMirror(AGENTS_FILE) == normalizeMirror("CLAUDE.md") {
        passed += 1
        out("✅ CLAUDE.md mirror parity verified")
    } else {
        err("❌ CLAUDE.md mirror parity failed (run oaef sync)")
        failed = true
    }
    checks += 1
    var placeholderFound = false
    for candidate in [AGENTS_FILE, LLMS_FILE] {
        if let content = readText(candidate), test(#"\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}"#, content) {
            placeholderFound = true
        }
    }
    if placeholderFound {
        err("❌ unresolved template placeholders found")
        failed = true
    } else {
        passed += 1
        out("✅ no unresolved template placeholders")
    }
    runSkillsSelftest()
    checks += 1
    if skFailures == 0 {
        passed += 1
        out("✅ routing self-test (SK-06) passed")
    } else {
        err("❌ routing self-test (SK-06) failed")
        failed = true
    }
    out("\n📊 Conformance: \(passed)/\(checks) checks passed")
    if failed { exit(1) }
}

func runQualityGate() {
    resolveProfile()
    out("🔍 Initiating OAEF Quality Gate Audit (Swift)...")
    var oversized = 0
    for file in productionFiles() {
        let lines = readLines(file).count
        if lines > 300 {
            err("⚠️  Oversized file (\(lines)L > 300L): \(file)")
            oversized += 1
        }
    }
    if oversized > 0 {
        err("❌ Quality Gate Failed: \(oversized) oversized files detected.")
        exit(1)
    }
    runCCChecks()
    let behavior = ccBlocking("CC-01") ? "blocking" : "advisory"
    out("Clean Code: \(ccTotal) violation(s) (\(PROFILE) profile: \(behavior))")
    if PROFILE == "strict" && !isAdoption() && ccTotal > 0 {
        err("❌ Quality Gate Failed: \(ccTotal) clean-code violation(s).")
        exit(1)
    }
    out("🎉 Quality Gates PASSED!")
}

func runCleanCode(overrideStandard: Bool) {
    resolveProfile(overrideStandard: overrideStandard)
    runCCChecks()
    var blockingTotal = 0
    for id in CC_IDS {
        let count = ccCounts[id] ?? 0
        if count <= 0 { continue }
        if ccBlocking(id) && count > ccThreshold(id) {
            blockingTotal += count
        }
    }
    let behavior = ccBlocking("CC-01") ? "blocking" : "advisory"
    out("Clean Code: \(ccTotal) violation(s) (\(PROFILE) profile: \(behavior))")
    if blockingTotal > 0 { exit(1) }
}

func runSync() {
    guard let agents = readText(AGENTS_FILE) else { return }
    let banner = "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n"
        + "<!-- To modify rules, edit AGENTS.md and run 'oaef sync'. -->\n\n"
    let content = banner + agents
    try? content.write(toFile: "CLAUDE.md", atomically: true, encoding: .utf8)
    out("✅ Synchronized AGENTS.md -> CLAUDE.md")
}

func runMetrics() {
    if let content = readText(BASELINE_FILE) {
        FileHandle.standardOutput.write(content.data(using: .utf8)!)
        if !content.hasSuffix("\n") { out("") }
    }
}

// ------------------------------------------------------------------------------
// CLI
// ------------------------------------------------------------------------------
func usage() {
    out("""
    OAEF Governance Tool (Swift Engine)
    Usage: swift tool/governance.swift <command>
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
      sync                      Synchronize AGENTS.md to CLAUDE.md
    """)
}

let command = arguments.count > 1 ? arguments[1] : ""
let rest = arguments.count > 2 ? Array(arguments.dropFirst(2)) : []

switch command {
case "quality-gate", "audit":
    runQualityGate()
case "clean-code", "governance-check":
    runCleanCode(overrideStandard: rest.contains("--standard"))
case "ponytail-debt", "ponytail":
    runPonytailDebt()
case "ponytail-audit":
    runPonytailAudit()
case "skills-audit":
    runSkillsAudit(selftest: rest.contains("--selftest"))
case "skills-route":
    runSkillsRoute(rest.joined(separator: " "))
case "skills":
    let subcommand = rest.first ?? ""
    switch subcommand {
    case "sync-mirrors":
        runSkillsSyncMirrors(checkOnly: rest.contains("--check"))
    case "audit":
        runSkillsAudit(selftest: rest.contains("--selftest"))
    case "route":
        runSkillsRoute(rest.dropFirst().joined(separator: " "))
    default:
        usage()
        exit(1)
    }
case "lint":
    runLint()
case "conform", "doctor":
    runConform()
case "metrics":
    runMetrics()
case "sync":
    runSync()
default:
    usage()
    exit(1)
}
