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
	case "sync":
		runSync()
	default:
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println("OAEF Governance Tool (Go Engine)")
	fmt.Println("Usage: go run tool/governance.go [quality-gate|lint|sync]")
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
