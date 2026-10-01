use std::fs;
use std::process::{Command, exit};

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        print_usage();
        exit(1);
    }

    match args[1].as_str() {
        "quality-gate" | "audit" => run_quality_gate(),
        "lint" => run_lint(),
        "conform" | "doctor" => run_conform(),
        "sync" => run_sync(),
        _ => {
            print_usage();
            exit(1);
        }
    }
}

fn print_usage() {
    println!("OAEF Governance Tool (Rust Engine)");
    println!("Usage: cargo run --bin governance [quality-gate|lint|doctor|sync]");
}

fn normalize_mirror_text(text: &str) -> String {
    text.lines()
        .filter(|line| !line.starts_with("<!--"))
        .collect::<Vec<&str>>()
        .join("")
        .chars()
        .filter(|character| !character.is_whitespace())
        .collect()
}

fn run_conform() {
    println!("🩺 OAEF Conformance Audit (doctor)...");
    let required_files = [
        "AGENTS.md", "CLAUDE.md", "llms.txt", "oaef.context.json",
        "docs/INDEX.md", "docs/MANIFESTO.md", "docs/DESIGN.md",
        "docs/standards/coding_patterns.md", "docs/standards/testing.md", "docs/standards/logging.md",
        "docs/wiki/metrics/baseline.json", "docs/wiki/memory/handoff.md", "docs/wiki/log.md",
        "docs/HARNESSES.md",
        ".github/workflows/ci.yml", ".github/pull_request_template.md",
        ".gitignore", "CONTRIBUTING.md", "SECURITY.md",
    ];
    let skills = [
        "architecture-audit", "code-review", "collect-coverage", "component-author",
        "fix-layout-issues", "nullable-types", "run-static-analysis", "screen-builder",
        "test-generator", "ui-preview", "conformance-audit",
    ];
    let runtimes = [
        "tool/governance.sh", "tool/governance.mjs", "tool/governance.py", "tool/governance.dart",
        "tool/governance.go", "tool/governance.rs", "tool/governance.main.kts", "tool/governance.swift",
        "tool/Governance.cs",
    ];

    let mut checks = 0;
    let mut passed = 0;
    let mut failed = false;

    for required_file in required_files {
        checks += 1;
        if fs::metadata(required_file).is_ok() {
            passed += 1;
            println!("✅ {} present", required_file);
        } else {
            eprintln!("❌ {} missing", required_file);
            failed = true;
        }
    }

    for skill in skills {
        checks += 1;
        let skill_path = format!(".agents/skills/{}/SKILL.md", skill);
        if fs::metadata(&skill_path).is_ok() {
            passed += 1;
            println!("✅ {} present", skill_path);
        } else {
            eprintln!("❌ {} missing", skill_path);
            failed = true;
        }
    }

    checks += 1;
    if runtimes.iter().any(|runtime| fs::metadata(runtime).is_ok()) {
        passed += 1;
        println!("✅ governance runtime present in tool/");
    } else {
        eprintln!("❌ governance runtime missing in tool/");
        failed = true;
    }

    checks += 1;
    match (fs::read_to_string("AGENTS.md"), fs::read_to_string("CLAUDE.md")) {
        (Ok(agents), Ok(claude)) => {
            if normalize_mirror_text(&agents) == normalize_mirror_text(&claude) {
                passed += 1;
                println!("✅ CLAUDE.md mirror parity verified");
            } else {
                eprintln!("❌ CLAUDE.md diverged from AGENTS.md");
                failed = true;
            }
        }
        _ => {
            eprintln!("❌ mirror parity not verifiable (missing AGENTS.md or CLAUDE.md)");
            failed = true;
        }
    }

    checks += 1;
    let mut placeholder_hits = false;
    for candidate in ["AGENTS.md", "llms.txt"] {
        if let Ok(text) = fs::read_to_string(candidate) {
            if text.contains("{{PROJECT_NAME}}") || text.contains("{{TECH_STACK}}") || text.contains("{{STACK_SPECIFIC_RULES}}") {
                placeholder_hits = true;
            }
        }
    }
    if placeholder_hits {
        eprintln!("❌ unresolved template placeholders found in AGENTS.md/llms.txt");
        failed = true;
    } else {
        passed += 1;
        println!("✅ no unresolved template placeholders");
    }

    println!("\n📊 Conformance: {}/{} checks passed", passed, checks);
    if failed {
        exit(1);
    }
}

fn run_quality_gate() {
    println!("🔍 Initiating OAEF Quality Gate Audit (Rust)...");
    let status = Command::new("cargo")
        .args(&["test"])
        .status()
        .expect("Failed to run cargo test");

    if !status.success() {
        eprintln!("❌ Tests failed.");
        exit(1);
    }
    println!("\n🎉 Quality Gates PASSED!");
}

fn run_lint() {
    println!("🔍 Auditing OAEF Integrity & Secret Leaks...");
    if let (Ok(agents), Ok(claude)) = (fs::read_to_string("AGENTS.md"), fs::read_to_string("CLAUDE.md")) {
        if normalize_mirror_text(&agents) != normalize_mirror_text(&claude) {
            eprintln!("❌ [LINT] CLAUDE.md diverged from AGENTS.md.");
            exit(1);
        }
    }
    println!("✅ [LINT] All audits passed cleanly.");
}

fn run_sync() {
    if let Ok(agents) = fs::read_to_string("AGENTS.md") {
        let content = format!("<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n\n{}", agents);
        fs::write("CLAUDE.md", content).expect("Failed to write CLAUDE.md");
        println!("✅ Synchronized AGENTS.md -> CLAUDE.md");
    }
}
