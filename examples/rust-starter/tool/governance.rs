// ==============================================================================
// OAEF Rust Governance Engine
// Implements docs/standards/governance_checks.md for the `rust` stack.
// Author: Felipe Carvalho | License: Apache 2.0
//
// Single-file, standard-library-only engine. `bin/oaef` compiles it with
// `rustc -O tool/governance.rs -o .oaef/governance-rust` and runs the binary.
// ==============================================================================

use std::fs;
use std::path::{Path, PathBuf};
use std::process::exit;

// ------------------------------------------------------------------------------
// Canonical catalog (must stay byte-identical to AGENTS.md section 3)
// ------------------------------------------------------------------------------
const SKILLS: [&str; 13] = [
    "ponytail",
    "nullable-types",
    "architecture-audit",
    "screen-builder",
    "component-author",
    "responsive-layout",
    "ui-preview",
    "fix-layout-issues",
    "test-generator",
    "collect-coverage",
    "run-static-analysis",
    "code-review",
    "conformance-audit",
];

const MIRROR_DIRS: [&str; 5] = [
    ".claude/skills",
    ".cursor/rules",
    ".windsurf/skills",
    ".cline/skills",
    ".grok/agents",
];

const CRYPTIC: [&str; 20] = [
    "cb", "fn", "res", "req", "btn", "val", "tmp", "ctx", "el", "usr", "mgr", "idx", "cnt", "buf", "str",
    "num", "doc", "elem", "curr", "prev",
];

const SECRET_NAMES: [&str; 5] = ["api_key", "apikey", "secret", "password", "token"];

const TERRITORY: [&str; 12] = [
    "features", "screens", "pages", "components", "shared", "ui", "core", "domain", "data", "infra", "test",
    "tests",
];

const RECIPES: [&str; 5] = [
    "1. Feature / Screen Construction: ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review",
    "2. Reusable Component / Module Authoring: ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis",
    "3. Bug Fix / Root-Cause Remediation: ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis",
    "4. Domain, Data & Infrastructure: ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis",
    "5. Pre-Submission / Pull Request Cycle: collect-coverage -> run-static-analysis -> code-review",
];

const FIXTURES: [(&str, &str); 12] = [
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
];

const REQUIRED_FILES: [&str; 24] = [
    "AGENTS.md",
    "CLAUDE.md",
    "llms.txt",
    "oaef.context.json",
    "docs/INDEX.md",
    "docs/MANIFESTO.md",
    "docs/DESIGN.md",
    "docs/HARNESSES.md",
    "docs/standards/coding_patterns.md",
    "docs/standards/testing.md",
    "docs/standards/logging.md",
    "docs/standards/clean_code.md",
    "docs/standards/solid.md",
    "docs/standards/review.md",
    "docs/standards/analytics_and_telemetry.md",
    "docs/standards/governance_checks.md",
    "docs/wiki/metrics/baseline.json",
    "docs/wiki/memory/handoff.md",
    "docs/wiki/log.md",
    ".github/workflows/ci.yml",
    ".github/pull_request_template.md",
    ".gitignore",
    "CONTRIBUTING.md",
    "SECURITY.md",
];

const MSG_CC01: &str = "prohibited single-letter identifier \"{}\"; use a descriptive name";
const MSG_CC02: &str = "prohibited cryptic abbreviation \"{}\"; use the full identifier";
const MSG_CC04: &str = "prohibited hardcoded placeholder/secret; source it from configuration/environment";
const MSG_CC05: &str = "prohibited raw print/debug output in production code; use the logging interface";
const MSG_CC06: &str = "prohibited silent exception swallowing; log with error+stack trace or rethrow";
const MSG_CC09: &str = "prohibited unimplemented placeholder in production contract; implement the contract (LSP)";
const MSG_CC11: &str =
    "[advisory] avoidable allocation on hot path; inspect without copying and return the original reference";

const CONTEXT_FILE: &str = "oaef.context.json";
const BASELINE_FILE: &str = "docs/wiki/metrics/baseline.json";
const ADOPTION_LEDGER: &str = "docs/wiki/metrics/adoption.json";
const AGENTS_FILE: &str = "AGENTS.md";

fn skill_triggers(skill: &str) -> &'static str {
    match skill {
        "ponytail" => "new|refactor|add|simple|minimal|yagni|dead code|delete|remove",
        "screen-builder" => "screen|page|feature|flow|view",
        "component-author" => "component|widget|button|card|modal",
        "ui-preview" => "preview|storybook|isolated render",
        "responsive-layout" => "responsive|adaptive|breakpoint|tablet|foldable|viewport",
        "fix-layout-issues" => "overflow|unbounded|layout|layout broken|render error",
        "test-generator" => "test|coverage|mock|fixture",
        "collect-coverage" => "coverage|lcov|jacoco|cobertura|branches",
        "run-static-analysis" => "analyze|lint|typecheck|warnings",
        "nullable-types" => "null|optional|nil|guard clause|defensive",
        "architecture-audit" => "architecture|boundary|coupling|cycle",
        "conformance-audit" => "conformance|doctor|parity|frontmatter",
        "code-review" => "review|pr|checklist|pre-pr",
        _ => "",
    }
}

fn skill_meta(skill: &str) -> &'static str {
    match skill {
        "ponytail" | "collect-coverage" | "run-static-analysis" | "conformance-audit" => "—",
        _ => "ponytail",
    }
}

fn skill_dir(skill: &str) -> String {
    format!(".agents/skills/{}", skill)
}

// ------------------------------------------------------------------------------
// Engine state
// ------------------------------------------------------------------------------
struct Engine {
    profile: String,
    adoption_mode: String,
    cc_counts: [u64; 11],
    cc_total: u64,
    sk_failures: u64,
}

impl Engine {
    fn new() -> Engine {
        Engine {
            profile: "strict".to_string(),
            adoption_mode: "install".to_string(),
            cc_counts: [0; 11],
            cc_total: 0,
            sk_failures: 0,
        }
    }

    fn resolve_profile(&mut self) {
        self.profile = "strict".to_string();
        self.adoption_mode = "install".to_string();
        if let Some(value) = json_string_value("strictness", CONTEXT_FILE) {
            self.profile = value;
        } else if let Some(value) = json_string_value("profile", BASELINE_FILE) {
            self.profile = value;
        }
        if let Some(value) = json_string_value("adoption_mode", CONTEXT_FILE) {
            self.adoption_mode = value;
        }
    }

    fn is_adoption(&self) -> bool {
        self.adoption_mode != "install"
    }

    fn cc_blocking(&self, id: &str) -> bool {
        if id == "CC-11" {
            return false;
        }
        if id == "CC-04" {
            return true;
        }
        if self.is_adoption() {
            return false;
        }
        self.profile == "strict"
    }

    fn cc_threshold(&self, id: &str) -> f64 {
        let key = match id {
            "CC-01" => "max_single_letter_identifiers",
            "CC-02" => "max_cryptic_abbreviations",
            "CC-03" => "max_mutable_lazy_initializations",
            "CC-04" => "max_dummy_keys",
            "CC-05" => "max_raw_prints",
            "CC-06" => "max_silent_catches",
            "CC-07" => "max_service_locator_leaks",
            "CC-08" => "max_nullable_collections",
            "CC-09" => "max_unimplemented_placeholders",
            "CC-10" => "max_concrete_client_instantiations",
            "CC-11" => "max_silent_catches",
            _ => "",
        };
        if key.is_empty() {
            return 0.0;
        }
        json_number_value(key, BASELINE_FILE).unwrap_or(0.0)
    }

    fn blocking_total(&self) -> u64 {
        let mut total = 0;
        for number in 1..=11usize {
            let id = format!("CC-{:02}", number);
            let count = self.cc_counts[number - 1];
            if count == 0 {
                continue;
            }
            if self.cc_blocking(&id) && (count as f64) > self.cc_threshold(&id) {
                total += count;
            }
        }
        total
    }

    fn behavior(&self) -> &'static str {
        if self.cc_blocking("CC-01") {
            "blocking"
        } else {
            "advisory"
        }
    }

    fn emit(&mut self, id: &str, path: &str, line: u64, message: &str) {
        println!("{} {}:{} — {}", id, path, line, message);
        if let Some(index) = cc_index(id) {
            self.cc_counts[index] += 1;
            self.cc_total += 1;
        }
    }

    fn emit_skill(&mut self, id: &str, path: &str, line: u64, message: &str) {
        println!("{} {}:{} — {}", id, path, line, message);
        self.sk_failures += 1;
    }

    // --------------------------------------------------------------------------
    // CC-* : rust realization
    // --------------------------------------------------------------------------
    fn scan_clean_code(&mut self) {
        for path in production_files() {
            self.check_production_file(&path);
        }
        for path in all_rust_files() {
            self.check_hot_allocation(&path);
        }
    }

    fn check_production_file(&mut self, path: &str) {
        let text = match read_text(path) {
            Some(value) => value,
            None => return,
        };
        let code = mask_noncode(&text, true);
        let code_lines: Vec<&str> = code.split('\n').collect();
        let strings = mask_noncode(&text, false);
        let string_lines: Vec<&str> = strings.split('\n').collect();
        self.check_identifiers(path, &code_lines);
        self.check_secrets(path, &string_lines);
        self.check_raw_prints(path, &code_lines);
        self.check_silent_catches(path, &code_lines);
        self.check_unimplemented(path, &code_lines);
    }

    fn check_identifiers(&mut self, path: &str, lines: &[&str]) {
        for (index, raw) in lines.iter().enumerate() {
            let lineno = (index + 1) as u64;
            let tokens = tokenize(raw);
            let mut bindings = binding_sites(&tokens);
            bindings.extend(fn_parameters(&tokens).into_iter().map(|name| (name, false)));
            for (name, from_for) in bindings {
                if name.chars().count() == 1 {
                    if name == "_" {
                        continue;
                    }
                    if (name == "i" || name == "j") && from_for {
                        continue;
                    }
                    let message = MSG_CC01.replace("{}", &name);
                    self.emit("CC-01", path, lineno, &message);
                } else if CRYPTIC.contains(&name.as_str()) {
                    let message = MSG_CC02.replace("{}", &name);
                    self.emit("CC-02", path, lineno, &message);
                }
            }
        }
    }

    fn check_secrets(&mut self, path: &str, lines: &[&str]) {
        for (index, line) in lines.iter().enumerate() {
            let lineno = (index + 1) as u64;
            if line.contains("dummy_") || line.contains("changeme") || line.contains("TODO_KEY") {
                self.emit("CC-04", path, lineno, MSG_CC04);
                continue;
            }
            if line.contains("env::var") || line.contains("std::env") || line.contains("env!") {
                continue;
            }
            let chars: Vec<char> = line.chars().collect();
            let mut cursor = 0usize;
            let mut found = false;
            while cursor < chars.len() && !found {
                if is_ident_char(chars[cursor]) && (cursor == 0 || !is_ident_char(chars[cursor - 1])) {
                    let start = cursor;
                    while cursor < chars.len() && is_ident_char(chars[cursor]) {
                        cursor += 1;
                    }
                    let name: String = chars[start..cursor].iter().collect();
                    if SECRET_NAMES.contains(&name.as_str()) {
                        let mut probe = cursor;
                        while probe < chars.len() && chars[probe].is_whitespace() {
                            probe += 1;
                        }
                        if probe < chars.len() && (chars[probe] == '=' || chars[probe] == ':') {
                            let separator = chars[probe];
                            let mut after = probe + 1;
                            let compound = (separator == '='
                                && after < chars.len()
                                && (chars[after] == '=' || chars[after] == '>'))
                                || (separator == ':' && after < chars.len() && chars[after] == ':');
                            if !compound {
                                while after < chars.len() && chars[after].is_whitespace() {
                                    after += 1;
                                }
                                if after < chars.len() && chars[after] == '"' {
                                    found = true;
                                }
                            }
                        }
                    }
                    continue;
                }
                cursor += 1;
            }
            if found {
                self.emit("CC-04", path, lineno, MSG_CC04);
            }
        }
    }

    fn check_raw_prints(&mut self, path: &str, lines: &[&str]) {
        for (index, line) in lines.iter().enumerate() {
            if macro_call(line, "println") || macro_call(line, "print") || macro_call(line, "dbg") {
                self.emit("CC-05", path, (index + 1) as u64, MSG_CC05);
            }
        }
    }

    fn check_silent_catches(&mut self, path: &str, lines: &[&str]) {
        let mut index = 0usize;
        while index < lines.len() {
            let line = lines[index];
            let lineno = (index + 1) as u64;
            if let Some(brace) = handler_brace(line) {
                let after = &line[brace + 1..];
                if body_is_empty(lines, index, after) {
                    self.emit("CC-06", path, lineno, MSG_CC06);
                }
            } else if discarded_result(line) {
                self.emit("CC-06", path, lineno, MSG_CC06);
            }
            index += 1;
        }
    }

    fn check_unimplemented(&mut self, path: &str, lines: &[&str]) {
        for (index, line) in lines.iter().enumerate() {
            if macro_call(line, "unimplemented") || macro_call(line, "todo") {
                self.emit("CC-09", path, (index + 1) as u64, MSG_CC09);
            }
        }
    }

    fn check_hot_allocation(&mut self, path: &str) {
        let text = match read_text(path) {
            Some(value) => value,
            None => return,
        };
        let masked = mask_noncode(&text, true);
        let bytes = masked.as_bytes();
        let mut line = 1u64;
        let mut open_stack: Vec<bool> = Vec::new();
        let mut statement = String::new();
        let mut cursor = 0usize;
        while cursor < bytes.len() {
            let byte = bytes[cursor];
            if byte == b'\n' {
                line += 1;
                cursor += 1;
                continue;
            }
            if byte == b'.' && bytes[cursor..].starts_with(b".clone()") {
                if open_stack.iter().any(|flag| *flag) {
                    self.emit("CC-11", path, line, MSG_CC11);
                }
                cursor += 8;
                continue;
            }
            if byte == b'{' {
                let is_loop = contains_word(&statement, "for")
                    || contains_word(&statement, "while")
                    || contains_word(&statement, "loop");
                open_stack.push(is_loop);
                statement.clear();
                cursor += 1;
                continue;
            }
            if byte == b'}' {
                open_stack.pop();
                statement.clear();
                cursor += 1;
                continue;
            }
            if byte == b';' {
                statement.clear();
                cursor += 1;
                continue;
            }
            if statement.len() < 240 {
                statement.push(byte as char);
            }
            cursor += 1;
        }
    }

    // --------------------------------------------------------------------------
    // PT-01 / ponytail
    // --------------------------------------------------------------------------
    fn run_ponytail_debt(&mut self) {
        self.scan_debt_markers();
    }

    fn scan_debt_markers(&mut self) {
        for path in production_files() {
            let text = match read_text(&path) {
                Some(value) => value,
                None => continue,
            };
            for (index, line) in text.split('\n').enumerate() {
                let marker_at = match line.find("ponytail:") {
                    Some(position) => position,
                    None => continue,
                };
                let prefix = &line[..marker_at];
                if !(prefix.contains("//") || prefix.contains('#') || prefix.contains("--") || prefix.contains("/*") || prefix.contains("<!--")) {
                    continue;
                }
                let reason = line[marker_at + "ponytail:".len()..].trim().to_string();
                println!("PT-01 {}:{} — {}", path, index + 1, reason);
            }
        }
    }

    fn run_ponytail_audit(&mut self) {
        self.scan_debt_markers();
        for path in production_files() {
            let text = match read_text(&path) {
                Some(value) => value,
                None => continue,
            };
            for (index, line) in text.split('\n').enumerate() {
                if narration_comment(line) {
                    println!("[advisory] [DELETE] {}:{} — narration comment restates the next line", path, index + 1);
                }
                if delegation_arrow(line) || delegation_block(line) {
                    println!(
                        "[advisory] [SHRINK] {}:{} — single-statement delegation; verify a caller justifies the layer",
                        path,
                        index + 1
                    );
                }
            }
        }
    }

    // --------------------------------------------------------------------------
    // SK-01 .. SK-06
    // --------------------------------------------------------------------------
    fn audit_skills_parity(&mut self) {
        for skill in SKILLS.iter() {
            let skill_path = format!("{}/SKILL.md", skill_dir(skill));
            if !Path::new(&skill_path).is_file() {
                let message = format!("skill \"{}\" is not listed in .agents/skills (parity required)", skill);
                self.emit_skill("SK-01", &skill_dir(skill), 0, &message);
                continue;
            }
            if Path::new(AGENTS_FILE).is_file() {
                if let Some(agents) = read_text(AGENTS_FILE) {
                    if !agents.contains(&format!("`{}`", skill)) {
                        let message = format!("skill \"{}\" is not listed in AGENTS.md (parity required)", skill);
                        self.emit_skill("SK-01", AGENTS_FILE, 0, &message);
                    }
                }
            }
            if Path::new("README.md").is_file() {
                if let Some(readme) = read_text("README.md") {
                    if !readme.contains(skill) {
                        let message = format!("skill \"{}\" is not listed in README.md (parity required)", skill);
                        self.emit_skill("SK-01", "README.md", 0, &message);
                    }
                }
            }
        }
    }

    fn audit_skills_frontmatter(&mut self) {
        for skill in SKILLS.iter() {
            let skill_path = format!("{}/SKILL.md", skill_dir(skill));
            if !Path::new(&skill_path).is_file() {
                continue;
            }
            if self.is_adoption() && user_owned_skill(skill) {
                continue;
            }
            let message = format!(
                "skill \"{}\" frontmatter must declare \"Use when\", \"Triggers on:\" and \"Chains into:\" with >=150 characters and name==directory",
                skill
            );
            let description = frontmatter_value(skill, "description");
            if description.is_empty()
                || !description.contains("Use when")
                || !description.contains("Triggers on:")
                || !description.contains("Chains into:")
                || description.chars().count() < 150
            {
                self.emit_skill("SK-02", &skill_path, 0, &message);
                continue;
            }
            if frontmatter_value(skill, "name") != *skill {
                self.emit_skill("SK-02", &skill_path, 0, &message);
                continue;
            }
            for key in frontmatter_keys(skill) {
                let allowed = matches!(
                    key.as_str(),
                    "name" | "description" | "argument-hint" | "license" | "metadata"
                );
                if !allowed {
                    self.emit_skill("SK-02", &skill_path, 0, &message);
                }
            }
            if !body_has_territory(&skill_path) {
                self.emit_skill("SK-02", &skill_path, 0, &message);
            }
        }
    }

    fn audit_entrypoint_parity(&mut self) {
        for skill in SKILLS.iter() {
            if Path::new("llms.txt").is_file() {
                if let Some(llms) = read_text("llms.txt") {
                    if !llms.contains(skill) {
                        let message = format!("skill \"{}\" is not listed in llms.txt", skill);
                        self.emit_skill("SK-03", "llms.txt", 0, &message);
                    }
                }
            }
        }
        for entry in ["README.md", "docs/INDEX.md", "docs/MANIFESTO.md"].iter() {
            if !Path::new(entry).is_file() {
                continue;
            }
            if let Some(text) = read_text(entry) {
                if !text.contains("llms.txt") {
                    let message = format!("entrypoint {} does not reference llms.txt", entry);
                    self.emit_skill("SK-03", entry, 0, &message);
                }
            }
        }
    }

    fn audit_trigger_coherence(&mut self) {
        let rows = matrix_rows();
        for skill in SKILLS.iter() {
            let prefix = format!("{}|", skill);
            let row = rows.iter().find(|candidate| candidate.starts_with(&prefix));
            let row = match row {
                Some(value) => value.clone(),
                None => {
                    let message = format!("skill \"{}\" has no dispatch-matrix row", skill);
                    self.emit_skill("SK-04", AGENTS_FILE, 0, &message);
                    continue;
                }
            };
            if self.is_adoption() && user_owned_skill(skill) {
                continue;
            }
            let triggers = match row.splitn(2, '|').nth(1) {
                Some(value) => value,
                None => continue,
            };
            let trimmed = triggers.trim_end_matches('|').trim();
            let blob = strip_quotes(trimmed).to_lowercase();
            if blob.is_empty() {
                continue;
            }
            let description = frontmatter_value(skill, "description").to_lowercase();
            if !description.contains(&blob) {
                let message = format!(
                    "trigger \"{}\" for skill \"{}\" is missing from its frontmatter \"Triggers on:\"",
                    blob, skill
                );
                self.emit_skill("SK-04", AGENTS_FILE, 0, &message);
            }
        }
    }

    fn audit_mirror_parity(&mut self) {
        for dir in MIRROR_DIRS.iter() {
            if !mirror_present(dir) {
                continue;
            }
            for skill in SKILLS.iter() {
                let canonical = format!("{}/SKILL.md", skill_dir(skill));
                if !Path::new(&canonical).is_file() {
                    continue;
                }
                let diverged = match mirror_of(dir, skill) {
                    Some(entry) => match (fs::read(&canonical), fs::read(&entry)) {
                        (Ok(left), Ok(right)) => left != right,
                        _ => true,
                    },
                    None => true,
                };
                if diverged {
                    let message = format!(
                        "harness mirror \"{}\" diverges from .agents/skills for skill \"{}\" (run: oaef skills sync-mirrors)",
                        dir, skill
                    );
                    self.emit_skill("SK-05", dir, 0, &message);
                }
            }
        }
    }

    fn run_skills_selftest(&mut self) {
        for (prompt, expected) in FIXTURES.iter() {
            let got = route_prompt(prompt);
            if got != *expected {
                let message = format!(
                    "routing self-test failed: prompt \"{}\" resolved to \"{}\" but expected \"{}\"",
                    prompt, got, expected
                );
                self.emit_skill("SK-06", AGENTS_FILE, 0, &message);
            }
        }
    }

    fn run_skills_audit(&mut self, argument: &str) {
        let selftest = argument == "--selftest";
        self.resolve_profile();
        self.audit_skills_parity();
        self.audit_skills_frontmatter();
        self.audit_entrypoint_parity();
        self.audit_trigger_coherence();
        self.audit_mirror_parity();
        if selftest {
            self.run_skills_selftest();
        }
        println!("Skills: {} finding(s)", self.sk_failures);
        if self.sk_failures > 0 {
            exit(1);
        }
    }

    fn run_skills_route(&mut self, query: &str) {
        let primary = route_prompt(query);
        println!("Routing: \"{}\"", query);
        println!("Primary skill: {} {}/SKILL.md", primary, skill_dir(&primary));
        println!("Meta-skill: {}", skill_meta(&primary));
        println!("Recipes containing {}:", primary);
        for recipe in RECIPES.iter() {
            if recipe.contains(&primary) {
                println!("  {}", recipe);
            }
        }
    }

    fn run_skills_sync_mirrors(&mut self, check_only: bool) {
        self.resolve_profile();
        let mut repaired = 0u64;
        for dir in MIRROR_DIRS.iter() {
            if !mirror_present(dir) {
                continue;
            }
            if is_symlink(dir) {
                if let Ok(target) = fs::read_link(dir) {
                    if target.to_string_lossy() == "../.agents/skills" && Path::new(dir).is_dir() {
                        println!("✅ {} is a symlink to .agents/skills (parity by construction)", dir);
                        continue;
                    }
                }
            }
            if !Path::new(dir).is_dir() {
                continue;
            }
            for skill in SKILLS.iter() {
                let canonical = format!("{}/SKILL.md", skill_dir(skill));
                if !Path::new(&canonical).is_file() {
                    continue;
                }
                if let Some(entry) = mirror_of(dir, skill) {
                    if !check_only {
                        let same = match (fs::read(&canonical), fs::read(&entry)) {
                            (Ok(left), Ok(right)) => left == right,
                            _ => false,
                        };
                        if !same && fs::copy(&canonical, &entry).is_ok() {
                            println!("🔧 {}: repaired mirror for {} (canonical catalog is authoritative)", dir, skill);
                            repaired += 1;
                        }
                    }
                    continue;
                }
                if check_only {
                    continue;
                }
                let target = format!("{}/{}", dir, skill);
                if make_symlink(&format!("../.agents/skills/{}", skill), &target) && Path::new(&target).exists() {
                    println!("🔧 {}: created mirror link for {}", dir, skill);
                } else {
                    let _ = fs::remove_file(&target);
                    if copy_dir(&skill_dir(skill), &target).is_ok() {
                        println!("🔧 {}: created mirror copy for {}", dir, skill);
                    }
                }
                repaired += 1;
            }
        }
        self.sk_failures = 0;
        self.audit_mirror_parity();
        if check_only {
            if self.sk_failures > 0 {
                println!("Mirrors: {} divergence(s) detected", self.sk_failures);
                exit(1);
            }
            println!("Mirrors: parity verified");
            return;
        }
        if self.sk_failures > 0 {
            println!("Mirrors: {} divergence(s) remain (user-owned entries are preserved)", self.sk_failures);
            exit(1);
        }
        println!("Mirrors: {} entry(ies) synchronized, parity verified", repaired);
    }

    // --------------------------------------------------------------------------
    // clean-code / quality-gate / lint / doctor / metrics / sync
    // --------------------------------------------------------------------------
    fn run_clean_code(&mut self, force_standard: bool) {
        self.resolve_profile();
        if force_standard {
            self.profile = "standard".to_string();
        }
        self.scan_clean_code();
        println!(
            "Clean Code: {} violation(s) ({} profile: {})",
            self.cc_total,
            self.profile,
            self.behavior()
        );
        if self.blocking_total() > 0 {
            exit(1);
        }
    }

    fn run_quality_gate(&mut self) {
        self.resolve_profile();
        println!("🔍 Initiating OAEF Quality Gate Audit (Rust)...");
        let mut oversized = 0u64;
        for file in production_files() {
            let lines = read_text(&file).map(|text| text.split('\n').count()).unwrap_or(0);
            if lines > 300 {
                eprintln!("⚠️  Oversized file ({}L > 300L): {}", lines, file);
                oversized += 1;
            }
        }
        if oversized > 0 {
            eprintln!("❌ Quality Gate Failed: {} oversized files detected.", oversized);
            exit(1);
        }
        self.scan_clean_code();
        println!(
            "Clean Code: {} violation(s) ({} profile: {})",
            self.cc_total,
            self.profile,
            self.behavior()
        );
        if self.profile == "strict" && !self.is_adoption() && self.blocking_total() > 0 {
            eprintln!("❌ Quality Gate Failed: {} clean-code violation(s).", self.cc_total);
            exit(1);
        }
        println!("🎉 Quality Gates PASSED!");
    }

    fn run_lint(&mut self) {
        self.resolve_profile();
        let mut failed = false;
        if Path::new(AGENTS_FILE).is_file() && Path::new("CLAUDE.md").is_file() {
            let agents = read_text(AGENTS_FILE).unwrap_or_default();
            let claude = read_text("CLAUDE.md").unwrap_or_default();
            if normalize_mirror_text(&agents) != normalize_mirror_text(&claude) {
                eprintln!("❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run \"oaef sync\".");
                failed = true;
            }
        }

        let secrets = scan_secrets_in_dir("docs");
        if !secrets.is_empty() {
            for hit in &secrets {
                println!("{}", hit);
            }
            eprintln!("🚨 [SECURITY] Potential secret detected in docs/!");
            failed = true;
        }

        let suppressions = scan_suppressions();
        if !suppressions.is_empty() {
            eprintln!("🚨 [LINT] Unallowed linter/compiler suppression comments detected:");
            for line in &suppressions {
                eprintln!("{}", line);
            }
            failed = true;
        }

        self.scan_clean_code();
        self.audit_skills_parity();
        self.audit_skills_frontmatter();
        self.audit_entrypoint_parity();
        self.audit_trigger_coherence();
        self.audit_mirror_parity();
        self.run_skills_selftest();
        if self.sk_failures > 0 {
            failed = true;
        }

        if failed {
            eprintln!("❌ LINT FAILED.");
            exit(1);
        }
        println!("✅ [LINT] All integrity and secret audits passed cleanly.");
    }

    fn run_conform(&mut self) {
        self.resolve_profile();
        let mut checks = 0u64;
        let mut passed = 0u64;
        let mut failed = false;
        println!("🩺 OAEF Conformance Audit (doctor)...");
        for required in REQUIRED_FILES.iter() {
            checks += 1;
            if Path::new(required).exists() {
                passed += 1;
                println!("✅ {} present", required);
            } else {
                eprintln!("❌ {} missing", required);
                failed = true;
            }
        }

        for skill in SKILLS.iter() {
            checks += 1;
            let skill_path = format!("{}/SKILL.md", skill_dir(skill));
            if Path::new(&skill_path).is_file() {
                passed += 1;
                println!("✅ {} present", skill_path);
            } else {
                eprintln!("❌ {} missing", skill_path);
                failed = true;
            }
        }

        checks += 1;
        let parity = match (read_text(AGENTS_FILE), read_text("CLAUDE.md")) {
            (Some(agents), Some(claude)) => normalize_mirror_text(&agents) == normalize_mirror_text(&claude),
            _ => false,
        };
        if parity {
            passed += 1;
            println!("✅ CLAUDE.md mirror parity verified");
        } else {
            eprintln!("❌ CLAUDE.md mirror parity failed (run oaef sync)");
            failed = true;
        }

        checks += 1;
        let mut placeholder_hits = false;
        for candidate in ["AGENTS.md", "llms.txt"].iter() {
            if let Some(text) = read_text(candidate) {
                if text.contains("{{PROJECT_NAME}}") || text.contains("{{TECH_STACK}}") || text.contains("{{STACK_SPECIFIC_RULES}}") {
                    placeholder_hits = true;
                }
            }
        }
        if placeholder_hits {
            eprintln!("❌ unresolved template placeholders found");
            failed = true;
        } else {
            passed += 1;
            println!("✅ no unresolved template placeholders");
        }

        checks += 1;
        self.sk_failures = 0;
        self.audit_mirror_parity();
        if self.sk_failures == 0 {
            passed += 1;
            println!("✅ harness mirror parity verified");
        } else {
            eprintln!("❌ harness mirror parity failed (run oaef skills sync-mirrors)");
            failed = true;
        }

        checks += 1;
        self.sk_failures = 0;
        self.run_skills_selftest();
        if self.sk_failures == 0 {
            passed += 1;
            println!("✅ routing self-test (SK-06) passed");
        } else {
            eprintln!("❌ routing self-test (SK-06) failed");
            failed = true;
        }

        println!("\n📊 Conformance: {}/{} checks passed", passed, checks);
        if failed {
            exit(1);
        }
    }

    fn run_metrics(&mut self) {
        if let Some(text) = read_text(BASELINE_FILE) {
            print!("{}", text);
        }
    }

    fn run_sync(&mut self) {
        if let Some(agents) = read_text(AGENTS_FILE) {
            let content = format!(
                "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n<!-- To modify rules, edit AGENTS.md and run 'oaef sync'. -->\n\n{}",
                agents
            );
            if fs::write("CLAUDE.md", content).is_ok() {
                println!("✅ Synchronized AGENTS.md -> CLAUDE.md");
            }
        }
    }
}

// ------------------------------------------------------------------------------
// JSON helpers (shape-tolerant, no external crate)
// ------------------------------------------------------------------------------
fn json_string_value(key: &str, file: &str) -> Option<String> {
    let text = read_text(file)?;
    let needle = format!("\"{}\"", key);
    let mut search = 0usize;
    while let Some(position) = text[search..].find(&needle) {
        let start = search + position + needle.len();
        let rest = text[start..].trim_start();
        if let Some(after_colon) = rest.strip_prefix(':') {
            let value = after_colon.trim_start();
            if let Some(after_quote) = value.strip_prefix('"') {
                if let Some(end) = after_quote.find('"') {
                    return Some(after_quote[..end].to_string());
                }
            }
        }
        search = start;
    }
    None
}

fn json_number_value(key: &str, file: &str) -> Option<f64> {
    let text = read_text(file)?;
    let needle = format!("\"{}\"", key);
    let position = text.find(&needle)?;
    let rest = text[position + needle.len()..].trim_start();
    let after_colon = rest.strip_prefix(':')?.trim_start();
    let digits: String = after_colon
        .chars()
        .take_while(|character| character.is_ascii_digit() || *character == '.')
        .collect();
    digits.parse::<f64>().ok()
}

fn user_owned_skill(skill: &str) -> bool {
    let text = match read_text(ADOPTION_LEDGER) {
        Some(value) => value,
        None => return false,
    };
    let anchor = match text.find("\"user_skills\"") {
        Some(position) => position,
        None => return false,
    };
    let after = &text[anchor..];
    let open = match after.find('[') {
        Some(position) => position,
        None => return false,
    };
    let close = match after[open..].find(']') {
        Some(position) => position,
        None => return false,
    };
    let array = &after[open + 1..open + close];
    let mut cursor = 0usize;
    while let Some(position) = array[cursor..].find('"') {
        let start = cursor + position + 1;
        if let Some(end) = array[start..].find('"') {
            if &array[start..start + end] == skill {
                return true;
            }
            cursor = start + end + 1;
        } else {
            break;
        }
    }
    false
}

// ------------------------------------------------------------------------------
// Scanning / masking helpers
// ------------------------------------------------------------------------------
fn read_text(path: &str) -> Option<String> {
    let bytes = fs::read(path).ok()?;
    String::from_utf8(bytes).ok()
}

fn mask_noncode(text: &str, blank_strings: bool) -> String {
    let bytes = text.as_bytes();
    let mut out = bytes.to_vec();
    let mut cursor = 0usize;
    while cursor < bytes.len() {
        let byte = bytes[cursor];
        if byte == b'/' && cursor + 1 < bytes.len() && bytes[cursor + 1] == b'/' {
            while cursor < bytes.len() && bytes[cursor] != b'\n' {
                out[cursor] = b' ';
                cursor += 1;
            }
            continue;
        }
        if byte == b'/' && cursor + 1 < bytes.len() && bytes[cursor + 1] == b'*' {
            let mut depth = 1usize;
            out[cursor] = b' ';
            out[cursor + 1] = b' ';
            cursor += 2;
            while cursor < bytes.len() && depth > 0 {
                if bytes[cursor] == b'\n' {
                    cursor += 1;
                    continue;
                }
                if bytes[cursor] == b'/' && cursor + 1 < bytes.len() && bytes[cursor + 1] == b'*' {
                    out[cursor] = b' ';
                    out[cursor + 1] = b' ';
                    depth += 1;
                    cursor += 2;
                    continue;
                }
                if bytes[cursor] == b'*' && cursor + 1 < bytes.len() && bytes[cursor + 1] == b'/' {
                    out[cursor] = b' ';
                    out[cursor + 1] = b' ';
                    depth -= 1;
                    cursor += 2;
                    continue;
                }
                out[cursor] = b' ';
                cursor += 1;
            }
            continue;
        }
        if blank_strings && byte == b'"' {
            out[cursor] = b' ';
            cursor += 1;
            while cursor < bytes.len() {
                if bytes[cursor] == b'\\' {
                    out[cursor] = b' ';
                    if cursor + 1 < bytes.len() {
                        out[cursor + 1] = b' ';
                    }
                    cursor += 2;
                    continue;
                }
                if bytes[cursor] == b'\n' {
                    break;
                }
                if bytes[cursor] == b'"' {
                    out[cursor] = b' ';
                    cursor += 1;
                    break;
                }
                out[cursor] = b' ';
                cursor += 1;
            }
            continue;
        }
        if blank_strings && byte == b'\'' {
            let mut probe = cursor + 1;
            if probe < bytes.len() && bytes[probe] == b'\\' {
                probe += 1;
            }
            if probe < bytes.len() {
                probe += 1;
            }
            if probe < bytes.len() && bytes[probe] == b'\'' {
                for index in cursor..=probe {
                    out[index] = b' ';
                }
                cursor = probe + 1;
                continue;
            }
        }
        cursor += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

fn is_ident_byte(byte: u8) -> bool {
    byte.is_ascii_alphanumeric() || byte == b'_'
}

fn is_ident_char(character: char) -> bool {
    character.is_ascii_alphanumeric() || character == '_'
}

fn is_ident(token: &str) -> bool {
    let mut characters = token.chars();
    match characters.next() {
        Some(first) if first.is_ascii_alphabetic() || first == '_' => characters.all(is_ident_char),
        _ => false,
    }
}

fn contains_word(haystack: &str, word: &str) -> bool {
    let bytes = haystack.as_bytes();
    let needle = word.as_bytes();
    if needle.len() > bytes.len() {
        return false;
    }
    let mut cursor = 0usize;
    while cursor + needle.len() <= bytes.len() {
        if &bytes[cursor..cursor + needle.len()] == needle {
            let before_ok = cursor == 0 || !is_ident_byte(bytes[cursor - 1]);
            let after_ok = cursor + needle.len() == bytes.len() || !is_ident_byte(bytes[cursor + needle.len()]);
            if before_ok && after_ok {
                return true;
            }
        }
        cursor += 1;
    }
    false
}

fn tokenize(line: &str) -> Vec<String> {
    let characters: Vec<char> = line.chars().collect();
    let mut out: Vec<String> = Vec::new();
    let mut cursor = 0usize;
    while cursor < characters.len() {
        let character = characters[cursor];
        if is_ident_char(character) {
            let start = cursor;
            while cursor < characters.len() && is_ident_char(characters[cursor]) {
                cursor += 1;
            }
            out.push(characters[start..cursor].iter().collect());
        } else if character.is_whitespace() {
            cursor += 1;
        } else {
            out.push(character.to_string());
            cursor += 1;
        }
    }
    out
}

fn binding_sites(tokens: &[String]) -> Vec<(String, bool)> {
    let mut out: Vec<(String, bool)> = Vec::new();
    let mut index = 0usize;
    while index < tokens.len() {
        let token = tokens[index].as_str();
        if token == "let" {
            let mut probe = index + 1;
            if probe < tokens.len() && tokens[probe] == "mut" {
                probe += 1;
            }
            if probe < tokens.len() && is_ident(&tokens[probe]) && tokens[probe] != "_" {
                out.push((tokens[probe].clone(), false));
            }
        } else if token == "for" {
            let mut probe = index + 1;
            while probe < tokens.len() && (tokens[probe] == "mut" || tokens[probe] == "ref" || tokens[probe] == "&") {
                probe += 1;
            }
            if probe < tokens.len() && is_ident(&tokens[probe]) {
                let mut next = probe + 1;
                while next < tokens.len() && (tokens[next] == "mut" || tokens[next] == "ref") {
                    next += 1;
                }
                if next < tokens.len() && tokens[next] == "in" {
                    out.push((tokens[probe].clone(), true));
                }
            }
        } else if token == "|" && closure_opener(&tokens, index) {
            let mut probe = index + 1;
            let mut segments: Vec<Vec<String>> = vec![Vec::new()];
            let mut closed = false;
            let mut valid = true;
            while probe < tokens.len() {
                let current = tokens[probe].as_str();
                if current == "|" {
                    closed = true;
                    break;
                }
                if is_ident(current) || current == "," || current == ":" || current == "&" || current == "::" {
                    if current == "," {
                        segments.push(Vec::new());
                    } else {
                        segments.last_mut().unwrap().push(current.to_string());
                    }
                } else {
                    valid = false;
                    break;
                }
                probe += 1;
            }
            if valid && closed {
                for segment in segments {
                    for word in segment.iter() {
                        if word == "mut" || word == "ref" || word == "&" {
                            continue;
                        }
                        if is_ident(word) {
                            if word != "_" {
                                out.push((word.clone(), false));
                            }
                            break;
                        }
                    }
                }
                index = probe;
            }
        }
        index += 1;
    }
    out
}

fn closure_opener(tokens: &[String], index: usize) -> bool {
    if index == 0 {
        return true;
    }
    matches!(
        tokens[index - 1].as_str(),
        "(" | "," | "=" | "=>" | "{" | ";" | "}" | "[" | ":" | "move" | "return"
    )
}

fn fn_parameters(tokens: &[String]) -> Vec<String> {
    let mut out: Vec<String> = Vec::new();
    let mut index = 0usize;
    while index < tokens.len() {
        if tokens[index] == "fn" {
            let mut probe = index + 1;
            while probe < tokens.len() && !is_ident(&tokens[probe]) {
                probe += 1;
            }
            if probe < tokens.len() {
                probe += 1;
            }
            while probe < tokens.len() && tokens[probe] != "(" && tokens[probe] != "{" && tokens[probe] != ";" {
                probe += 1;
            }
            if probe < tokens.len() && tokens[probe] == "(" {
                let mut depth = 1i32;
                probe += 1;
                let mut segment: Vec<String> = Vec::new();
                let mut segments: Vec<Vec<String>> = Vec::new();
                while probe < tokens.len() {
                    let current = tokens[probe].as_str();
                    if current == "(" {
                        depth += 1;
                        segment.push(current.to_string());
                    } else if current == ")" {
                        depth -= 1;
                        if depth == 0 {
                            segments.push(segment.clone());
                            break;
                        }
                        segment.push(current.to_string());
                    } else if current == "," && depth == 1 {
                        segments.push(segment.clone());
                        segment.clear();
                    } else {
                        segment.push(current.to_string());
                    }
                    probe += 1;
                }
                for entry in segments {
                    for word in entry.iter() {
                        if word == "&" || word == "mut" || word == "ref" {
                            continue;
                        }
                        if is_ident(word) {
                            out.push(word.clone());
                            break;
                        }
                    }
                }
                index = probe;
            }
        }
        index += 1;
    }
    out
}

fn macro_call(line: &str, name: &str) -> bool {
    let bytes = line.as_bytes();
    let needle = name.as_bytes();
    if needle.is_empty() || needle.len() > bytes.len() {
        return false;
    }
    let mut cursor = 0usize;
    while cursor + needle.len() <= bytes.len() {
        if &bytes[cursor..cursor + needle.len()] == needle {
            let before_ok = cursor == 0 || !is_ident_byte(bytes[cursor - 1]);
            let mut probe = cursor + needle.len();
            let after_ok = probe >= bytes.len() || !is_ident_byte(bytes[probe]);
            if before_ok && after_ok {
                while probe < bytes.len() && (bytes[probe] == b' ' || bytes[probe] == b'\t') {
                    probe += 1;
                }
                if probe < bytes.len() && bytes[probe] == b'!' {
                    probe += 1;
                    while probe < bytes.len() && (bytes[probe] == b' ' || bytes[probe] == b'\t') {
                        probe += 1;
                    }
                    if probe < bytes.len() && bytes[probe] == b'(' {
                        return true;
                    }
                }
            }
        }
        cursor += 1;
    }
    false
}

fn handler_brace(line: &str) -> Option<usize> {
    if let Some(position) = line.find("if let Err(_)") {
        if let Some(offset) = line[position..].find('{') {
            return Some(position + offset);
        }
    }
    if let Some(position) = line.find("Err(_)") {
        let after = &line[position + 6..];
        let trimmed = after.trim_start();
        if let Some(rest) = trimmed.strip_prefix("=>") {
            let rest_trimmed = rest.trim_start();
            if let Some(offset) = rest_trimmed.find('{') {
                return Some(line.len() - rest_trimmed.len() + offset);
            }
        }
    }
    None
}

fn body_is_empty(lines: &[&str], index: usize, after_brace: &str) -> bool {
    let rest = after_brace.trim_start();
    if rest.starts_with('}') {
        return true;
    }
    if !rest.is_empty() {
        return false;
    }
    let mut probe = index + 1;
    while probe < lines.len() {
        let trimmed = lines[probe].trim();
        if trimmed.is_empty() {
            probe += 1;
            continue;
        }
        return trimmed.starts_with('}');
    }
    false
}

fn discarded_result(line: &str) -> bool {
    let mut search = 0usize;
    while let Some(position) = line[search..].find(".ok()") {
        let absolute = search + position;
        let after = line[absolute + 5..].trim_start();
        if after.starts_with(';') && !has_plain_assignment(&line[..absolute]) {
            return true;
        }
        search = absolute + 5;
    }
    false
}

fn has_plain_assignment(fragment: &str) -> bool {
    let bytes = fragment.as_bytes();
    let mut cursor = 0usize;
    while cursor < bytes.len() {
        if bytes[cursor] == b'=' {
            let previous = if cursor == 0 { 0 } else { bytes[cursor - 1] };
            let next = if cursor + 1 < bytes.len() { bytes[cursor + 1] } else { 0 };
            if next != b'=' && next != b'>' && previous != b'=' && previous != b'!' && previous != b'<' && previous != b'>' {
                return true;
            }
        }
        cursor += 1;
    }
    false
}

fn narration_comment(line: &str) -> bool {
    let trimmed = line.trim_start();
    let rest = if let Some(value) = trimmed.strip_prefix("//") {
        value
    } else if let Some(value) = trimmed.strip_prefix('#') {
        value
    } else {
        return false;
    };
    let rest = rest.trim_start();
    let keyword: String = rest.chars().take_while(|character| character.is_ascii_alphabetic()).collect();
    let keywords = [
        "increment",
        "decrement",
        "set",
        "assign",
        "call",
        "return",
        "loop",
        "iterate",
        "initialize",
        "create",
        "check",
        "store",
    ];
    if !keywords.contains(&keyword.as_str()) {
        return false;
    }
    rest.chars().nth(keyword.chars().count()).map(|c| c.is_whitespace()).unwrap_or(false)
}

fn delegation_arrow(line: &str) -> bool {
    let trimmed = line.trim_end();
    let trimmed = trimmed.strip_suffix(';').unwrap_or(trimmed).trim_end();
    let position = match trimmed.find("=>") {
        Some(value) => value,
        None => return false,
    };
    delegation_call(trimmed[position + 2..].trim())
}

fn delegation_block(line: &str) -> bool {
    let trimmed = line.trim();
    let rest = match trimmed.strip_prefix('{') {
        Some(value) => value.trim_start(),
        None => return false,
    };
    let rest = match rest.strip_prefix("return") {
        Some(value) => value.trim_start(),
        None => return false,
    };
    let call = match rest.strip_suffix('}') {
        Some(value) => value.trim_end(),
        None => return false,
    };
    let call = match call.strip_suffix(';') {
        Some(value) => value.trim_end(),
        None => return false,
    };
    delegation_call(call)
}

fn delegation_call(text: &str) -> bool {
    let characters: Vec<char> = text.chars().collect();
    if characters.is_empty() {
        return false;
    }
    let mut cursor = 0usize;
    if !(characters[0].is_ascii_alphabetic() || characters[0] == '_') {
        return false;
    }
    while cursor < characters.len() && (is_ident_char(characters[cursor]) || characters[cursor] == '.') {
        cursor += 1;
    }
    if cursor >= characters.len() || characters[cursor] != '(' {
        return false;
    }
    cursor += 1;
    let mut closed = false;
    while cursor < characters.len() {
        if characters[cursor] == ')' {
            closed = true;
            cursor += 1;
            break;
        }
        if characters[cursor] == '(' {
            return false;
        }
        cursor += 1;
    }
    closed && cursor == characters.len()
}

fn strip_quotes(text: &str) -> &str {
    let mut value = text;
    if value.starts_with('"') {
        value = &value[1..];
    }
    if value.ends_with('"') && value.len() >= 1 {
        value = &value[..value.len() - 1];
    }
    value
}

// ------------------------------------------------------------------------------
// File discovery (rust scope: src/ production, tests/ test tree)
// ------------------------------------------------------------------------------
const EXCLUDED_SEGMENTS: [&str; 28] = [
    ".git", ".github", ".agents", ".claude", ".cursor", ".windsurf", ".cline", ".grok", ".oaef", "node_modules",
    "vendor", "build", "dist", "target", "obj", "bin", "tool", "docs", "templates", "examples", "coverage",
    "generated", ".venv", "venv", "__pycache__", ".dart_tool", ".gradle", ".idea",
];

const TEST_SEGMENTS: [&str; 7] = ["test", "tests", "__tests__", "spec", "specs", "androidTest", "iosTest"];

fn is_excluded_path(path: &str) -> bool {
    for segment in path.split('/') {
        if EXCLUDED_SEGMENTS.contains(&segment) {
            return true;
        }
    }
    let name = path.rsplit('/').next().unwrap_or(path);
    name.contains(".g.")
        || name.ends_with("_pb2.py")
        || name.ends_with("_pb2_grpc.py")
        || name.ends_with(".min.js")
        || name.contains(".generated.")
        || name.contains(".freezed.")
        || name.contains(".designer.")
}

fn is_test_path(path: &str) -> bool {
    for segment in path.split('/') {
        if TEST_SEGMENTS.contains(&segment) {
            return true;
        }
    }
    let name = path.rsplit('/').next().unwrap_or(path);
    name.contains("_test.")
        || name.contains(".spec.")
        || name.contains(".test.")
        || name.starts_with("test_") && name.ends_with(".py")
        || name.ends_with("Tests.cs")
        || name.ends_with("Test.kt")
}

fn collect_rust(root: &str, out: &mut Vec<String>) {
    let directory = Path::new(root);
    if !directory.is_dir() {
        return;
    }
    let reader = match fs::read_dir(directory) {
        Ok(value) => value,
        Err(_) => return,
    };
    let mut entries: Vec<PathBuf> = reader.filter_map(|entry| entry.ok()).map(|entry| entry.path()).collect();
    entries.sort();
    for entry in entries {
        let name = entry
            .file_name()
            .map(|value| value.to_string_lossy().to_string())
            .unwrap_or_default();
        if entry.is_dir() {
            if EXCLUDED_SEGMENTS.contains(&name.as_str()) {
                continue;
            }
            collect_rust(&entry.to_string_lossy(), out);
        } else if entry.extension().map(|value| value.to_string_lossy() == "rs").unwrap_or(false) {
            let path = entry.to_string_lossy().replace('\\', "/");
            let path = path.strip_prefix("./").unwrap_or(&path).to_string();
            out.push(path);
        }
    }
}

fn all_rust_files() -> Vec<String> {
    let mut files: Vec<String> = Vec::new();
    collect_rust("src", &mut files);
    collect_rust("tests", &mut files);
    files.retain(|path| !is_excluded_path(path));
    files.sort();
    files.dedup();
    files
}

fn production_files() -> Vec<String> {
    let mut files = all_rust_files();
    files.retain(|path| !is_test_path(path));
    files
}

// ------------------------------------------------------------------------------
// Skill frontmatter / matrix helpers
// ------------------------------------------------------------------------------
fn frontmatter_lines(skill: &str) -> Option<Vec<String>> {
    let path = format!("{}/SKILL.md", skill_dir(skill));
    let text = read_text(&path)?;
    let mut lines = text.lines();
    let first = lines.next()?;
    if first.trim_end() != "---" {
        return None;
    }
    let mut out: Vec<String> = Vec::new();
    for line in lines {
        if line.trim_end() == "---" {
            return Some(out);
        }
        out.push(line.to_string());
    }
    None
}

fn frontmatter_value(skill: &str, key: &str) -> String {
    let lines = match frontmatter_lines(skill) {
        Some(value) => value,
        None => return String::new(),
    };
    let prefix = format!("{}:", key);
    let mut value = String::new();
    let mut collecting = false;
    for line in lines.iter() {
        if collecting {
            if line.starts_with(' ') || line.starts_with('\t') {
                let trimmed = line.trim_start();
                if value.is_empty()
                    || value == ">"
                    || value == ">-"
                    || value == ">+"
                    || value == "|"
                    || value == "|-"
                    || value == "|+"
                {
                    value = trimmed.to_string();
                } else {
                    value.push(' ');
                    value.push_str(trimmed);
                }
                continue;
            }
            collecting = false;
        }
        if let Some(rest) = line.strip_prefix(&prefix) {
            value = rest.trim_start().to_string();
            collecting = true;
        }
    }
    value.trim_end().to_string()
}

fn frontmatter_keys(skill: &str) -> Vec<String> {
    let lines = match frontmatter_lines(skill) {
        Some(value) => value,
        None => return Vec::new(),
    };
    let mut out: Vec<String> = Vec::new();
    for line in lines.iter() {
        let bytes = line.as_bytes();
        if bytes.is_empty() || !bytes[0].is_ascii_alphabetic() {
            continue;
        }
        let mut cursor = 1usize;
        while cursor < bytes.len()
            && (bytes[cursor].is_ascii_alphanumeric() || bytes[cursor] == b'_' || bytes[cursor] == b'-')
        {
            cursor += 1;
        }
        if cursor < bytes.len() && bytes[cursor] == b':' {
            out.push(line[..cursor].to_string());
        }
    }
    out
}

fn body_has_territory(path: &str) -> bool {
    match read_text(path) {
        Some(text) => text.split('\n').any(|line| line.starts_with("## Territory")),
        None => false,
    }
}

fn matrix_rows() -> Vec<String> {
    let text = match read_text(AGENTS_FILE) {
        Some(value) => value,
        None => return Vec::new(),
    };
    let mut inside = false;
    let mut out: Vec<String> = Vec::new();
    for line in text.split('\n') {
        if line.starts_with("### 3.3") {
            inside = true;
            continue;
        }
        if inside && line.starts_with('#') {
            inside = false;
            continue;
        }
        if inside && line.starts_with('|') {
            let cells: Vec<&str> = line.split('|').collect();
            if cells.len() < 7 {
                continue;
            }
            let triggers = cells[3].trim().to_string();
            let primary: String = cells[4].chars().filter(|character| *character != '`' && !character.is_whitespace()).collect();
            if primary.is_empty() || primary == "PrimarySkill" {
                continue;
            }
            out.push(format!("{}|{}|", primary, triggers));
        }
    }
    out
}

fn mirror_present(path: &str) -> bool {
    fs::symlink_metadata(path).is_ok()
}

fn is_symlink(path: &str) -> bool {
    fs::symlink_metadata(path)
        .map(|metadata| metadata.file_type().is_symlink())
        .unwrap_or(false)
}

fn mirror_of(dir: &str, skill: &str) -> Option<String> {
    if !mirror_present(dir) {
        return None;
    }
    let base = format!("{}/{}", dir, skill);
    if Path::new(&base).is_dir() {
        return Some(format!("{}/SKILL.md", base));
    }
    let markdown = format!("{}.md", base);
    if Path::new(&markdown).is_file() {
        return Some(markdown);
    }
    let mdc = format!("{}.mdc", base);
    if Path::new(&mdc).is_file() {
        return Some(mdc);
    }
    None
}

#[cfg(unix)]
fn make_symlink(target: &str, link: &str) -> bool {
    std::os::unix::fs::symlink(target, link).is_ok()
}

#[cfg(not(unix))]
fn make_symlink(_target: &str, _link: &str) -> bool {
    false
}

fn copy_dir(source: &str, destination: &str) -> std::io::Result<()> {
    fs::create_dir_all(destination)?;
    for entry in fs::read_dir(source)? {
        let entry = entry?;
        let name = entry.file_name();
        let from = entry.path();
        let to = Path::new(destination).join(&name);
        if from.is_dir() {
            copy_dir(&from.to_string_lossy(), &to.to_string_lossy())?;
        } else {
            fs::copy(&from, &to)?;
        }
    }
    Ok(())
}

// ------------------------------------------------------------------------------
// Routing (governance_checks.md section 7.1)
// ------------------------------------------------------------------------------
fn route_prompt(prompt: &str) -> String {
    let lowered = prompt.to_lowercase();
    let tokens: Vec<String> = lowered
        .split(|character: char| !(character.is_ascii_lowercase() || character.is_ascii_digit() || character == '-'))
        .filter(|value| !value.is_empty())
        .map(|value| value.to_string())
        .collect();
    let mut best = "ponytail".to_string();
    let mut best_score = 0i64;
    for skill in SKILLS.iter() {
        let mut score = 0i64;
        for word in skill.split('-') {
            if tokens.iter().any(|token| word_match(token, word)) {
                score += 5;
            }
        }
        for trigger in skill_triggers(skill).split('|') {
            if trigger.is_empty() {
                continue;
            }
            let weight = trigger.chars().count().min(8) as i64;
            if trigger.contains(' ') {
                if lowered.contains(trigger) {
                    score += 3 + weight;
                }
            } else if tokens.iter().any(|token| word_match(token, trigger)) {
                score += 3 + weight;
            }
        }
        for token in tokens.iter() {
            if TERRITORY.contains(&token.as_str()) {
                score += 1;
            }
        }
        if score > best_score {
            best_score = score;
            best = skill.to_string();
        }
    }
    if best_score == 0 {
        best = "ponytail".to_string();
    }
    best
}

fn word_match(token: &str, word: &str) -> bool {
    if word.is_empty() {
        return false;
    }
    for form in candidate_forms(token) {
        if form == word {
            return true;
        }
        if form.chars().count() >= 4 && common_prefix(&form, word) >= 4 {
            return true;
        }
    }
    false
}

fn candidate_forms(token: &str) -> Vec<String> {
    let mut out: Vec<String> = vec![token.to_string()];
    if token.ends_with("ies") {
        out.push(format!("{}y", &token[..token.len() - 3]));
    }
    if token.ends_with("es") {
        out.push(token[..token.len() - 2].to_string());
    }
    if token.ends_with('s') {
        out.push(token[..token.len() - 1].to_string());
    }
    if token.ends_with("ing") {
        out.push(token[..token.len() - 3].to_string());
    }
    if token.ends_with("ed") {
        out.push(token[..token.len() - 2].to_string());
    }
    if token.ends_with("ion") {
        out.push(token[..token.len() - 3].to_string());
    }
    out
}

fn common_prefix(left: &str, right: &str) -> usize {
    let left: Vec<char> = left.chars().collect();
    let right: Vec<char> = right.chars().collect();
    let limit = left.len().min(right.len());
    let mut index = 0usize;
    while index < limit {
        if left[index] != right[index] {
            return index;
        }
        index += 1;
    }
    limit
}

// ------------------------------------------------------------------------------
// lint scanners
// ------------------------------------------------------------------------------
fn normalize_mirror_text(text: &str) -> String {
    text.split('\n')
        .filter(|line| !line.starts_with("<!--"))
        .collect::<Vec<&str>>()
        .join("")
        .chars()
        .filter(|character| !character.is_whitespace())
        .collect()
}

fn walk_files(directory: &str, skip: &[&str], out: &mut Vec<String>) {
    let reader = match fs::read_dir(directory) {
        Ok(value) => value,
        Err(_) => return,
    };
    let mut entries: Vec<PathBuf> = reader.filter_map(|entry| entry.ok()).map(|entry| entry.path()).collect();
    entries.sort();
    for entry in entries {
        let name = entry
            .file_name()
            .map(|value| value.to_string_lossy().to_string())
            .unwrap_or_default();
        if entry.is_dir() {
            if skip.contains(&name.as_str()) {
                continue;
            }
            walk_files(&entry.to_string_lossy(), skip, out);
        } else {
            out.push(entry.to_string_lossy().replace('\\', "/"));
        }
    }
}

fn has_secret(line: &str) -> bool {
    let marker_ok = |marker: &str, minimum: usize| -> bool {
        let bytes = line.as_bytes();
        let needle = marker.as_bytes();
        let mut cursor = 0usize;
        while cursor + needle.len() <= bytes.len() {
            if &bytes[cursor..cursor + needle.len()] == needle {
                let mut probe = cursor + needle.len();
                let mut count = 0usize;
                while probe < bytes.len() && bytes[probe].is_ascii_alphanumeric() {
                    count += 1;
                    probe += 1;
                }
                if count >= minimum {
                    return true;
                }
            }
            cursor += 1;
        }
        false
    };
    if marker_ok("sk-", 20) || marker_ok("ghp_", 20) {
        return true;
    }
    if let Some(position) = line.find("AKIA") {
        let tail: Vec<char> = line[position + 4..].chars().take(16).collect();
        if tail.len() == 16 && tail.iter().all(|character| character.is_ascii_digit() || character.is_ascii_uppercase()) {
            return true;
        }
    }
    line.contains("-----BEGIN ") && line.contains(" PRIVATE KEY-----")
}

fn scan_secrets_in_dir(directory: &str) -> Vec<String> {
    let mut files: Vec<String> = Vec::new();
    walk_files(directory, &[], &mut files);
    let mut hits: Vec<String> = Vec::new();
    for file in files {
        let text = match read_text(&file) {
            Some(value) => value,
            None => continue,
        };
        for (index, line) in text.split('\n').enumerate() {
            if has_secret(line) {
                hits.push(format!("{}:{}:{}", file, index + 1, line));
            }
        }
    }
    hits
}

fn scan_suppressions() -> Vec<String> {
    let mut files: Vec<String> = Vec::new();
    walk_files(".", &EXCLUDED_SEGMENTS, &mut files);
    let patterns = [
        "// ignore:",
        "/* eslint-disable",
        "// @ts-ignore",
        "# noqa",
        "# type: ignore",
        "//nolint",
        "#[allow(",
        "@Suppress(",
        "// swiftlint:disable",
        "#pragma warning disable",
    ];
    let exclusions = [
        "deprecated_member_use",
        "type=lint",
        "SA1019",
        "CS0618",
        "CS0612",
        "DEPRECATION",
        "DeprecatedCallableAddReplaceWith",
        "#[allow(deprecated)",
        "@typescript-eslint/no-deprecated",
        "W1505",
        "B005",
        "deprecated-method",
        "type: ignore[deprecated]",
        "DO NOT EDIT",
        "@generated",
        ".g.",
    ];
    let mut hits: Vec<String> = Vec::new();
    for file in files {
        if file.ends_with(".md") {
            continue;
        }
        let text = match read_text(&file) {
            Some(value) => value,
            None => continue,
        };
        for (index, line) in text.split('\n').enumerate() {
            if patterns.iter().any(|pattern| line.contains(pattern))
                && !exclusions.iter().any(|exclusion| line.contains(exclusion))
            {
                hits.push(format!("{}:{}:{}", file, index + 1, line));
            }
        }
    }
    hits
}

// ------------------------------------------------------------------------------
// CLI
// ------------------------------------------------------------------------------
fn usage() {
    println!("OAEF Governance Tool (Rust Engine)");
    println!("Usage: cargo run --bin governance <command>");
    println!("Commands:");
    println!("  quality-gate|audit        Quality Gate audit (sizing, clean code)");
    println!("  clean-code                Governance barriers (docs/standards/governance_checks.md)");
    println!("  ponytail-debt             Report every \"// ponytail:\" debt marker (PT-01)");
    println!("  ponytail-audit            Advisory anti-slop audit");
    println!("  skills-audit [--selftest] Skill activation invariants (SK-01..SK-06)");
    println!("  skills-route \"<query>\"    Resolve a prompt to its governing skill and recipe");
    println!("  skills sync-mirrors [--check] Rebuild or validate the harness skill mirrors");
    println!("  lint                      Mirror parity, secrets, anti-suppression, skills");
    println!("  doctor|conform            Conformance audit");
    println!("  metrics                   Display baseline thresholds");
    println!("  sync                      Synchronize AGENTS.md to CLAUDE.md");
}

fn cc_index(id: &str) -> Option<usize> {
    let suffix = id.strip_prefix("CC-")?;
    let number = suffix.parse::<usize>().ok()?;
    if number >= 1 && number <= 11 {
        Some(number - 1)
    } else {
        None
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        usage();
        exit(1);
    }
    let mut engine = Engine::new();
    let command = args[1].clone();
    let rest: Vec<String> = args[2..].to_vec();
    let first = rest.first().map(|value| value.as_str()).unwrap_or("");
    match command.as_str() {
        "quality-gate" | "audit" => engine.run_quality_gate(),
        "clean-code" | "governance-check" => engine.run_clean_code(rest.iter().any(|value| value == "--standard")),
        "ponytail-debt" => engine.run_ponytail_debt(),
        "ponytail-audit" => engine.run_ponytail_audit(),
        "skills-audit" => engine.run_skills_audit(first),
        "skills-route" => engine.run_skills_route(&rest.join(" ")),
        "skills-sync-mirrors" => engine.run_skills_sync_mirrors(first == "--check"),
        "skills" => match first {
            "sync-mirrors" => {
                let flag = rest.get(1).map(|value| value.as_str()).unwrap_or("");
                engine.run_skills_sync_mirrors(flag == "--check");
            }
            "audit" => {
                let flag = rest.get(1).map(|value| value.as_str()).unwrap_or("");
                engine.run_skills_audit(flag);
            }
            "route" => engine.run_skills_route(&rest[1..].join(" ")),
            _ => {
                usage();
                exit(1);
            }
        },
        "ponytail" => match first {
            "audit" => engine.run_ponytail_audit(),
            _ => engine.run_ponytail_debt(),
        },
        "lint" => engine.run_lint(),
        "conform" | "doctor" => engine.run_conform(),
        "metrics" => engine.run_metrics(),
        "sync" => engine.run_sync(),
        _ => {
            usage();
            exit(1);
        }
    }
}
