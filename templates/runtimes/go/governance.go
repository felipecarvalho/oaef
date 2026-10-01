package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

type Baseline struct {
	Baseline struct {
		Coverage struct {
			LinesMinPercentage float64 `json:"lines_min_percentage"`
		} `json:"coverage"`
		CleanSizing struct {
			FileMaxLines int `json:"file_max_lines"`
		} `json:"clean_sizing"`
	} `json:"baseline"`
}

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	cmd := os.Args[1]
	switch cmd {
	case "quality-gate", "audit":
		runQualityGate()
	case "lint":
		runLint()
	case "conform", "doctor":
		runConform()
	case "sync":
		runSync()
	default:
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println("OAEF Governance Tool (Go Engine)")
	fmt.Println("Usage: go run tool/governance.go [quality-gate|lint|doctor|sync]")
}

func normalizeMirrorText(text string) string {
	var builder strings.Builder
	for _, line := range strings.Split(text, "\n") {
		if strings.HasPrefix(line, "<!--") {
			continue
		}
		builder.WriteString(line)
	}
	return strings.Join(strings.Fields(builder.String()), "")
}

func runConform() {
	fmt.Println("🩺 OAEF Conformance Audit (doctor)...")
	requiredFiles := []string{
		"AGENTS.md", "CLAUDE.md", "llms.txt", "oaef.context.json",
		"docs/INDEX.md", "docs/MANIFESTO.md", "docs/DESIGN.md",
		"docs/standards/coding_patterns.md", "docs/standards/testing.md", "docs/standards/logging.md",
		"docs/wiki/metrics/baseline.json", "docs/wiki/memory/handoff.md", "docs/wiki/log.md",
		"docs/HARNESSES.md",
		".github/workflows/ci.yml", ".github/pull_request_template.md",
		".gitignore", "CONTRIBUTING.md", "SECURITY.md",
	}
	skills := []string{
		"architecture-audit", "code-review", "collect-coverage", "component-author",
		"fix-layout-issues", "nullable-types", "run-static-analysis", "screen-builder",
		"test-generator", "ui-preview", "conformance-audit",
	}
	runtimes := []string{
		"tool/governance.sh", "tool/governance.mjs", "tool/governance.py", "tool/governance.dart",
		"tool/governance.go", "tool/governance.rs", "tool/governance.main.kts", "tool/governance.swift",
		"tool/Governance.cs",
	}

	checks := 0
	passed := 0
	failed := false
	check := func(condition bool, label string) {
		checks++
		if condition {
			passed++
			fmt.Printf("✅ %s\n", label)
		} else {
			fmt.Fprintf(os.Stderr, "❌ %s\n", label)
			failed = true
		}
	}

	for _, requiredFile := range requiredFiles {
		_, err := os.Stat(requiredFile)
		check(err == nil, requiredFile+" present")
	}
	for _, skill := range skills {
		_, err := os.Stat(filepath.Join(".agents", "skills", skill, "SKILL.md"))
		check(err == nil, ".agents/skills/"+skill+"/SKILL.md present")
	}

	runtimeFound := false
	for _, runtime := range runtimes {
		if _, err := os.Stat(runtime); err == nil {
			runtimeFound = true
		}
	}
	check(runtimeFound, "governance runtime present in tool/")

	agentsData, agentsErr := os.ReadFile("AGENTS.md")
	claudeData, claudeErr := os.ReadFile("CLAUDE.md")
	if agentsErr == nil && claudeErr == nil {
		check(normalizeMirrorText(string(agentsData)) == normalizeMirrorText(string(claudeData)), "CLAUDE.md mirror parity verified")
	} else {
		check(false, "mirror parity not verifiable (missing AGENTS.md or CLAUDE.md)")
	}

	placeholderRe := regexp.MustCompile(`\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}`)
	placeholderHits := false
	for _, candidate := range []string{"AGENTS.md", "llms.txt"} {
		if data, err := os.ReadFile(candidate); err == nil && placeholderRe.Match(data) {
			placeholderHits = true
		}
	}
	check(!placeholderHits, "no unresolved template placeholders")

	fmt.Printf("\n📊 Conformance: %d/%d checks passed\n", passed, checks)
	if failed {
		os.Exit(1)
	}
}

func runQualityGate() {
	fmt.Println("🔍 Initiating OAEF Quality Gate Audit (Go)...")
	baselineData, err := os.ReadFile("docs/wiki/metrics/baseline.json")
	var baseline Baseline
	if err == nil {
		_ = json.Unmarshal(baselineData, &baseline)
	}

	maxLines := baseline.Baseline.CleanSizing.FileMaxLines
	if maxLines == 0 {
		maxLines = 300
	}

	// Clean Sizing audit
	oversized := 0
	_ = filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		data, _ := os.ReadFile(path)
		lines := strings.Split(string(data), "\n")
		if len(lines) > maxLines {
			oversized++
			fmt.Fprintf(os.Stderr, "⚠️  Oversized file (%dL > %dL): %s\n", len(lines), maxLines, path)
		}
		return nil
	})

	if oversized > 0 {
		fmt.Fprintf(os.Stderr, "❌ Quality Gate Failed: %d oversized files.\n", oversized)
		os.Exit(1)
	}

	// Run tests
	fmt.Println("ℹ️  Running go test with coverage...")
	testCmd := exec.Command("go", "test", "-coverprofile=coverage.out", "./...")
	testCmd.Stdout = os.Stdout
	testCmd.Stderr = os.Stderr
	if err := testCmd.Run(); err != nil {
		fmt.Fprintln(os.Stderr, "❌ Tests failed.")
		os.Exit(1)
	}

	fmt.Println("\n🎉 Quality Gates PASSED!")
}

func runLint() {
	fmt.Println("🔍 Auditing OAEF Integrity & Secret Leaks...")
	failed := false

	// Mirror parity
	agentsData, agentsErr := os.ReadFile("AGENTS.md")
	claudeData, claudeErr := os.ReadFile("CLAUDE.md")
	if agentsErr == nil && claudeErr == nil {
		if normalizeMirrorText(string(agentsData)) != normalizeMirrorText(string(claudeData)) {
			fmt.Fprintln(os.Stderr, "❌ [LINT] CLAUDE.md diverged from AGENTS.md.")
			failed = true
		}
	}

	// Secret patterns
	secretRe := regexp.MustCompile(`(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16})`)
	_ = filepath.Walk("docs", func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() || !strings.HasSuffix(path, ".md") {
			return nil
		}
		data, _ := os.ReadFile(path)
		if secretRe.Match(data) {
			fmt.Fprintf(os.Stderr, "🚨 [SECURITY] Potential secret detected in %s!\n", path)
			failed = true
		}
		return nil
	})

	if failed {
		os.Exit(1)
	}
	fmt.Println("✅ [LINT] All audits passed cleanly.")
}

func runSync() {
	agentsData, err := os.ReadFile("AGENTS.md")
	if err != nil {
		fmt.Fprintln(os.Stderr, "AGENTS.md not found.")
		os.Exit(1)
	}
	banner := "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n\n"
	_ = os.WriteFile("CLAUDE.md", append([]byte(banner), agentsData...), 0644)
	fmt.Println("✅ Synchronized AGENTS.md -> CLAUDE.md")
}
