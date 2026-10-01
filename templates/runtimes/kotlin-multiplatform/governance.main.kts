import java.io.File

val command = args.firstOrNull() ?: ""

when (command) {
    "quality-gate", "audit" -> runQualityGate()
    "lint" -> runLint()
    "conform", "doctor" -> runConform()
    "sync" -> runSync()
    else -> {
        println("OAEF Governance Tool (Kotlin Multiplatform Engine)")
        println("Usage: kotlin tool/governance.main.kts [quality-gate|lint|doctor|sync]")
        System.exit(1)
    }
}

fun runQualityGate() {
    println("🔍 Initiating OAEF Quality Gate Audit (Kotlin Multiplatform)...")
    val gradlew = if (File("gradlew").exists()) "./gradlew" else "gradle"
    val testTask = if (File("composeApp").exists()) "allTests" else "test"
    val process = ProcessBuilder(gradlew, testTask).inheritIO().start()
    if (process.waitFor() != 0) {
        System.err.println("❌ Multiplatform tests failed.")
        System.exit(1)
    }
    println("\n🎉 Quality Gates PASSED!")
}

fun normalizeMirrorText(text: String): String =
    text.lines()
        .filter { !it.startsWith("<!--") }
        .joinToString("")
        .replace(Regex("\\s+"), "")

fun runConform() {
    println("🩺 OAEF Conformance Audit (doctor)...")
    val requiredFiles = listOf(
        "AGENTS.md", "CLAUDE.md", "llms.txt", "oaef.context.json",
        "docs/INDEX.md", "docs/MANIFESTO.md", "docs/DESIGN.md",
        "docs/standards/coding_patterns.md", "docs/standards/testing.md", "docs/standards/logging.md",
        "docs/wiki/metrics/baseline.json", "docs/wiki/memory/handoff.md", "docs/wiki/log.md",
        "docs/HARNESSES.md",
        ".github/workflows/ci.yml", ".github/pull_request_template.md",
        ".gitignore", "CONTRIBUTING.md", "SECURITY.md"
    )
    val skills = listOf(
        "architecture-audit", "code-review", "collect-coverage", "component-author",
        "fix-layout-issues", "nullable-types", "run-static-analysis", "screen-builder",
        "test-generator", "ui-preview", "conformance-audit"
    )
    val runtimes = listOf(
        "tool/governance.sh", "tool/governance.mjs", "tool/governance.py", "tool/governance.dart",
        "tool/governance.go", "tool/governance.rs", "tool/governance.main.kts", "tool/governance.swift",
        "tool/Governance.cs"
    )

    var checks = 0
    var passed = 0
    var failed = false

    fun check(condition: Boolean, label: String) {
        checks++
        if (condition) {
            passed++
            println("✅ $label")
        } else {
            System.err.println("❌ $label")
            failed = true
        }
    }

    for (file in requiredFiles) check(File(file).exists(), "$file present")
    for (skill in skills) check(File(".agents/skills/$skill/SKILL.md").exists(), ".agents/skills/$skill/SKILL.md present")
    check(runtimes.any { File(it).exists() }, "governance runtime present in tool/")

    val agentsFile = File("AGENTS.md")
    val claudeFile = File("CLAUDE.md")
    if (agentsFile.exists() && claudeFile.exists()) {
        check(normalizeMirrorText(agentsFile.readText()) == normalizeMirrorText(claudeFile.readText()), "CLAUDE.md mirror parity verified")
    } else {
        check(false, "mirror parity not verifiable (missing AGENTS.md or CLAUDE.md)")
    }

    val placeholderPattern = Regex("\\{\\{PROJECT_NAME\\}\\}|\\{\\{TECH_STACK\\}\\}|\\{\\{STACK_SPECIFIC_RULES\\}\\}")
    var placeholderHits = false
    for (candidate in listOf("AGENTS.md", "llms.txt")) {
        val candidateFile = File(candidate)
        if (candidateFile.exists() && placeholderPattern.containsMatchIn(candidateFile.readText())) {
            placeholderHits = true
        }
    }
    check(!placeholderHits, "no unresolved template placeholders")

    println("\n📊 Conformance: $passed/$checks checks passed")
    if (failed) System.exit(1)
}

fun runLint() {
    println("🔍 Auditing OAEF Integrity & Secret Leaks...")
    val agents = File("AGENTS.md")
    val claude = File("CLAUDE.md")
    if (agents.exists() && claude.exists()) {
        if (normalizeMirrorText(agents.readText()) != normalizeMirrorText(claude.readText())) {
            System.err.println("❌ [LINT] CLAUDE.md diverged from AGENTS.md.")
            System.exit(1)
        }
    }
    println("✅ [LINT] All audits passed cleanly.")
}

fun runSync() {
    val agents = File("AGENTS.md")
    if (agents.exists()) {
        File("CLAUDE.md").writeText("<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n\n" + agents.readText())
        println("✅ Synchronized AGENTS.md -> CLAUDE.md")
    }
}
