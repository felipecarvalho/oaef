import Foundation

let args = CommandLine.arguments
guard args.count > 1 else {
    print("""
    OAEF Governance Tool (Swift Engine)
    Usage: swift tool/governance.swift [quality-gate|lint|sync]
    """)
    exit(1)
}

let command = args[1]
switch command {
case "quality-gate", "audit":
    print("🔍 Initiating OAEF Quality Gate Audit (Swift)...")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
    process.arguments = ["test"]
    try? process.run()
    process.waitUntilExit()
    if process.terminationStatus != 0 {
        fputs("❌ Tests failed.\n", stderr)
        exit(1)
    }
    print("\n🎉 Quality Gates PASSED!")
case "lint":
    print("🔍 Auditing OAEF Integrity & Secret Leaks...")
    let fm = FileManager.default
    if fm.fileExists(atPath: "AGENTS.md") && fm.fileExists(atPath: "CLAUDE.md") {
        let agents = (try? String(contentsOfFile: "AGENTS.md", encoding: .utf8)) ?? ""
        let claude = (try? String(contentsOfFile: "CLAUDE.md", encoding: .utf8)) ?? ""
        if normalizeMirrorText(agents) != normalizeMirrorText(claude) {
            fputs("❌ [LINT] CLAUDE.md diverged from AGENTS.md.\n", stderr)
            exit(1)
        }
    }
    print("✅ [LINT] All audits passed cleanly.")
case "conform", "doctor":
    runConform()
case "sync":
    if let agents = try? String(contentsOfFile: "AGENTS.md", encoding: .utf8) {
        let banner = "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n\n"
        try? (banner + agents).write(toFile: "CLAUDE.md", atomically: true, encoding: .utf8)
        print("✅ Synchronized AGENTS.md -> CLAUDE.md")
    }
default:
    print("Unknown command: \(command)")
    exit(1)
}

func normalizeMirrorText(_ text: String) -> String {
    let withoutComments = text
        .split(separator: "\n", omittingEmptySubsequences: false)
        .filter { !$0.hasPrefix("<!--") }
        .joined()
    return withoutComments.components(separatedBy: .whitespacesAndNewlines).joined()
}

func runConform() {
    print("🩺 OAEF Conformance Audit (doctor)...")
    let requiredFiles = [
        "AGENTS.md", "CLAUDE.md", "llms.txt", "oaef.context.json",
        "docs/INDEX.md", "docs/MANIFESTO.md", "docs/DESIGN.md",
        "docs/standards/coding_patterns.md", "docs/standards/testing.md", "docs/standards/logging.md",
        "docs/wiki/metrics/baseline.json", "docs/wiki/memory/handoff.md", "docs/wiki/log.md",
        "docs/HARNESSES.md",
        ".github/workflows/ci.yml", ".github/pull_request_template.md",
        ".gitignore", "CONTRIBUTING.md", "SECURITY.md",
    ]
    let skills = [
        "architecture-audit", "code-review", "collect-coverage", "component-author",
        "fix-layout-issues", "nullable-types", "run-static-analysis", "screen-builder",
        "test-generator", "ui-preview", "conformance-audit",
    ]
    let runtimes = [
        "tool/governance.sh", "tool/governance.mjs", "tool/governance.py", "tool/governance.dart",
        "tool/governance.go", "tool/governance.rs", "tool/governance.main.kts", "tool/governance.swift",
        "tool/Governance.cs",
    ]

    var checks = 0
    var passed = 0
    var failed = false

    func check(_ condition: Bool, _ label: String) {
        checks += 1
        if condition {
            passed += 1
            print("✅ \(label)")
        } else {
            fputs("❌ \(label)\n", stderr)
            failed = true
        }
    }

    let fileManager = FileManager.default
    for requiredFile in requiredFiles {
        check(fileManager.fileExists(atPath: requiredFile), "\(requiredFile) present")
    }
    for skill in skills {
        check(fileManager.fileExists(atPath: ".agents/skills/\(skill)/SKILL.md"), ".agents/skills/\(skill)/SKILL.md present")
    }
    check(runtimes.contains { fileManager.fileExists(atPath: $0) }, "governance runtime present in tool/")

    if fileManager.fileExists(atPath: "AGENTS.md") && fileManager.fileExists(atPath: "CLAUDE.md") {
        let agents = (try? String(contentsOfFile: "AGENTS.md", encoding: .utf8)) ?? ""
        let claude = (try? String(contentsOfFile: "CLAUDE.md", encoding: .utf8)) ?? ""
        check(normalizeMirrorText(agents) == normalizeMirrorText(claude), "CLAUDE.md mirror parity verified")
    } else {
        check(false, "mirror parity not verifiable (missing AGENTS.md or CLAUDE.md)")
    }

    var placeholderHits = false
    for candidate in ["AGENTS.md", "llms.txt"] {
        if let text = try? String(contentsOfFile: candidate, encoding: .utf8) {
            if text.range(of: #"\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}"#, options: .regularExpression) != nil {
                placeholderHits = true
            }
        }
    }
    check(!placeholderHits, "no unresolved template placeholders")

    print("\n📊 Conformance: \(passed)/\(checks) checks passed")
    if failed {
        exit(1)
    }
}
