// ==============================================================================
// OAEF Native Governance Engine — Kotlin Multiplatform
// Implements docs/standards/governance_checks.md for the `kotlin-multiplatform` stack.
// Invocation: kotlinc -script tool/governance.main.kts <command> [args]
// Author: Felipe Carvalho | License: Apache 2.0
// ==============================================================================

import java.io.File
import java.nio.file.Files
import java.nio.file.Paths

// ------------------------------------------------------------------------------
// Constants and mutable audit state (initialized before the command dispatch)
// ------------------------------------------------------------------------------
val CONTEXT_FILE = "oaef.context.json"
val BASELINE_FILE = "docs/wiki/metrics/baseline.json"
val ADOPTION_LEDGER = "docs/wiki/metrics/adoption.json"
val AGENTS_FILE = "AGENTS.md"
val LLMS_FILE = "llms.txt"

val EXCLUDED_SEGMENTS = listOf(
    ".git", ".github", ".agents", ".claude", ".cursor", ".windsurf", ".cline", ".grok",
    ".oaef", "node_modules", "vendor", "build", "dist", "target", "obj", "bin", "tool",
    "docs", "templates", "examples", "coverage", "generated", ".venv", "venv",
    "__pycache__", ".dart_tool", ".gradle", ".idea"
)

val TEST_SEGMENTS = listOf(
    "test", "tests", "__tests__", "spec", "specs", "androidTest", "iosTest",
    "commonTest", "androidUnitTest", "jvmTest", "desktopTest"
)

// Production scope of the `kotlin` stack (docs/standards/governance_checks.md section 2.1)
val PRODUCTION_ROOTS = listOf("src/main", "src/commonMain", "src/androidMain", "src/iosMain")

var profile = "strict"
var adoptionMode = "install"
var ccTotal = 0
var skillFailures = 0
val ccCounts = mutableMapOf<String, Int>()

// `kotlinc -script` consumes leading-dash flags itself, so bin/oaef and scripts/self-audit.sh pass the
// command line through OAEF_GOVERNANCE_ARGS; direct invocation still works through the script `args`.
val rawArgs: List<String> = if (args.isNotEmpty()) {
    args.toList()
} else {
    (System.getenv("OAEF_GOVERNANCE_ARGS") ?: "").split(" ").filter { it.isNotBlank() }
}
val command = rawArgs.firstOrNull() ?: ""
val cliArgs = rawArgs.drop(1)

when (command) {
    "quality-gate", "audit" -> runQualityGate()
    "clean-code", "governance-check" -> runCleanCode(cliArgs.contains("--standard"))
    "ponytail-debt" -> runPonytailDebt()
    "ponytail-audit" -> runPonytailAudit()
    "skills-audit" -> runSkillsAudit(cliArgs.firstOrNull() == "--selftest")
    "skills-route" -> runSkillsRoute(cliArgs.joinToString(" "))
    "skills" -> when (cliArgs.firstOrNull() ?: "audit") {
        "sync-mirrors" -> runSkillsSyncMirrors(cliArgs.getOrNull(1) == "--check")
        "audit" -> runSkillsAudit(cliArgs.getOrNull(1) == "--selftest")
        "route" -> runSkillsRoute(cliArgs.drop(1).joinToString(" "))
        else -> {
            usage()
            System.exit(1)
        }
    }
    "lint" -> runLint()
    "conform", "doctor" -> runConform()
    "metrics" -> runMetrics()
    "sync" -> runSync()
    else -> {
        usage()
        System.exit(1)
    }
}

// ------------------------------------------------------------------------------
// Canonical catalog (must stay byte-identical to AGENTS.md section 3)
// ------------------------------------------------------------------------------
fun skillCatalog(): List<String> = listOf(
    "ponytail", "nullable-types", "architecture-audit", "screen-builder",
    "component-author", "responsive-layout", "ui-preview", "fix-layout-issues",
    "test-generator", "collect-coverage", "run-static-analysis", "code-review",
    "conformance-audit"
)

fun skillTriggers(skill: String): String = when (skill) {
    "ponytail" -> "new|refactor|add|simple|minimal|yagni|dead code|delete|remove"
    "screen-builder" -> "screen|page|feature|flow|view"
    "component-author" -> "component|widget|button|card|modal"
    "ui-preview" -> "preview|storybook|isolated render"
    "responsive-layout" -> "responsive|adaptive|breakpoint|tablet|foldable|viewport"
    "fix-layout-issues" -> "overflow|unbounded|layout|layout broken|render error"
    "test-generator" -> "test|coverage|mock|fixture"
    "collect-coverage" -> "coverage|lcov|jacoco|cobertura|branches"
    "run-static-analysis" -> "analyze|lint|typecheck|warnings"
    "nullable-types" -> "null|optional|nil|guard clause|defensive"
    "architecture-audit" -> "architecture|boundary|coupling|cycle"
    "conformance-audit" -> "conformance|doctor|parity|frontmatter"
    "code-review" -> "review|pr|checklist|pre-pr"
    else -> ""
}

fun skillMeta(skill: String): String = when (skill) {
    "ponytail", "collect-coverage", "run-static-analysis", "conformance-audit" -> "—"
    else -> "ponytail"
}

fun routingFixtures(): List<String> = listOf(
    "create a new screen for the booking flow|screen-builder",
    "build a reusable button component|component-author",
    "the layout overflows on small screens|fix-layout-issues",
    "add responsive breakpoints for tablet|responsive-layout",
    "write unit tests for the payment service|test-generator",
    "collect coverage and check the branch floor|collect-coverage",
    "fix all analyzer warnings|run-static-analysis",
    "this optional list parameter is always null|nullable-types",
    "audit module boundaries and cyclic imports|architecture-audit",
    "verify the repo conforms to the framework|conformance-audit",
    "review my PR before I open it|code-review",
    "remove the dead code and the 1-line use case|ponytail"
)

fun recipes(): List<String> = listOf(
    "1. Feature / Screen Construction: ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review",
    "2. Reusable Component / Module Authoring: ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis",
    "3. Bug Fix / Root-Cause Remediation: ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis",
    "4. Domain, Data & Infrastructure: ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis",
    "5. Pre-Submission / Pull Request Cycle: collect-coverage -> run-static-analysis -> code-review"
)

fun mirrorDirs(): List<String> = listOf(
    ".claude/skills", ".cursor/rules", ".windsurf/skills", ".cline/skills", ".grok/agents"
)

// ------------------------------------------------------------------------------
// Profile & adoption resolution
// ------------------------------------------------------------------------------
fun jsonStringValue(file: String, key: String): String {
    val target = File(file)
    if (!target.exists()) return ""
    val match = Regex("\"" + key + "\"\\s*:\\s*\"([^\"]*)\"").find(target.readText())
    return match?.groupValues?.get(1) ?: ""
}

fun resolveProfile() {
    val contextStrictness = jsonStringValue(CONTEXT_FILE, "strictness")
    if (contextStrictness.isNotEmpty()) {
        profile = contextStrictness
    } else {
        val baselineProfile = jsonStringValue(BASELINE_FILE, "profile")
        if (baselineProfile.isNotEmpty()) profile = baselineProfile
    }
    val mode = jsonStringValue(CONTEXT_FILE, "adoption_mode")
    adoptionMode = if (mode.isEmpty()) "install" else mode
}

fun isAdoption(): Boolean = adoptionMode != "install"

fun ccBlocking(id: String): Boolean {
    if (id == "CC-11") return false
    if (id == "CC-04") return true
    if (isAdoption()) return false
    return profile == "strict"
}

fun ccThreshold(id: String): Double {
    val key = when (id) {
        "CC-01" -> "max_single_letter_identifiers"
        "CC-02" -> "max_cryptic_abbreviations"
        "CC-03" -> "max_mutable_lazy_initializations"
        "CC-04" -> "max_dummy_keys"
        "CC-05" -> "max_raw_prints"
        "CC-06" -> "max_silent_catches"
        "CC-07" -> "max_service_locator_leaks"
        "CC-08" -> "max_nullable_collections"
        "CC-09" -> "max_unimplemented_placeholders"
        "CC-10" -> "max_concrete_client_instantiations"
        else -> ""
    }
    if (key.isEmpty()) return 0.0
    val baseline = File(BASELINE_FILE)
    if (!baseline.exists()) return 0.0
    val match = Regex("\"" + key + "\"\\s*:\\s*([0-9][0-9.]*)").find(baseline.readText())
    val raw = match?.groupValues?.get(1) ?: ""
    if (raw.isEmpty()) return 0.0
    return raw.toDoubleOrNull() ?: 0.0
}

// ------------------------------------------------------------------------------
// File discovery & scope
// ------------------------------------------------------------------------------
fun normalizedPath(target: File): String = target.path.replace('\\', '/').removePrefix("./")

fun pathSegments(path: String): List<String> = path.split('/').filter { it.isNotEmpty() }

fun containsSequence(segments: List<String>, sequence: String): Boolean {
    val wanted = sequence.split('/')
    if (wanted.isEmpty() || wanted.size > segments.size) return false
    for (start in 0..(segments.size - wanted.size)) {
        var matched = true
        for (offset in wanted.indices) {
            if (segments[start + offset] != wanted[offset]) {
                matched = false
                break
            }
        }
        if (matched) return true
    }
    return false
}

fun hasPathSegment(path: String, segment: String): Boolean = pathSegments(path).contains(segment)

fun isExcludedPath(path: String): Boolean {
    val segments = pathSegments(path)
    for (segment in segments) {
        if (EXCLUDED_SEGMENTS.contains(segment)) return true
    }
    val name = segments.lastOrNull() ?: ""
    if (name.contains(".g.") || name.contains(".generated.")) return true
    if (name.contains(".freezed.") || name.contains(".designer.")) return true
    if (name.endsWith("_pb2.py") || name.endsWith("_pb2_grpc.py") || name.endsWith(".min.js")) return true
    return false
}

fun isTestPath(path: String): Boolean {
    val segments = pathSegments(path)
    for (segment in segments) {
        if (TEST_SEGMENTS.contains(segment)) return true
    }
    val name = segments.lastOrNull() ?: ""
    if (name.endsWith("Test.kt") || name.endsWith("Tests.kt") || name.endsWith("Test.kts")) return true
    if (Regex(".*[._](test|spec)\\.[^.]+$").matches(name)) return true
    return false
}

fun isKotlinSource(path: String): Boolean = path.endsWith(".kt") || path.endsWith(".kts")

fun collectSourceFiles(): List<File> {
    val collected = mutableListOf<File>()
    fun visit(directory: File) {
        val children = directory.listFiles() ?: return
        for (child in children) {
            if (EXCLUDED_SEGMENTS.contains(child.name)) continue
            if (child.isDirectory) {
                visit(child)
            } else if (child.isFile) {
                val relative = normalizedPath(child)
                if (!isKotlinSource(relative)) continue
                if (isExcludedPath(relative)) continue
                collected.add(child)
            }
        }
    }
    visit(File("."))
    return collected.sortedBy { normalizedPath(it) }
}

fun isProductionPath(path: String): Boolean {
    val segments = pathSegments(path)
    var insideRoot = false
    for (root in PRODUCTION_ROOTS) {
        if (containsSequence(segments, root)) {
            insideRoot = true
            break
        }
    }
    if (!insideRoot) return false
    return !isTestPath(path)
}

fun productionFiles(): List<File> = collectSourceFiles().filter { isProductionPath(normalizedPath(it)) }

// ------------------------------------------------------------------------------
// Line sanitization (comments and string literals are never findings)
// ------------------------------------------------------------------------------
fun sanitizeSource(text: String): List<String> {
    val sanitized = mutableListOf<String>()
    var inBlockComment = false
    for (rawLine in text.split("\n")) {
        val builder = StringBuilder()
        var index = 0
        var inString = false
        var inChar = false
        while (index < rawLine.length) {
            val current = rawLine[index]
            val next = if (index + 1 < rawLine.length) rawLine[index + 1] else '\u0000'
            if (inBlockComment) {
                if (current == '*' && next == '/') {
                    inBlockComment = false
                    index += 2
                } else {
                    index += 1
                }
                continue
            }
            if (inString) {
                if (current == '\\') {
                    index += 2
                    continue
                }
                if (current == '"') inString = false
                index += 1
                continue
            }
            if (inChar) {
                if (current == '\\') {
                    index += 2
                    continue
                }
                if (current == '\'') inChar = false
                index += 1
                continue
            }
            if (current == '/' && next == '*') {
                inBlockComment = true
                index += 2
                continue
            }
            if (current == '/' && next == '/') break
            if (current == '"') {
                inString = true
                index += 1
                continue
            }
            if (current == '\'') {
                inChar = true
                index += 1
                continue
            }
            builder.append(current)
            index += 1
        }
        sanitized.add(builder.toString())
    }
    return sanitized
}

// ------------------------------------------------------------------------------
// Finding emission
// ------------------------------------------------------------------------------
fun emit(id: String, path: String, line: Int, message: String) {
    println("$id $path:$line — $message")
    ccCounts[id] = (ccCounts[id] ?: 0) + 1
    ccTotal += 1
}

fun emitSkill(id: String, path: String, line: Int, message: String) {
    println("$id $path:$line — $message")
    skillFailures += 1
}

fun ccIdentifiers(): List<String> = listOf(
    "CC-01", "CC-02", "CC-03", "CC-04", "CC-05", "CC-06",
    "CC-07", "CC-08", "CC-09", "CC-10", "CC-11"
)

// ------------------------------------------------------------------------------
// CC-01 / CC-02 : identifier discipline
// ------------------------------------------------------------------------------
fun crypticTokens(): List<String> = listOf(
    "cb", "fn", "res", "req", "btn", "val", "tmp", "ctx", "el", "usr",
    "mgr", "idx", "cnt", "buf", "str", "num", "doc", "elem", "curr", "prev"
)

fun isTypeDeclarationSite(line: String, nameStart: Int): Boolean {
    var index = nameStart - 1
    while (index >= 0 && line[index].isWhitespace()) index -= 1
    if (index < 0) return false
    if (line[index] == '(' || line[index] == ',') return false
    val keywordEnd = index + 1
    while (index >= 0 && (line[index].isLetterOrDigit() || line[index] == '_')) index -= 1
    val keyword = line.substring(index + 1, keywordEnd)
    return keyword == "class" || keyword == "interface" || keyword == "object" ||
        keyword == "enum" || keyword == "value" || keyword == "fun" || keyword == "typealias"
}

fun bindingNames(line: String): List<String> {
    val declarations = mutableListOf<String>()
    for (match in Regex("\\b(?:val|var)\\s+([A-Za-z_][A-Za-z0-9_]*)").findAll(line)) {
        declarations.add(match.groupValues[1])
    }
    if (declarations.isNotEmpty()) return declarations

    val parameters = mutableListOf<String>()
    for (match in Regex("[\\s(,]([A-Za-z_][A-Za-z0-9_]*)\\s*:").findAll(line)) {
        val nameIndex = match.range.first + 1
        if (isTypeDeclarationSite(line, nameIndex)) continue
        parameters.add(match.groupValues[1])
    }
    if (parameters.isNotEmpty()) return parameters

    val caught = mutableListOf<String>()
    for (match in Regex("catch\\s*\\(\\s*([A-Za-z_][A-Za-z0-9_]*)").findAll(line)) {
        caught.add(match.groupValues[1])
    }
    if (caught.isNotEmpty()) return caught

    val loops = mutableListOf<String>()
    for (match in Regex("\\bfor\\s*\\(\\s*([A-Za-z_][A-Za-z0-9_]*)\\s+(?:in|:)").findAll(line)) {
        loops.add(match.groupValues[1])
    }
    if (loops.isNotEmpty()) return loops

    val lambdas = mutableListOf<String>()
    for (match in Regex("\\{([^{}]*?)->").findAll(line)) {
        for (part in match.groupValues[1].split(',')) {
            val candidate = part.trim()
            val identifier = Regex("^([A-Za-z_][A-Za-z0-9_]*)").find(candidate)?.groupValues?.get(1) ?: continue
            lambdas.add(identifier)
        }
    }
    return lambdas
}

fun checkIdentifierDiscipline(file: File, codeLines: List<String>) {
    val cryptic = crypticTokens()
    val path = normalizedPath(file)
    for (index in codeLines.indices) {
        val line = codeLines[index]
        if (line.isBlank()) continue
        for (name in bindingNames(line).distinct()) {
            if (name == "_") continue
            if (name.length == 1) {
                if ((name == "i" || name == "j") && line.contains("for")) continue
                emit("CC-01", path, index + 1, "prohibited single-letter identifier \"$name\"; use a descriptive name")
            } else if (cryptic.contains(name.lowercase())) {
                emit("CC-02", path, index + 1, "prohibited cryptic abbreviation \"$name\"; use the full identifier")
            }
        }
    }
}

// ------------------------------------------------------------------------------
// CC-03 : mutable lazy initialization — documented no-op for Kotlin
// Kotlin has no `??=` operator; the Elvis/nullable-service idioms are reviewed
// by `architecture-audit`/`solid` guidance instead of a mechanical barrier.
// ------------------------------------------------------------------------------
fun checkLazyInit(file: File) {
    // Documented no-op: Kotlin has no `??=` operator (docs/standards/governance_checks.md
    // section 4 marks CC-03 as a no-op for this stack). The canonical message that this
    // barrier would emit on other stacks is kept here for catalog traceability:
    // "prohibited mutable lazy initialization; inject the dependency via constructor".
}

// ------------------------------------------------------------------------------
// CC-04 : hardcoded placeholder / secret (blocking under every profile)
// ------------------------------------------------------------------------------
fun checkSecrets(file: File, rawLines: List<String>) {
    // Case-insensitive so the idiomatic camelCase Kotlin forms (`apiKey`, `authToken`)
    // are covered by the same documented token list.
    val pattern = Regex("(dummy_|changeme|TODO_KEY|(api[_-]?key|secret|password|token)\\s*[:=]\\s*\"[^\"]*\")", RegexOption.IGNORE_CASE)
    val exclusion = Regex("(api[_-]?key|secret|password|token)\\s*[:=]\\s*(\"[^\"]*\\{[^\"]*\"|\\$|process\\.env|System\\.getenv|System\\.getProperty|os\\.environ|env\\[)", RegexOption.IGNORE_CASE)
    val path = normalizedPath(file)
    for (index in rawLines.indices) {
        val line = rawLines[index]
        if (!pattern.containsMatchIn(line)) continue
        if (exclusion.containsMatchIn(line)) continue
        emit("CC-04", path, index + 1, "prohibited hardcoded placeholder/secret; source it from configuration/environment")
    }
}

// ------------------------------------------------------------------------------
// CC-05 : raw print / debug output
// ------------------------------------------------------------------------------
fun checkRawPrints(file: File, codeLines: List<String>) {
    val pattern = Regex("(^|[^A-Za-z0-9_.])println\\(")
    val path = normalizedPath(file)
    for (index in codeLines.indices) {
        val line = codeLines[index]
        if (line.startsWith("#!")) continue
        if (!pattern.containsMatchIn(line)) continue
        emit("CC-05", path, index + 1, "prohibited raw print/debug output in production code; use the logging interface")
    }
}

// ------------------------------------------------------------------------------
// CC-06 : silent exception swallowing
// ------------------------------------------------------------------------------
fun checkSilentCatches(file: File, rawLines: List<String>) {
    val inlineHandler = Regex("catch.*\\{\\s*\\}\\s*$")
    val openHandler = Regex("catch[^{]*\\{\\s*$")
    val closer = Regex("^\\s*\\}\\s*$")
    val blankOrComment = Regex("^\\s*$|^\\s*(//|/\\*|\\*|#)")
    val path = normalizedPath(file)
    val message = "prohibited silent exception swallowing; log with error+stack trace or rethrow"
    var index = 0
    while (index < rawLines.size) {
        val line = rawLines[index]
        if (inlineHandler.containsMatchIn(line)) {
            emit("CC-06", path, index + 1, message)
            index += 1
            continue
        }
        if (openHandler.containsMatchIn(line)) {
            var emptied = true
            var lookahead = 1
            while (lookahead <= 3 && index + lookahead < rawLines.size) {
                val upcoming = rawLines[index + lookahead]
                if (blankOrComment.containsMatchIn(upcoming)) {
                    lookahead += 1
                    continue
                }
                if (!closer.containsMatchIn(upcoming)) emptied = false
                break
            }
            if (emptied) emit("CC-06", path, index + 1, message)
        }
        index += 1
    }
}

// ------------------------------------------------------------------------------
// CC-07 : service-locator confinement
// ------------------------------------------------------------------------------
fun isContainerConfinementPath(path: String): Boolean {
    if (hasPathSegment(path, "di")) return true
    val name = pathSegments(path).lastOrNull() ?: path
    if (name.endsWith("Module.kt") || name.endsWith("Module.kts")) return true
    if (name.contains("Application")) return true
    if (name.contains("Activity")) return true
    return false
}

fun checkServiceLocator(file: File, codeLines: List<String>) {
    val path = normalizedPath(file)
    if (isContainerConfinementPath(path)) return
    // Documented tokens (docs/standards/governance_checks.md section 4) plus their
    // reified continuations, so `getKoin().get<Service>()` is caught alongside
    // `getKoin().get(Service::class.java)`.
    val tokens = listOf(
        "inject<", "KoinComponent",
        "getKoin().get(", "getKoin().get<",
        "GlobalContext.get().get(", "GlobalContext.get().get<"
    )
    val message = "prohibited service-locator resolution outside the composition root/presentation layer; inject via constructor"
    for (index in codeLines.indices) {
        val line = codeLines[index]
        var hit = false
        for (token in tokens) {
            if (line.contains(token)) {
                hit = true
                break
            }
        }
        if (hit) emit("CC-07", path, index + 1, message)
    }
}

// ------------------------------------------------------------------------------
// CC-08 : nullable collection parameter
// ------------------------------------------------------------------------------
fun checkNullableCollections(file: File, codeLines: List<String>) {
    // Documented tokens (docs/standards/governance_checks.md section 4); substring
    // matching also covers the Mutable*/qualified spellings of the same collection.
    val tokens = listOf("List<", "Map<", "Set<")
    val path = normalizedPath(file)
    val message = "prohibited nullable collection parameter; default to a constant empty collection"
    for (index in codeLines.indices) {
        val line = codeLines[index]
        for (token in tokens) {
            var searchFrom = 0
            while (true) {
                val found = line.indexOf(token, searchFrom)
                if (found < 0) break
                searchFrom = found + 1
                val colonIndex = line.lastIndexOf(':', found)
                if (colonIndex < 0) continue
                if (line.substring(0, colonIndex).trimEnd().endsWith(")")) continue
                var depth = 0
                var position = found + token.length - 1
                var end = -1
                while (position < line.length) {
                    val current = line[position]
                    if (current == '<') depth += 1
                    if (current == '>') {
                        depth -= 1
                        if (depth == 0) {
                            end = position
                            break
                        }
                    }
                    position += 1
                }
                if (end < 0) continue
                var after = end + 1
                while (after < line.length && line[after] == ' ') after += 1
                if (after < line.length && line[after] == '?') {
                    emit("CC-08", path, index + 1, message)
                }
            }
        }
    }
}

// ------------------------------------------------------------------------------
// CC-09 : unimplemented placeholder
// ------------------------------------------------------------------------------
fun checkUnimplemented(file: File, codeLines: List<String>) {
    // Documented tokens (docs/standards/governance_checks.md section 4).
    val tokens = listOf("TODO(", "throw NotImplementedError(")
    val path = normalizedPath(file)
    for (index in codeLines.indices) {
        val line = codeLines[index]
        if (!tokens.any { line.contains(it) }) continue
        emit("CC-09", path, index + 1, "prohibited unimplemented placeholder in production contract; implement the contract (LSP)")
    }
}

// ------------------------------------------------------------------------------
// CC-10 : concrete network-client instantiation (DIP)
// ------------------------------------------------------------------------------
fun isNetworkClientConfinementPath(path: String): Boolean {
    if (isContainerConfinementPath(path)) return true
    val name = pathSegments(path).lastOrNull() ?: path
    return name.startsWith("main.")
}

fun checkConcreteClient(file: File, codeLines: List<String>) {
    val path = normalizedPath(file)
    if (isNetworkClientConfinementPath(path)) return
    val tokens = listOf("OkHttpClient(", "HttpClient(")
    val message = "prohibited concrete network-client instantiation outside the composition root; depend on an abstraction (DIP)"
    for (index in codeLines.indices) {
        val line = codeLines[index]
        var hit = false
        for (token in tokens) {
            if (line.contains(token)) {
                hit = true
                break
            }
        }
        if (hit) emit("CC-10", path, index + 1, message)
    }
}

// ------------------------------------------------------------------------------
// CC-11 : avoidable allocation on a hot path (advisory)
// ------------------------------------------------------------------------------
fun loopHeaderCloseIndex(line: String): Int {
    val header = Regex("\\b(?:for|while)\\s*\\(").find(line) ?: return -1
    var depth = 0
    var position = line.indexOf('(', header.range.first)
    if (position < 0) return -1
    while (position < line.length) {
        val current = line[position]
        if (current == '(') depth += 1
        if (current == ')') {
            depth -= 1
            if (depth == 0) return position
        }
        position += 1
    }
    return -1
}

fun checkHotPathAllocations(file: File, codeLines: List<String>) {
    val path = normalizedPath(file)
    // Documented tokens (docs/standards/governance_checks.md section 4).
    val tokens = listOf(".toList()", ".toMutableList()")
    val loopHeader = Regex("\\b(?:for|while)\\s*\\(")
    val message = "[advisory] avoidable allocation on hot path; inspect without copying and return the original reference"
    var depth = 0
    val loopDepths = mutableListOf<Int>()
    var previousBareLoopHeader = false
    for (index in codeLines.indices) {
        val line = codeLines[index]
        while (loopDepths.isNotEmpty() && loopDepths.last() > depth) {
            loopDepths.removeAt(loopDepths.size - 1)
        }
        val trimmed = line.trim()
        val isLoopHeader = loopHeader.containsMatchIn(line)
        var allocationIndex = -1
        for (token in tokens) {
            val found = line.indexOf(token)
            if (found >= 0 && (allocationIndex < 0 || found < allocationIndex)) allocationIndex = found
        }
        if (allocationIndex >= 0) {
            var inside = loopDepths.isNotEmpty() || previousBareLoopHeader
            if (!inside && isLoopHeader) {
                val closeIndex = loopHeaderCloseIndex(line)
                if (closeIndex >= 0 && allocationIndex > closeIndex) inside = true
            }
            if (inside) emit("CC-11", path, index + 1, message)
        }
        previousBareLoopHeader = isLoopHeader && !trimmed.endsWith("{")
        var opens = 0
        var closes = 0
        for (character in line) {
            if (character == '{') opens += 1
            if (character == '}') closes += 1
        }
        depth += opens - closes
        if (isLoopHeader && trimmed.endsWith("{")) loopDepths.add(depth)
    }
}

// ------------------------------------------------------------------------------
// clean-code suite
// ------------------------------------------------------------------------------
fun runCleanCodeReport() {
    for (file in productionFiles()) {
        val text = try {
            file.readText()
        } catch (error: Exception) {
            continue
        }
        val rawLines = text.split("\n")
        val codeLines = sanitizeSource(text)
        checkIdentifierDiscipline(file, codeLines)
        checkLazyInit(file)
        checkSecrets(file, rawLines)
        checkRawPrints(file, codeLines)
        checkSilentCatches(file, rawLines)
        checkUnimplemented(file, codeLines)
        checkServiceLocator(file, codeLines)
        checkNullableCollections(file, codeLines)
        checkConcreteClient(file, codeLines)
    }
    for (file in collectSourceFiles()) {
        val text = try {
            file.readText()
        } catch (error: Exception) {
            continue
        }
        checkHotPathAllocations(file, sanitizeSource(text))
    }
}

fun runCleanCode(forceStandard: Boolean) {
    resolveProfile()
    if (forceStandard) profile = "standard"
    ccTotal = 0
    for (id in ccIdentifiers()) ccCounts[id] = 0
    runCleanCodeReport()

    var blockingTotal = 0
    for (id in ccIdentifiers()) {
        val count = ccCounts[id] ?: 0
        if (count <= 0) continue
        if (ccBlocking(id) && count.toDouble() > ccThreshold(id)) blockingTotal += count
    }

    val behavior = if (ccBlocking("CC-01")) "blocking" else "advisory"
    println("Clean Code: $ccTotal violation(s) ($profile profile: $behavior)")
    if (blockingTotal > 0) {
        System.exit(1)
    }
}

// ------------------------------------------------------------------------------
// PT-01 : ponytail debt markers
// ------------------------------------------------------------------------------
fun scanDebtMarkers() {
    val pattern = Regex("(^|[^A-Za-z])(//|#|--|/\\*|///|<!--)[^\n]*ponytail:")
    for (file in collectSourceFiles()) {
        val text = try {
            file.readText()
        } catch (error: Exception) {
            continue
        }
        val path = normalizedPath(file)
        val lines = text.split("\n")
        for (index in lines.indices) {
            val line = lines[index]
            if (!pattern.containsMatchIn(line)) continue
            val marker = line.indexOf("ponytail:")
            if (marker < 0) continue
            val reason = line.substring(marker + "ponytail:".length).trim()
            println("PT-01 $path:${index + 1} — $reason")
        }
    }
}

fun runPonytailDebt() {
    scanDebtMarkers()
}

fun runPonytailAudit() {
    scanDebtMarkers()
    val narration = Regex("^\\s*(//|#)\\s*(increment|decrement|set|assign|call|return|loop|iterate|initialize|create|check|store)\\s")
    val delegation = Regex("=>\\s*[A-Za-z_][A-Za-z0-9_.]*\\([^)]*\\);?\\s*$|^\\s*\\{\\s*return\\s+[A-Za-z_][A-Za-z0-9_.]*\\([^)]*\\);\\s*\\}\\s*$")
    for (file in productionFiles()) {
        val text = try {
            file.readText()
        } catch (error: Exception) {
            continue
        }
        val path = normalizedPath(file)
        val lines = text.split("\n")
        for (index in lines.indices) {
            val line = lines[index]
            if (narration.containsMatchIn(line)) {
                println("[advisory] [DELETE] $path:${index + 1} — narration comment restates the next line")
            }
            if (delegation.containsMatchIn(line)) {
                println("[advisory] [SHRINK] $path:${index + 1} — single-statement delegation; verify a caller justifies the layer")
            }
        }
    }
}

// ------------------------------------------------------------------------------
// SK-01 .. SK-06 : skill activation invariants
// ------------------------------------------------------------------------------
fun skillFile(skill: String): File = File(".agents/skills/$skill/SKILL.md")

fun frontmatterValue(skill: String, key: String): String {
    val file = skillFile(skill)
    if (!file.exists()) return ""
    val lines = file.readText().split("\n")
    if (lines.isEmpty() || lines[0].trim() != "---") return ""
    var value = ""
    var collecting = false
    var index = 1
    while (index < lines.size) {
        val line = lines[index]
        if (line.trim() == "---") break
        if (line.startsWith("$key:")) {
            value = line.substring(key.length + 1).trim()
            collecting = true
            index += 1
            continue
        }
        if (collecting) {
            if (line.startsWith(" ") || line.startsWith("\t")) {
                val trimmed = line.trim()
                value = if (value.isEmpty() || value == ">" || value == "|" || value == ">-" || value == "|-") {
                    trimmed
                } else {
                    "$value $trimmed"
                }
                index += 1
                continue
            }
            collecting = false
        }
        index += 1
    }
    return value.trim()
}

fun frontmatterKeys(skill: String): List<String> {
    val file = skillFile(skill)
    if (!file.exists()) return emptyList()
    val lines = file.readText().split("\n")
    if (lines.isEmpty() || lines[0].trim() != "---") return emptyList()
    val keys = mutableListOf<String>()
    var index = 1
    while (index < lines.size) {
        val line = lines[index]
        if (line.trim() == "---") break
        val match = Regex("^([A-Za-z][A-Za-z0-9_-]*):").find(line)
        if (match != null) keys.add(match.groupValues[1])
        index += 1
    }
    return keys
}

fun skill02Message(skill: String): String =
    "skill \"$skill\" frontmatter must declare \"Use when\", \"Triggers on:\" and \"Chains into:\" with >=150 characters and name==directory"

fun auditSkillsParity() {
    val agents = File(AGENTS_FILE)
    val agentsText = if (agents.exists()) agents.readText() else ""
    val readme = File("README.md")
    val readmeText = if (readme.exists()) readme.readText() else ""
    for (skill in skillCatalog()) {
        if (!skillFile(skill).exists()) {
            emitSkill("SK-01", ".agents/skills/$skill", 0, "skill \"$skill\" is not listed in .agents/skills (parity required)")
            continue
        }
        if (agents.exists() && !agentsText.contains("`$skill`")) {
            emitSkill("SK-01", AGENTS_FILE, 0, "skill \"$skill\" is not listed in AGENTS.md (parity required)")
        }
        if (readme.exists() && !readmeText.contains(skill)) {
            emitSkill("SK-01", "README.md", 0, "skill \"$skill\" is not listed in README.md (parity required)")
        }
    }
}

fun auditSkillsFrontmatter() {
    val allowedKeys = listOf("name", "description", "argument-hint", "license", "metadata")
    for (skill in skillCatalog()) {
        val file = skillFile(skill)
        if (!file.exists()) continue
        if (isAdoption() && userOwnedSkill(skill)) continue
        val description = frontmatterValue(skill, "description")
        var invalid = description.isEmpty() ||
            !description.contains("Use when") ||
            !description.contains("Triggers on:") ||
            !description.contains("Chains into:") ||
            description.length < 150
        if (invalid) {
            emitSkill("SK-02", ".agents/skills/$skill/SKILL.md", 0, skill02Message(skill))
            continue
        }
        if (frontmatterValue(skill, "name") != skill) {
            emitSkill("SK-02", ".agents/skills/$skill/SKILL.md", 0, skill02Message(skill))
            continue
        }
        for (key in frontmatterKeys(skill)) {
            if (!allowedKeys.contains(key)) {
                emitSkill("SK-02", ".agents/skills/$skill/SKILL.md", 0, skill02Message(skill))
            }
        }
        val hasTerritory = file.readText().split("\n").any { it.startsWith("## Territory") }
        if (!hasTerritory) {
            emitSkill("SK-02", ".agents/skills/$skill/SKILL.md", 0, skill02Message(skill))
        }
    }
}

fun auditEntrypointParity() {
    val llms = File(LLMS_FILE)
    val llmsText = if (llms.exists()) llms.readText() else ""
    for (skill in skillCatalog()) {
        if (llms.exists() && !llmsText.contains(skill)) {
            emitSkill("SK-03", LLMS_FILE, 0, "skill \"$skill\" is not listed in llms.txt")
        }
    }
    for (entry in listOf("README.md", "docs/INDEX.md", "docs/MANIFESTO.md")) {
        val file = File(entry)
        if (!file.exists()) continue
        if (!file.readText().contains("llms.txt")) {
            emitSkill("SK-03", entry, 0, "entrypoint $entry does not reference llms.txt")
        }
    }
}

fun matrixRows(): List<Pair<String, String>> {
    val agents = File(AGENTS_FILE)
    if (!agents.exists()) return emptyList()
    val rows = mutableListOf<Pair<String, String>>()
    var inside = false
    for (line in agents.readText().split("\n")) {
        if (line.startsWith("### 3.3")) {
            inside = true
            continue
        }
        if (inside && line.startsWith("#")) {
            inside = false
            continue
        }
        if (!inside) continue
        if (!line.startsWith("|")) continue
        // Kotlin's String.split drops trailing empty strings: a five-column row yields six cells
        // (["", intent, territory, triggers, primary, meta]).
        val cells = line.split("|").toMutableList()
        while (cells.isNotEmpty() && cells.last().isBlank()) cells.removeAt(cells.size - 1)
        if (cells.size < 5) continue
        val triggers = cells[3].trim()
        val primary = cells[4].replace(Regex("[`\\s]"), "")
        if (primary.isEmpty() || primary == "PrimarySkill" || primary.startsWith(":")) continue
        rows.add(Pair(primary, triggers))
    }
    return rows
}

fun auditTriggerCoherence() {
    val rows = matrixRows()
    for (skill in skillCatalog()) {
        val row = rows.firstOrNull { it.first == skill }
        if (row == null) {
            emitSkill("SK-04", AGENTS_FILE, 0, "skill \"$skill\" has no dispatch-matrix row")
            continue
        }
        if (isAdoption() && userOwnedSkill(skill)) continue
        val description = frontmatterValue(skill, "description").lowercase()
        for (piece in row.second.split(",")) {
            if (piece.isEmpty()) continue
            var trigger = piece
            if (trigger.startsWith("\"")) trigger = trigger.substring(1)
            if (trigger.endsWith("\"")) trigger = trigger.dropLast(1)
            trigger = trigger.lowercase()
            if (trigger.isEmpty()) continue
            if (!description.contains(trigger)) {
                emitSkill("SK-04", AGENTS_FILE, 0, "trigger \"$trigger\" for skill \"$skill\" is missing from its frontmatter \"Triggers on:\"")
            }
        }
    }
}

fun mirrorPresent(directory: String): Boolean =
    File(directory).exists() || Files.isSymbolicLink(Paths.get(directory))

fun mirrorOf(directory: String, skill: String): String? {
    if (!mirrorPresent(directory)) return null
    if (File("$directory/$skill").isDirectory) return "$directory/$skill/SKILL.md"
    if (File("$directory/$skill.md").isFile) return "$directory/$skill.md"
    if (File("$directory/$skill.mdc").isFile) return "$directory/$skill.mdc"
    return null
}

fun sameContent(left: File, right: File): Boolean {
    if (!right.isFile) return false
    val leftBytes = try {
        left.readBytes()
    } catch (error: Exception) {
        return false
    }
    val rightBytes = try {
        right.readBytes()
    } catch (error: Exception) {
        return false
    }
    return leftBytes.contentEquals(rightBytes)
}

fun auditMirrorParity() {
    for (directory in mirrorDirs()) {
        if (!mirrorPresent(directory)) continue
        for (skill in skillCatalog()) {
            val canonical = File(".agents/skills/$skill/SKILL.md")
            if (!canonical.isFile) continue
            val mirror = mirrorOf(directory, skill)
            if (mirror == null) {
                emitSkill("SK-05", directory, 0, "harness mirror \"$directory\" diverges from .agents/skills for skill \"$skill\" (run: oaef skills sync-mirrors)")
                continue
            }
            if (!sameContent(canonical, File(mirror))) {
                emitSkill("SK-05", directory, 0, "harness mirror \"$directory\" diverges from .agents/skills for skill \"$skill\" (run: oaef skills sync-mirrors)")
            }
        }
    }
}

fun userOwnedSkill(skill: String): Boolean {
    val ledger = File(ADOPTION_LEDGER)
    if (!ledger.exists()) return false
    var inside = false
    for (line in ledger.readText().split("\n")) {
        if (line.contains("\"user_skills\"")) {
            inside = true
            continue
        }
        if (inside) {
            if (line.contains(']')) return false
            if (line.contains("\"$skill\"")) return true
        }
    }
    return false
}

// ------------------------------------------------------------------------------
// Routing (docs/standards/governance_checks.md section 7.1)
// ------------------------------------------------------------------------------
fun candidateForms(token: String): List<String> {
    val forms = mutableListOf(token)
    if (token.endsWith("ies")) forms.add(token.dropLast(3) + "y")
    if (token.endsWith("es")) forms.add(token.dropLast(2))
    if (token.endsWith("s")) forms.add(token.dropLast(1))
    if (token.endsWith("ing")) forms.add(token.dropLast(3))
    if (token.endsWith("ed")) forms.add(token.dropLast(2))
    if (token.endsWith("ion")) forms.add(token.dropLast(3))
    return forms
}

fun commonPrefixLength(left: String, right: String): Int {
    val limit = minOf(left.length, right.length)
    for (position in 0 until limit) {
        if (left[position] != right[position]) return position
    }
    return limit
}

fun tokenMatchesWord(token: String, word: String): Boolean {
    if (word.isEmpty()) return false
    for (candidate in candidateForms(token)) {
        if (candidate == word) return true
        if (candidate.length >= 4 && commonPrefixLength(candidate, word) >= 4) return true
    }
    return false
}

fun routePrompt(prompt: String): String {
    val lowered = prompt.lowercase()
    val tokens = lowered.split(Regex("[^a-z0-9-]+")).filter { it.isNotEmpty() }
    val territory = " features screens pages components shared ui core domain data infra test tests "
    var best = "ponytail"
    var bestScore = -1
    for (skill in skillCatalog()) {
        var score = 0
        for (nameWord in skill.split('-')) {
            if (tokens.any { tokenMatchesWord(it, nameWord) }) score += 5
        }
        val triggerText = skillTriggers(skill)
        if (triggerText.isNotEmpty()) {
            for (trigger in triggerText.split('|')) {
                if (trigger.isEmpty()) continue
                val weight = minOf(trigger.length, 8)
                if (trigger.contains(' ')) {
                    if (lowered.contains(trigger)) score += 3 + weight
                } else if (tokens.any { tokenMatchesWord(it, trigger) }) {
                    score += 3 + weight
                }
            }
        }
        for (token in tokens) {
            if (territory.contains(" $token ")) score += 1
        }
        if (score > bestScore) {
            bestScore = score
            best = skill
        }
    }
    if (bestScore <= 0) best = "ponytail"
    return best
}

fun runSkillsRoute(query: String) {
    val primary = routePrompt(query)
    val meta = skillMeta(primary)
    println("Routing: \"$query\"")
    println("Primary skill: $primary .agents/skills/$primary/SKILL.md")
    println("Meta-skill: $meta")
    println("Recipes containing $primary:")
    for (recipe in recipes()) {
        if (recipe.contains(primary)) println("  $recipe")
    }
}

fun runSkillsSelftest() {
    for (fixture in routingFixtures()) {
        val separator = fixture.indexOf('|')
        if (separator < 0) continue
        val prompt = fixture.substring(0, separator)
        val expected = fixture.substring(separator + 1)
        val resolved = routePrompt(prompt)
        if (resolved != expected) {
            emitSkill("SK-06", AGENTS_FILE, 0, "routing self-test failed: prompt \"$prompt\" resolved to \"$resolved\" but expected \"$expected\"")
        }
    }
}

fun runSkillsAudit(selftest: Boolean) {
    resolveProfile()
    skillFailures = 0
    auditSkillsParity()
    auditSkillsFrontmatter()
    auditEntrypointParity()
    auditTriggerCoherence()
    auditMirrorParity()
    if (selftest) runSkillsSelftest()
    println("Skills: $skillFailures finding(s)")
    if (skillFailures > 0) System.exit(1)
}

// ------------------------------------------------------------------------------
// Harness skill mirrors
// ------------------------------------------------------------------------------
fun copyTree(source: File, target: File) {
    if (source.isDirectory) {
        target.mkdirs()
        val children = source.listFiles() ?: return
        for (child in children) copyTree(child, File(target, child.name))
    } else {
        target.parentFile?.mkdirs()
        source.copyTo(target, overwrite = true)
    }
}

fun runSkillsSyncMirrors(checkOnly: Boolean) {
    resolveProfile()
    var repaired = 0
    for (directory in mirrorDirs()) {
        if (!mirrorPresent(directory)) continue
        val directoryPath = Paths.get(directory)
        if (Files.isSymbolicLink(directoryPath) &&
            Files.readSymbolicLink(directoryPath).toString() == "../.agents/skills" &&
            File(directory).isDirectory
        ) {
            println("✅ $directory is a symlink to .agents/skills (parity by construction)")
            continue
        }
        if (!File(directory).isDirectory) continue
        for (skill in skillCatalog()) {
            val canonical = skillFile(skill)
            if (!canonical.isFile) continue
            val entry = mirrorOf(directory, skill)
            if (entry != null) {
                if (!checkOnly && !sameContent(canonical, File(entry))) {
                    copyTree(canonical, File(entry))
                    println("🔧 $directory: repaired mirror for $skill (canonical catalog is authoritative)")
                    repaired += 1
                }
                continue
            }
            if (checkOnly) continue
            val target = "$directory/$skill"
            var linked = false
            try {
                Files.createSymbolicLink(Paths.get(target), Paths.get("../.agents/skills/$skill"))
                linked = File(target).exists()
            } catch (error: Exception) {
                linked = false
            }
            if (linked) {
                println("🔧 $directory: created mirror link for $skill")
            } else {
                File(target).delete()
                copyTree(skillFile(skill).parentFile ?: File(".agents/skills/$skill"), File(target))
                println("🔧 $directory: created mirror copy for $skill")
            }
            repaired += 1
        }
    }
    skillFailures = 0
    auditMirrorParity()
    if (checkOnly) {
        if (skillFailures > 0) {
            println("Mirrors: $skillFailures divergence(s) detected")
            System.exit(1)
        }
        println("Mirrors: parity verified")
        return
    }
    if (skillFailures > 0) {
        println("Mirrors: $skillFailures divergence(s) remain (user-owned entries are preserved)")
        System.exit(1)
    }
    println("Mirrors: $repaired entry(ies) synchronized, parity verified")
}

// ------------------------------------------------------------------------------
// lint / doctor / quality gate / sync / metrics
// ------------------------------------------------------------------------------
fun normalizeMirror(path: String): String {
    val file = File(path)
    if (!file.exists()) return ""
    return file.readText().split("\n")
        .filter { !it.startsWith("<!--") }
        .joinToString("")
        .replace(Regex("[ \t\r\n]"), "")
}

fun collectAllFiles(): List<File> {
    val collected = mutableListOf<File>()
    fun visit(directory: File) {
        val children = directory.listFiles() ?: return
        for (child in children) {
            if (EXCLUDED_SEGMENTS.contains(child.name)) continue
            if (child.isDirectory) {
                visit(child)
            } else if (child.isFile) {
                collected.add(child)
            }
        }
    }
    visit(File("."))
    return collected.sortedBy { normalizedPath(it) }
}

fun runSecretScan(): Boolean {
    val pattern = Regex("(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)")
    var found = false
    for (file in collectAllFiles()) {
        val path = normalizedPath(file)
        if (!path.startsWith("docs/")) continue
        val text = try {
            file.readText()
        } catch (error: Exception) {
            continue
        }
        val lines = text.split("\n")
        for (index in lines.indices) {
            if (!pattern.containsMatchIn(lines[index])) continue
            println("$path:${index + 1}:${lines[index]}")
            found = true
        }
    }
    return found
}

fun runSuppressionScan(): Boolean {
    val pattern = Regex("(//\\s*ignore:|/\\*\\s*eslint-disable|//\\s*@ts-ignore|#\\s*noqa|#\\s*type:\\s*ignore|//nolint|#\\[allow\\(|@Suppress\\(|//\\s*swiftlint:disable|#pragma warning disable)")
    val allowed = Regex("(deprecated_member_use|type=lint|SA1019|CS0618|CS0612|DEPRECATION|DeprecatedCallableAddReplaceWith|#\\[allow\\(deprecated\\)|@typescript-eslint/no-deprecated|W1505|B005|deprecated-method|type:\\s*ignore\\[deprecated\\]|DO NOT EDIT|@generated|\\.g\\.)")
    val hits = mutableListOf<String>()
    for (file in collectAllFiles()) {
        val path = normalizedPath(file)
        if (path.endsWith(".md")) continue
        val text = try {
            file.readText()
        } catch (error: Exception) {
            continue
        }
        val lines = text.split("\n")
        for (index in lines.indices) {
            val line = lines[index]
            if (!pattern.containsMatchIn(line)) continue
            val rendered = "$path:${index + 1}:$line"
            if (allowed.containsMatchIn(rendered)) continue
            hits.add(rendered)
        }
    }
    if (hits.isEmpty()) return false
    System.err.println("🚨 [LINT] Unallowed linter/compiler suppression comments detected:")
    for (hit in hits) System.err.println(hit)
    return true
}

fun runLint() {
    resolveProfile()
    var failed = false

    if (File(AGENTS_FILE).exists() && File("CLAUDE.md").exists()) {
        if (normalizeMirror(AGENTS_FILE) != normalizeMirror("CLAUDE.md")) {
            System.err.println("❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run \"oaef sync\".")
            failed = true
        }
    }

    if (runSecretScan()) {
        System.err.println("🚨 [SECURITY] Potential secret detected in docs/!")
        failed = true
    }

    if (runSuppressionScan()) failed = true

    ccTotal = 0
    for (id in ccIdentifiers()) ccCounts[id] = 0
    runCleanCodeReport()
    skillFailures = 0
    auditSkillsParity()
    auditSkillsFrontmatter()
    auditEntrypointParity()
    auditTriggerCoherence()
    auditMirrorParity()
    runSkillsSelftest()
    if (skillFailures > 0) failed = true

    if (failed) {
        System.err.println("❌ LINT FAILED.")
        System.exit(1)
    }
    println("✅ [LINT] All integrity and secret audits passed cleanly.")
}

fun runConform() {
    resolveProfile()
    var checks = 0
    var passed = 0
    var failed = false

    fun check(condition: Boolean, label: String) {
        checks += 1
        if (condition) {
            passed += 1
            println("✅ $label")
        } else {
            System.err.println("❌ $label")
            failed = true
        }
    }

    println("🩺 OAEF Conformance Audit (doctor)...")
    val requiredFiles = listOf(
        "AGENTS.md", "CLAUDE.md", "llms.txt", "oaef.context.json",
        "docs/INDEX.md", "docs/MANIFESTO.md", "docs/DESIGN.md", "docs/HARNESSES.md",
        "docs/standards/coding_patterns.md", "docs/standards/testing.md", "docs/standards/logging.md",
        "docs/standards/clean_code.md", "docs/standards/solid.md", "docs/standards/review.md",
        "docs/standards/analytics_and_telemetry.md", "docs/standards/governance_checks.md",
        "docs/wiki/metrics/baseline.json", "docs/wiki/memory/handoff.md", "docs/wiki/log.md",
        ".github/workflows/ci.yml", ".github/pull_request_template.md",
        ".gitignore", "CONTRIBUTING.md", "SECURITY.md"
    )
    for (entry in requiredFiles) {
        checks += 1
        if (File(entry).exists()) {
            passed += 1
            println("✅ $entry present")
        } else {
            System.err.println("❌ $entry missing")
            failed = true
        }
    }
    for (skill in skillCatalog()) {
        checks += 1
        if (skillFile(skill).isFile) {
            passed += 1
            println("✅ .agents/skills/$skill/SKILL.md present")
        } else {
            System.err.println("❌ .agents/skills/$skill/SKILL.md missing")
            failed = true
        }
    }
    check(
        File(AGENTS_FILE).exists() && File("CLAUDE.md").exists() &&
            normalizeMirror(AGENTS_FILE) == normalizeMirror("CLAUDE.md"),
        "CLAUDE.md mirror parity verified"
    )
    val agentsText = if (File(AGENTS_FILE).exists()) File(AGENTS_FILE).readText() else ""
    val llmsText = if (File(LLMS_FILE).exists()) File(LLMS_FILE).readText() else ""
    val placeholderPattern = Regex("\\{\\{PROJECT_NAME\\}\\}|\\{\\{TECH_STACK\\}\\}|\\{\\{STACK_SPECIFIC_RULES\\}\\}")
    check(
        !placeholderPattern.containsMatchIn(agentsText) && !placeholderPattern.containsMatchIn(llmsText),
        "no unresolved template placeholders"
    )
    skillFailures = 0
    runSkillsSelftest()
    check(skillFailures == 0, "routing self-test (SK-06) passed")

    println("\n📊 Conformance: $passed/$checks checks passed")
    if (failed) System.exit(1)
}

fun runQualityGate() {
    resolveProfile()
    println("🔍 Initiating OAEF Quality Gate Audit (Kotlin Multiplatform)...")
    if (!File("build.gradle.kts").exists() && !File("build.gradle").exists()) {
        System.err.println("⚠️  No build.gradle(.kts) found; skipping the Gradle test suite.")
    } else {
        val gradlew = if (File("gradlew").exists()) "./gradlew" else "gradle"
        val testTask = if (File("composeApp").exists()) "allTests" else "test"
        var process: Process? = null
        try {
            process = ProcessBuilder(gradlew, testTask).inheritIO().start()
        } catch (error: Exception) {
            System.err.println("⚠️  Gradle ($gradlew) is unavailable; skipping the Gradle test suite.")
        }
        val runner = process
        if (runner != null && runner.waitFor() != 0) {
            System.err.println("❌ Multiplatform tests failed.")
            System.exit(1)
        }
    }

    var oversized = 0
    for (file in productionFiles()) {
        val lines = try {
            file.readText().split("\n").size
        } catch (error: Exception) {
            continue
        }
        if (lines > 300) {
            System.err.println("⚠️  Oversized file (${lines}L > 300L): ${normalizedPath(file)}")
            oversized += 1
        }
    }
    if (oversized > 0) {
        System.err.println("❌ Quality Gate Failed: $oversized oversized files detected.")
        System.exit(1)
    }

    ccTotal = 0
    for (id in ccIdentifiers()) ccCounts[id] = 0
    runCleanCodeReport()
    val behavior = if (ccBlocking("CC-01")) "blocking" else "advisory"
    println("Clean Code: $ccTotal violation(s) ($profile profile: $behavior)")
    if (profile == "strict" && !isAdoption() && ccTotal > 0) {
        System.err.println("❌ Quality Gate Failed: $ccTotal clean-code violation(s).")
        System.exit(1)
    }
    println("\n🎉 Quality Gates PASSED!")
}

fun runMetrics() {
    val baseline = File(BASELINE_FILE)
    if (baseline.exists()) print(baseline.readText())
}

fun runSync() {
    val agents = File(AGENTS_FILE)
    if (agents.exists()) {
        val content = "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n" +
            "<!-- To modify rules, edit AGENTS.md and run \"oaef sync\". -->\n\n" +
            agents.readText().trimEnd('\n') + "\n"
        File("CLAUDE.md").writeText(content)
        println("✅ Synchronized AGENTS.md -> CLAUDE.md")
    }
}

fun usage() {
    println("OAEF Governance Tool (Kotlin Multiplatform Engine)")
    println("Usage: kotlinc -script tool/governance.main.kts <command>")
    println("Commands:")
    println("  quality-gate|audit        Quality Gate audit (tests, sizing, clean code)")
    println("  clean-code                Governance barriers (docs/standards/governance_checks.md)")
    println("  ponytail-debt             Report every \"// ponytail:\" debt marker (PT-01)")
    println("  ponytail-audit            Advisory anti-slop audit")
    println("  skills-audit [--selftest] Skill activation invariants (SK-01..SK-06)")
    println("  skills-route \"<query>\"    Resolve a prompt to its governing skill and recipe")
    println("  skills sync-mirrors [--check] Rebuild or validate the harness skill mirrors")
    println("  lint                      Mirror parity, secrets, anti-suppression, skills")
    println("  doctor|conform            Conformance audit")
    println("  metrics                   Display baseline thresholds")
    println("  sync                      Synchronize AGENTS.md to CLAUDE.md")
}
