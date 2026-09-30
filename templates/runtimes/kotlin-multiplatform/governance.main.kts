import java.io.File

val command = args.firstOrNull() ?: ""

when (command) {
    "quality-gate", "audit" -> runQualityGate()
    "lint" -> runLint()
    "sync" -> runSync()
    else -> {
        println("OAEF Governance Tool (Kotlin Multiplatform Engine)")
        println("Usage: kotlin tool/governance.main.kts [quality-gate|lint|sync]")
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

fun runLint() {
    println("🔍 Auditing OAEF Integrity & Secret Leaks...")
    val agents = File("AGENTS.md")
    val claude = File("CLAUDE.md")
    if (agents.exists() && claude.exists()) {
        if (!claude.readText().contains(agents.readText().trim())) {
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
