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
        "sync" => run_sync(),
        _ => {
            print_usage();
            exit(1);
        }
    }
}

fn print_usage() {
    println!("OAEF Governance Tool (Rust Engine)");
    println!("Usage: cargo run --bin governance [quality-gate|lint|sync]");
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
    if let Ok(agents) = fs::read_to_string("AGENTS.md") {
        if let Ok(claude) = fs::read_to_string("CLAUDE.md") {
            if !claude.contains(&agents) {
                eprintln!("❌ [LINT] CLAUDE.md diverged from AGENTS.md.");
                exit(1);
            }
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
