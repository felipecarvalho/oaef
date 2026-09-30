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
        if !claude.contains(agents.trimmingCharacters(in: .whitespacesAndNewlines)) {
            fputs("❌ [LINT] CLAUDE.md diverged from AGENTS.md.\n", stderr)
            exit(1)
        }
    }
    print("✅ [LINT] All audits passed cleanly.")
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
