// ==============================================================================
// OAEF Governance Engine — Go realization
// Implements docs/standards/governance_checks.md for the `go` stack.
// Author: Felipe Carvalho | License: Apache 2.0
// Invocation: go run tool/governance.go <command>
// ==============================================================================

package main

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

const (
	emDash         = "—"
	contextFile    = "oaef.context.json"
	baselineFile   = "docs/wiki/metrics/baseline.json"
	adoptionLedger = "docs/wiki/metrics/adoption.json"
	agentsFile     = "AGENTS.md"
	llmsFile       = "llms.txt"
)

// ------------------------------------------------------------------------------
// Canonical catalog (must stay byte-identical to AGENTS.md section 3)
// ------------------------------------------------------------------------------

var skillsCatalog = []string{
	"ponytail", "nullable-types", "architecture-audit", "screen-builder", "component-author",
	"responsive-layout", "ui-preview", "fix-layout-issues", "test-generator", "collect-coverage",
	"run-static-analysis", "code-review", "conformance-audit",
}

var skillTriggers = map[string][]string{
	"ponytail":            {"new", "refactor", "add", "simple", "minimal", "yagni", "dead code", "delete", "remove"},
	"screen-builder":      {"screen", "page", "feature", "flow", "view"},
	"component-author":    {"component", "widget", "button", "card", "modal"},
	"ui-preview":          {"preview", "storybook", "isolated render"},
	"responsive-layout":   {"responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport"},
	"fix-layout-issues":   {"overflow", "unbounded", "layout", "layout broken", "render error"},
	"test-generator":      {"test", "coverage", "mock", "fixture"},
	"collect-coverage":    {"coverage", "lcov", "jacoco", "cobertura", "branches"},
	"run-static-analysis": {"analyze", "lint", "typecheck", "warnings"},
	"nullable-types":      {"null", "optional", "nil", "guard clause", "defensive"},
	"architecture-audit":  {"architecture", "boundary", "coupling", "cycle"},
	"conformance-audit":   {"conformance", "doctor", "parity", "frontmatter"},
	"code-review":         {"review", "pr", "checklist", "pre-pr"},
}

func metaSkill(skill string) string {
	switch skill {
	case "ponytail", "collect-coverage", "run-static-analysis", "conformance-audit":
		return emDash
	}
	return "ponytail"
}

var routingFixtures = [][2]string{
	{"create a new screen for the booking flow", "screen-builder"},
	{"build a reusable button component", "component-author"},
	{"the layout overflows on small screens", "fix-layout-issues"},
	{"add responsive breakpoints for tablet", "responsive-layout"},
	{"write unit tests for the payment service", "test-generator"},
	{"collect coverage and check the branch floor", "collect-coverage"},
	{"fix all analyzer warnings", "run-static-analysis"},
	{"this optional list parameter is always null", "nullable-types"},
	{"audit module boundaries and cyclic imports", "architecture-audit"},
	{"verify the repo conforms to the framework", "conformance-audit"},
	{"review my PR before I open it", "code-review"},
	{"remove the dead code and the 1-line use case", "ponytail"},
}

var recipes = []string{
	"1. Feature / Screen Construction: ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review",
	"2. Reusable Component / Module Authoring: ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis",
	"3. Bug Fix / Root-Cause Remediation: ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis",
	"4. Domain, Data & Infrastructure: ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis",
	"5. Pre-Submission / Pull Request Cycle: collect-coverage -> run-static-analysis -> code-review",
}

var mirrorDirs = []string{".claude/skills", ".cursor/rules", ".windsurf/skills", ".cline/skills", ".grok/agents"}

// ------------------------------------------------------------------------------
// Profile & adoption resolution
// ------------------------------------------------------------------------------

var (
	profile      = "strict"
	adoptionMode = "install"

	baselineCache  map[string]any
	baselineLoaded bool
)

func readJSONMap(path string) map[string]any {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	var parsed map[string]any
	if json.Unmarshal(data, &parsed) != nil {
		return nil
	}
	return parsed
}

func baselineMap() map[string]any {
	if !baselineLoaded {
		baselineCache = readJSONMap(baselineFile)
		baselineLoaded = true
	}
	return baselineCache
}

func resolveProfile() {
	profile = ""
	if ctx := readJSONMap(contextFile); ctx != nil {
		if value, ok := ctx["strictness"].(string); ok {
			profile = value
		}
	}
	if profile == "" {
		if bm := baselineMap(); bm != nil {
			if value, ok := bm["profile"].(string); ok {
				profile = value
			}
		}
	}
	if profile == "" {
		profile = "strict"
	}
	adoptionMode = "install"
	if ctx := readJSONMap(contextFile); ctx != nil {
		if value, ok := ctx["adoption_mode"].(string); ok && value != "" {
			adoptionMode = value
		}
	}
}

func isAdoption() bool { return adoptionMode != "install" }

func userOwnedSkill(skill string) bool {
	ledger := readJSONMap(adoptionLedger)
	if ledger == nil {
		return false
	}
	entries, _ := ledger["user_skills"].([]any)
	for _, entry := range entries {
		if name, ok := entry.(string); ok && name == skill {
			return true
		}
	}
	return false
}

var ccThresholdKeys = map[string]string{
	"CC-01": "max_single_letter_identifiers",
	"CC-02": "max_cryptic_abbreviations",
	"CC-03": "max_mutable_lazy_initializations",
	"CC-04": "max_dummy_keys",
	"CC-05": "max_raw_prints",
	"CC-06": "max_silent_catches",
	"CC-07": "max_service_locator_leaks",
	"CC-08": "max_nullable_collections",
	"CC-09": "max_unimplemented_placeholders",
	"CC-10": "max_concrete_client_instantiations",
	"CC-11": "max_avoidable_allocations",
}

func ccThreshold(id string) int {
	key, ok := ccThresholdKeys[id]
	if !ok {
		return 0
	}
	bm := baselineMap()
	if bm == nil {
		return 0
	}
	baseline, _ := bm["baseline"].(map[string]any)
	if baseline == nil {
		return 0
	}
	cleanCode, _ := baseline["clean_code"].(map[string]any)
	if cleanCode == nil {
		return 0
	}
	if value, ok := cleanCode[key].(float64); ok {
		return int(value)
	}
	return 0
}

// ccBlocking reports whether a check is blocking under the effective profile.
// CC-04 blocks under every profile; CC-11 is advisory by definition; adoption
// modes make every remaining CC-* advisory.
func ccBlocking(id string) bool {
	if id == "CC-11" {
		return false
	}
	if id == "CC-04" {
		return true
	}
	if isAdoption() {
		return false
	}
	return profile == "strict"
}

// ------------------------------------------------------------------------------
// File discovery
// ------------------------------------------------------------------------------

var excludedSegments = map[string]bool{
	".git": true, ".github": true, ".agents": true, ".claude": true, ".cursor": true,
	".windsurf": true, ".cline": true, ".grok": true, ".oaef": true, "node_modules": true,
	"vendor": true, "build": true, "dist": true, "target": true, "obj": true, "bin": true,
	"tool": true, "docs": true, "templates": true, "examples": true, "coverage": true,
	"generated": true, ".venv": true, "venv": true, "__pycache__": true, ".dart_tool": true,
	".gradle": true, ".idea": true,
}

var testSegments = map[string]bool{
	"test": true, "tests": true, "__tests__": true, "spec": true, "specs": true,
	"androidTest": true, "iosTest": true,
}

var generatedPatterns = []string{".g.", "_pb2.py", "_pb2_grpc.py", ".min.js", ".generated.", ".freezed.", ".designer."}

func isExcludedPath(rel string) bool {
	segments := strings.Split(rel, "/")
	for _, segment := range segments {
		if excludedSegments[segment] {
			return true
		}
	}
	base := segments[len(segments)-1]
	for _, pattern := range generatedPatterns {
		if strings.Contains(base, pattern) {
			return true
		}
	}
	return false
}

func isTestPath(rel string) bool {
	for _, segment := range strings.Split(rel, "/") {
		if testSegments[segment] {
			return true
		}
	}
	base := filepath.Base(rel)
	switch {
	case strings.Contains(base, "_test."):
		return true
	case strings.Contains(base, ".spec."):
		return true
	case strings.Contains(base, ".test."):
		return true
	case strings.HasPrefix(base, "test_") && strings.HasSuffix(base, ".py"):
		return true
	case strings.HasSuffix(base, "Tests.cs"):
		return true
	case strings.HasSuffix(base, "Test.kt"):
		return true
	}
	return false
}

func walkGoFiles(includeTests bool) []string {
	var out []string
	_ = filepath.WalkDir(".", func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if entry.IsDir() {
			if path != "." && excludedSegments[entry.Name()] {
				return fs.SkipDir
			}
			return nil
		}
		rel := filepath.ToSlash(strings.TrimPrefix(path, "./"))
		if !strings.HasSuffix(rel, ".go") {
			return nil
		}
		if isExcludedPath(rel) {
			return nil
		}
		if !includeTests && isTestPath(rel) {
			return nil
		}
		out = append(out, rel)
		return nil
	})
	sort.Strings(out)
	return out
}

func productionFiles() []string { return walkGoFiles(false) }
func allSourceFiles() []string  { return walkGoFiles(true) }

// ------------------------------------------------------------------------------
// Finding emission
// ------------------------------------------------------------------------------

var (
	ccCounts   = map[string]int{}
	ccTotal    int
	skFailures int
)

func emitCC(id, path string, line int, message string) {
	fmt.Printf("%s %s:%d %s %s\n", id, path, line, emDash, message)
	ccCounts[id]++
	ccTotal++
}

func emitSK(id, path string, line int, message string) {
	fmt.Printf("%s %s:%d %s %s\n", id, path, line, emDash, message)
	skFailures++
}

func readLines(path string) []string {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	return strings.Split(string(data), "\n")
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func filesEqual(left, right string) bool {
	a, errA := os.ReadFile(left)
	b, errB := os.ReadFile(right)
	if errA != nil || errB != nil {
		return false
	}
	return string(a) == string(b)
}

// stripCode blanks out string/rune literals and line comments while preserving
// byte offsets, so declaration parsing never trips on string content.
func stripCode(line string) string {
	out := []byte(line)
	inString := false
	inRaw := false
	inRune := false
	inComment := false
	for i := 0; i < len(line); i++ {
		c := line[i]
		if inComment {
			out[i] = ' '
			continue
		}
		if inString {
			out[i] = ' '
			if c == '\\' && i+1 < len(line) {
				out[i+1] = ' '
				i++
				continue
			}
			if c == '"' {
				inString = false
			}
			continue
		}
		if inRaw {
			out[i] = ' '
			if c == '`' {
				inRaw = false
			}
			continue
		}
		if inRune {
			out[i] = ' '
			if c == '\\' && i+1 < len(line) {
				out[i+1] = ' '
				i++
				continue
			}
			if c == '\'' {
				inRune = false
			}
			continue
		}
		if c == '/' && i+1 < len(line) && line[i+1] == '/' {
			inComment = true
			out[i] = ' '
			continue
		}
		switch c {
		case '"':
			inString = true
			out[i] = ' '
		case '`':
			inRaw = true
			out[i] = ' '
		case '\'':
			inRune = true
			out[i] = ' '
		}
	}
	return string(out)
}

// ------------------------------------------------------------------------------
// CC-01 / CC-02 : identifier discipline
// ------------------------------------------------------------------------------

var crypticTokens = []string{
	"cb", "fn", "res", "req", "btn", "val", "tmp", "ctx", "el", "usr", "mgr", "idx",
	"cnt", "buf", "str", "num", "doc", "elem", "curr", "prev",
}

var crypticSet = func() map[string]bool {
	set := map[string]bool{}
	for _, token := range crypticTokens {
		set[token] = true
	}
	return set
}()

var (
	reForLine       = regexp.MustCompile(`^\s*for\b`)
	reFuncLiteral   = regexp.MustCompile(`\bfunc\s*\(`)
	reVarDecl       = regexp.MustCompile(`\bvar\s+([A-Za-z_][A-Za-z0-9_]*)`)
	reShortDecl     = regexp.MustCompile(`(^|[^A-Za-z0-9_.])([A-Za-z_][A-Za-z0-9_]*)\s*:=`)
	reIdentStart    = regexp.MustCompile(`^([A-Za-z_][A-Za-z0-9_]*)`)
	reMethodName    = regexp.MustCompile(`^\s*[A-Za-z_][A-Za-z0-9_]*\s*\(`)
	reSilentAssign  = regexp.MustCompile(`(^|[^A-Za-z0-9_])_\s*=\s*err\b`)
	reIfErrNil      = regexp.MustCompile(`\bif\s+err\s*!=\s*nil\s*\{`)
	reRecoverBlock  = regexp.MustCompile(`\brecover\s*\(\s*\)[^{}]*\{`)
	reUnimplemented = regexp.MustCompile(`panic\s*\(\s*"(not implemented|TODO)`)
	reRawPrint      = regexp.MustCompile(`(^|[^A-Za-z0-9_.])(fmt\.Print|println\s*\()`)
	reAppendCall    = regexp.MustCompile(`(^|[^A-Za-z0-9_.])append\s*\(`)
	reDummyKey      = regexp.MustCompile(`dummy_|changeme|TODO_KEY`)
	reSecretAssign  = regexp.MustCompile("(?i)\\b(api[_-]?key|apikey|secret|password|token)\\s*:?=\\s*(\"[^\"]*\"|`[^`]*`)")
	reEnvSafe       = regexp.MustCompile(`os\.Getenv|os\.LookupEnv|os\.Environ|process\.env|System\.getenv|os\.environ|env\[|\$\{|fmt\.Sprintf`)
	reNarration     = regexp.MustCompile(`^\s*(//|#)\s*(increment|decrement|set|assign|call|return|loop|iterate|initialize|create|check|store)\s`)
	reShrink        = regexp.MustCompile(`^\s*func\b[^{]*\{\s*return\s+[A-Za-z_][A-Za-z0-9_.]*\([^)]*\)\s*\}\s*$`)
	reDebtMarker    = regexp.MustCompile(`(^|[^A-Za-z])(//|#|--|/\*|///|<!--)[^\n]*ponytail:`)
)

type binding struct {
	name string
	loop bool
}

func funcLiteralParams(line string) []string {
	var names []string
	for _, loc := range reFuncLiteral.FindAllStringIndex(line, -1) {
		open := loc[1] - 1
		depth := 0
		closeIdx := -1
		for i := open; i < len(line); i++ {
			switch line[i] {
			case '(':
				depth++
			case ')':
				depth--
				if depth == 0 {
					closeIdx = i
				}
			}
			if closeIdx >= 0 {
				break
			}
		}
		if closeIdx < 0 {
			continue
		}
		// A method declaration carries a receiver and then the method name.
		if reMethodName.MatchString(line[closeIdx+1:]) {
			continue
		}
		for _, part := range strings.Split(line[open+1:closeIdx], ",") {
			if match := reIdentStart.FindStringSubmatch(strings.TrimSpace(part)); match != nil {
				names = append(names, match[1])
			}
		}
	}
	return names
}

func extractBindings(line string) []binding {
	var out []binding
	seen := map[string]bool{}
	add := func(name string, loop bool) {
		if name == "" || seen[name] {
			return
		}
		seen[name] = true
		out = append(out, binding{name: name, loop: loop})
	}

	if reForLine.MatchString(line) {
		if idx := strings.Index(line, ":="); idx >= 0 {
			clause := strings.TrimSpace(strings.TrimPrefix(strings.TrimSpace(line[:idx]), "for"))
			for _, part := range strings.Split(clause, ",") {
				if match := reIdentStart.FindStringSubmatch(strings.TrimSpace(part)); match != nil {
					add(match[1], true)
				}
			}
		}
	}
	for _, match := range reVarDecl.FindAllStringSubmatch(line, -1) {
		add(match[1], false)
	}
	for _, name := range funcLiteralParams(line) {
		add(name, false)
	}
	for _, match := range reShortDecl.FindAllStringSubmatch(line, -1) {
		add(match[2], false)
	}
	return out
}

func checkIdentifierDiscipline(file string, lines []string) {
	for index, raw := range lines {
		code := stripCode(raw)
		for _, bound := range extractBindings(code) {
			name := bound.name
			if len(name) == 1 {
				if name == "_" {
					continue
				}
				if (name == "i" || name == "j") && bound.loop {
					continue
				}
				emitCC("CC-01", file, index+1,
					fmt.Sprintf("prohibited single-letter identifier %q; use a descriptive name", name))
				break
			}
			if crypticSet[strings.ToLower(name)] {
				emitCC("CC-02", file, index+1,
					fmt.Sprintf("prohibited cryptic abbreviation %q; use the full identifier", name))
				break
			}
		}
	}
}

// Documented no-ops for this stack (governance_checks.md §4, `go` column):
//   CC-03 — Go has no mutable lazy-initialization idiom to detect.
//   CC-07 — Go has no idiomatic service locator; dependencies are explicit
//           constructor arguments and consumer-owned interfaces.
//   CC-08 — Go's type system cannot express a non-null collection default; the
//           rule degrades to the advisory "collection parameters must be
//           documented as nil-safe", which is never emitted mechanically.
//   CC-10 — `http.Client{}` construction is an explicit composition-root
//           decision in Go; the check degrades to review guidance.

// ------------------------------------------------------------------------------
// CC-04 : hardcoded placeholder / secret
// ------------------------------------------------------------------------------

func checkSecrets(file string, lines []string) {
	for index, raw := range lines {
		hit := reDummyKey.MatchString(raw)
		if !hit && reSecretAssign.MatchString(raw) && !reEnvSafe.MatchString(raw) {
			hit = true
		}
		if hit {
			emitCC("CC-04", file, index+1,
				"prohibited hardcoded placeholder/secret; source it from configuration/environment")
		}
	}
}

// ------------------------------------------------------------------------------
// CC-05 : raw print / debug output
// ------------------------------------------------------------------------------

func checkRawPrints(file string, lines []string) {
	for index, raw := range lines {
		if reRawPrint.MatchString(stripCode(raw)) {
			emitCC("CC-05", file, index+1,
				"prohibited raw print/debug output in production code; use the logging interface")
		}
	}
}

// ------------------------------------------------------------------------------
// CC-06 : silent exception swallowing
// ------------------------------------------------------------------------------

// blockEnd returns the index of the line that closes the block opened at
// bracePos on startIdx.
func blockEnd(lines []string, startIdx, bracePos int) int {
	depth := 0
	raw := lines[startIdx]
	for i := bracePos; i < len(raw); i++ {
		switch raw[i] {
		case '{':
			depth++
		case '}':
			depth--
			if depth == 0 {
				return startIdx
			}
		}
	}
	for lineIdx := startIdx + 1; lineIdx < len(lines); lineIdx++ {
		raw = lines[lineIdx]
		for i := 0; i < len(raw); i++ {
			switch raw[i] {
			case '{':
				depth++
			case '}':
				depth--
				if depth == 0 {
					return lineIdx
				}
			}
		}
	}
	return len(lines) - 1
}

// blockIsEmpty reports whether the block opened at bracePos contains nothing
// but whitespace and comments.
func blockIsEmpty(lines []string, startIdx, bracePos int) bool {
	depth := 0
	hasContent := false
	raw := lines[startIdx]
	code := stripCode(raw)
	for i := bracePos; i < len(raw); i++ {
		switch raw[i] {
		case '{':
			depth++
		case '}':
			depth--
			if depth == 0 {
				return !hasContent
			}
		default:
			if depth == 1 && code[i] != ' ' && code[i] != '\t' {
				hasContent = true
			}
		}
	}
	for lineIdx := startIdx + 1; lineIdx < len(lines); lineIdx++ {
		raw = lines[lineIdx]
		code = stripCode(raw)
		for i := 0; i < len(raw); i++ {
			switch raw[i] {
			case '{':
				depth++
			case '}':
				depth--
				if depth == 0 {
					return !hasContent
				}
			default:
				if depth == 1 && code[i] != ' ' && code[i] != '\t' {
					hasContent = true
				}
			}
		}
	}
	return !hasContent
}

func checkSilentCatches(file string, lines []string) {
	const message = "prohibited silent exception swallowing; log with error+stack trace or rethrow"
	reported := map[int]bool{}
	for index, raw := range lines {
		code := stripCode(raw)
		if reSilentAssign.MatchString(code) && !reported[index+1] {
			emitCC("CC-06", file, index+1, message)
			reported[index+1] = true
		}
		for _, matcher := range []*regexp.Regexp{reIfErrNil, reRecoverBlock} {
			loc := matcher.FindStringIndex(code)
			if loc == nil {
				continue
			}
			if blockIsEmpty(lines, index, loc[1]-1) && !reported[index+1] {
				emitCC("CC-06", file, index+1, message)
				reported[index+1] = true
			}
		}
	}
}

// ------------------------------------------------------------------------------
// CC-09 : unimplemented placeholder
// ------------------------------------------------------------------------------

func checkUnimplemented(file string, lines []string) {
	for index, raw := range lines {
		if reUnimplemented.MatchString(raw) {
			emitCC("CC-09", file, index+1,
				"prohibited unimplemented placeholder in production contract; implement the contract (LSP)")
		}
	}
}

// ------------------------------------------------------------------------------
// CC-11 : avoidable allocation on a hot path (advisory)
// ------------------------------------------------------------------------------

func checkHotPathAllocations(file string, lines []string) {
	reported := map[int]bool{}
	for index, raw := range lines {
		code := stripCode(raw)
		if !reForLine.MatchString(code) {
			continue
		}
		bracePos := strings.Index(code, "{")
		startIdx := index
		if bracePos < 0 {
			for lookahead := index + 1; lookahead <= index+3 && lookahead < len(lines); lookahead++ {
				next := stripCode(lines[lookahead])
				if strings.TrimSpace(next) == "" {
					continue
				}
				if brace := strings.Index(next, "{"); brace >= 0 {
					startIdx = lookahead
					bracePos = brace
				}
				break
			}
		}
		if bracePos < 0 {
			continue
		}
		end := blockEnd(lines, startIdx, bracePos)
		for lineIdx := startIdx; lineIdx <= end; lineIdx++ {
			if lineIdx < index {
				continue
			}
			if reAppendCall.MatchString(stripCode(lines[lineIdx])) && !reported[lineIdx+1] {
				emitCC("CC-11", file, lineIdx+1,
					"[advisory] avoidable allocation on hot path; inspect without copying and return the original reference")
				reported[lineIdx+1] = true
			}
		}
	}
}

// ------------------------------------------------------------------------------
// clean-code suite
// ------------------------------------------------------------------------------

func runCleanCodeChecks() {
	for _, file := range productionFiles() {
		lines := readLines(file)
		checkIdentifierDiscipline(file, lines)
		checkSecrets(file, lines)
		checkRawPrints(file, lines)
		checkSilentCatches(file, lines)
		checkUnimplemented(file, lines)
	}
	for _, file := range allSourceFiles() {
		checkHotPathAllocations(file, readLines(file))
	}
}

func blockingTotal() int {
	total := 0
	for id := range ccCounts {
		count := ccCounts[id]
		if count > 0 && ccBlocking(id) && count > ccThreshold(id) {
			total += count
		}
	}
	return total
}

func cleanCodeBehavior() string {
	if ccBlocking("CC-01") {
		return "blocking"
	}
	return "advisory"
}

func printCleanCodeSummary() {
	fmt.Printf("Clean Code: %d violation(s) (%s profile: %s)\n", ccTotal, profile, cleanCodeBehavior())
}

func runCleanCode(standardOverride bool) {
	resolveProfile()
	if standardOverride {
		profile = "standard"
	}
	runCleanCodeChecks()
	printCleanCodeSummary()
	if blockingTotal() > 0 {
		os.Exit(1)
	}
}

// ------------------------------------------------------------------------------
// PT-01 : ponytail debt markers + anti-slop audit
// ------------------------------------------------------------------------------

func scanDebtMarkers() {
	for _, file := range allSourceFiles() {
		for index, raw := range readLines(file) {
			if !reDebtMarker.MatchString(raw) {
				continue
			}
			marker := strings.Index(raw, "ponytail:")
			if marker < 0 {
				continue
			}
			reason := strings.TrimSpace(raw[marker+len("ponytail:"):])
			fmt.Printf("PT-01 %s:%d %s %s\n", file, index+1, emDash, reason)
		}
	}
}

func runPonytailDebt() {
	scanDebtMarkers()
}

func runPonytailAudit() {
	scanDebtMarkers()
	for _, file := range productionFiles() {
		for index, raw := range readLines(file) {
			if reNarration.MatchString(raw) {
				fmt.Printf("[advisory] [DELETE] %s:%d %s narration comment restates the next line\n", file, index+1, emDash)
			}
			if reShrink.MatchString(raw) {
				fmt.Printf("[advisory] [SHRINK] %s:%d %s single-statement delegation; verify a caller justifies the layer\n", file, index+1, emDash)
			}
		}
	}
}

// ------------------------------------------------------------------------------
// SK-01 .. SK-06 : skill activation invariants
// ------------------------------------------------------------------------------

func skillDir(skill string) string { return ".agents/skills/" + skill }

func frontmatterLines(skill string) []string {
	lines := readLines(skillDir(skill) + "/SKILL.md")
	if len(lines) == 0 || strings.TrimRight(lines[0], "\r") != "---" {
		return nil
	}
	var block []string
	for _, line := range lines[1:] {
		if strings.TrimRight(line, "\r") == "---" {
			return block
		}
		block = append(block, line)
	}
	return block
}

func frontmatterValue(skill, key string) string {
	value := ""
	collecting := false
	for _, line := range frontmatterLines(skill) {
		if strings.HasPrefix(line, key+":") {
			value = strings.TrimLeft(line[len(key)+1:], " \t")
			collecting = true
			continue
		}
		if collecting && (strings.HasPrefix(line, " ") || strings.HasPrefix(line, "\t")) {
			trimmed := strings.TrimSpace(line)
			if value == "" || value == ">" || value == "|" || value == ">-" || value == "|-" || value == ">+" || value == "|+" {
				value = trimmed
			} else {
				value = value + " " + trimmed
			}
			continue
		}
		collecting = false
	}
	return strings.TrimRight(value, " \t")
}

func frontmatterKeys(skill string) []string {
	var keys []string
	reKey := regexp.MustCompile(`^[A-Za-z][A-Za-z0-9_-]*:`)
	for _, line := range frontmatterLines(skill) {
		if reKey.MatchString(line) {
			keys = append(keys, strings.TrimSuffix(strings.SplitN(line, ":", 2)[0], ":"))
		}
	}
	return keys
}

func auditSkillsParity() {
	for _, skill := range skillsCatalog {
		canonical := skillDir(skill) + "/SKILL.md"
		if !fileExists(canonical) {
			emitSK("SK-01", skillDir(skill), 0,
				fmt.Sprintf("skill %q is not listed in .agents/skills (parity required)", skill))
			continue
		}
		if fileExists(agentsFile) {
			if data, err := os.ReadFile(agentsFile); err == nil && !strings.Contains(string(data), "`"+skill+"`") {
				emitSK("SK-01", agentsFile, 0,
					fmt.Sprintf("skill %q is not listed in AGENTS.md (parity required)", skill))
			}
		}
		if fileExists("README.md") {
			if data, err := os.ReadFile("README.md"); err == nil && !strings.Contains(string(data), skill) {
				emitSK("SK-01", "README.md", 0,
					fmt.Sprintf("skill %q is not listed in README.md (parity required)", skill))
			}
		}
	}
}

const sk02Message = "frontmatter must declare \"Use when\", \"Triggers on:\" and \"Chains into:\" with >=150 characters and name==directory"

func auditSkillsFrontmatter() {
	allowedKeys := map[string]bool{"name": true, "description": true, "argument-hint": true, "license": true, "metadata": true}
	for _, skill := range skillsCatalog {
		canonical := skillDir(skill) + "/SKILL.md"
		if !fileExists(canonical) {
			continue
		}
		if isAdoption() && userOwnedSkill(skill) {
			continue
		}
		description := frontmatterValue(skill, "description")
		bad := description == "" ||
			!strings.Contains(description, "Use when") ||
			!strings.Contains(description, "Triggers on:") ||
			!strings.Contains(description, "Chains into:") ||
			len([]rune(description)) < 150 ||
			frontmatterValue(skill, "name") != skill
		if !bad {
			for _, key := range frontmatterKeys(skill) {
				if !allowedKeys[key] {
					bad = true
					break
				}
			}
		}
		if !bad {
			body, err := os.ReadFile(canonical)
			if err != nil || !strings.Contains(string(body), "## Territory") {
				bad = true
			}
		}
		if bad {
			emitSK("SK-02", canonical, 0, fmt.Sprintf("skill %q %s", skill, sk02Message))
		}
	}
}

func auditEntrypointParity() {
	for _, skill := range skillsCatalog {
		if !fileExists(llmsFile) {
			break
		}
		if data, err := os.ReadFile(llmsFile); err == nil && !strings.Contains(string(data), skill) {
			emitSK("SK-03", llmsFile, 0, fmt.Sprintf("skill %q is not listed in llms.txt", skill))
		}
	}
	for _, entry := range []string{"README.md", "docs/INDEX.md", "docs/MANIFESTO.md"} {
		if !fileExists(entry) {
			continue
		}
		if data, err := os.ReadFile(entry); err == nil && !strings.Contains(string(data), "llms.txt") {
			emitSK("SK-03", entry, 0, fmt.Sprintf("entrypoint %s does not reference llms.txt", entry))
		}
	}
}

// matrixRows returns the dispatch matrix as skill -> trigger keywords, in the
// order of AGENTS.md section 3.3.
func matrixRows() (map[string][]string, []string) {
	rows := map[string][]string{}
	var order []string
	lines := readLines(agentsFile)
	inside := false
	reQuoted := regexp.MustCompile(`"([^"]*)"`)
	for _, line := range lines {
		if strings.HasPrefix(line, "### 3.3") {
			inside = true
			continue
		}
		if inside && strings.HasPrefix(line, "#") {
			break
		}
		if !inside || !strings.HasPrefix(line, "|") {
			continue
		}
		cells := strings.Split(line, "|")
		if len(cells) < 7 {
			continue
		}
		primary := strings.NewReplacer("`", "", " ", "").Replace(cells[4])
		if primary == "" || primary == "PrimarySkill" {
			continue
		}
		if _, exists := rows[primary]; exists {
			continue
		}
		var triggers []string
		for _, match := range reQuoted.FindAllStringSubmatch(cells[3], -1) {
			triggers = append(triggers, strings.ToLower(match[1]))
		}
		rows[primary] = triggers
		order = append(order, primary)
	}
	return rows, order
}

func auditTriggerCoherence() {
	rows, _ := matrixRows()
	for _, skill := range skillsCatalog {
		triggers, ok := rows[skill]
		if !ok {
			emitSK("SK-04", agentsFile, 0, fmt.Sprintf("skill %q has no dispatch-matrix row", skill))
			continue
		}
		if isAdoption() && userOwnedSkill(skill) {
			continue
		}
		frontmatter := strings.ToLower(frontmatterValue(skill, "description"))
		for _, trigger := range triggers {
			if !strings.Contains(frontmatter, trigger) {
				emitSK("SK-04", agentsFile, 0,
					fmt.Sprintf("trigger %q for skill %q is missing from its frontmatter \"Triggers on:\"", trigger, skill))
			}
		}
	}
}

func mirrorPresent(path string) bool {
	_, err := os.Lstat(path)
	return err == nil
}

func mirrorOf(dir, skill string) (string, bool) {
	if !mirrorPresent(dir) {
		return "", false
	}
	if info, err := os.Stat(filepath.Join(dir, skill)); err == nil && info.IsDir() {
		return dir + "/" + skill + "/SKILL.md", true
	}
	if info, err := os.Stat(dir + "/" + skill + ".md"); err == nil && !info.IsDir() {
		return dir + "/" + skill + ".md", true
	}
	if info, err := os.Stat(dir + "/" + skill + ".mdc"); err == nil && !info.IsDir() {
		return dir + "/" + skill + ".mdc", true
	}
	return "", false
}

func auditMirrorParity() int {
	divergences := 0
	for _, dir := range mirrorDirs {
		if !mirrorPresent(dir) {
			continue
		}
		for _, skill := range skillsCatalog {
			canonical := skillDir(skill) + "/SKILL.md"
			if !fileExists(canonical) {
				continue
			}
			mirror, ok := mirrorOf(dir, skill)
			if !ok || !filesEqual(canonical, mirror) {
				emitSK("SK-05", dir, 0,
					fmt.Sprintf("harness mirror %q diverges from .agents/skills for skill %q (run: oaef skills sync-mirrors)", dir, skill))
				divergences++
			}
		}
	}
	return divergences
}

// --- routing ------------------------------------------------------------------

func tokenize(prompt string) []string {
	splitter := regexp.MustCompile(`[^a-z0-9-]+`)
	return splitter.Split(prompt, -1)
}

func candidateForms(token string) []string {
	forms := []string{token}
	if strings.HasSuffix(token, "ies") {
		forms = append(forms, token[:len(token)-3]+"y")
	}
	if strings.HasSuffix(token, "es") {
		forms = append(forms, token[:len(token)-2])
	}
	if strings.HasSuffix(token, "s") {
		forms = append(forms, token[:len(token)-1])
	}
	if strings.HasSuffix(token, "ing") {
		forms = append(forms, token[:len(token)-3])
	}
	if strings.HasSuffix(token, "ed") {
		forms = append(forms, token[:len(token)-2])
	}
	if strings.HasSuffix(token, "ion") {
		forms = append(forms, token[:len(token)-3])
	}
	return forms
}

func commonPrefix(left, right string) int {
	limit := len(left)
	if len(right) < limit {
		limit = len(right)
	}
	for i := 0; i < limit; i++ {
		if left[i] != right[i] {
			return i
		}
	}
	return limit
}

func wordMatch(token, word string) bool {
	if word == "" {
		return false
	}
	for _, form := range candidateForms(token) {
		if form == word {
			return true
		}
		if len(form) >= 4 && commonPrefix(form, word) >= 4 {
			return true
		}
	}
	return false
}

const territoryVocabulary = " features screens pages components shared ui core domain data infra test tests "

func routePrompt(prompt string) string {
	prompt = strings.ToLower(prompt)
	tokens := tokenize(prompt)
	best := "ponytail"
	bestScore := 0
	for _, skill := range skillsCatalog {
		score := 0
		for _, nameWord := range strings.Split(skill, "-") {
			for _, token := range tokens {
				if token == "" {
					continue
				}
				if wordMatch(token, nameWord) {
					score += 5
					break
				}
			}
		}
		for _, trigger := range skillTriggers[skill] {
			weight := len(trigger)
			if weight > 8 {
				weight = 8
			}
			if strings.Contains(trigger, " ") {
				if strings.Contains(prompt, trigger) {
					score += 3 + weight
				}
				continue
			}
			for _, token := range tokens {
				if token == "" {
					continue
				}
				if wordMatch(token, trigger) {
					score += 3 + weight
					break
				}
			}
		}
		for _, token := range tokens {
			if token == "" {
				continue
			}
			if strings.Contains(territoryVocabulary, " "+token+" ") {
				score++
			}
		}
		if score > bestScore {
			bestScore = score
			best = skill
		}
	}
	if bestScore == 0 {
		return "ponytail"
	}
	return best
}

func runSkillsRoute(args []string) {
	query := strings.Join(args, " ")
	primary := routePrompt(query)
	fmt.Printf("Routing: \"%s\"\n", query)
	fmt.Printf("Primary skill: %s %s/SKILL.md\n", primary, skillDir(primary))
	fmt.Printf("Meta-skill: %s\n", metaSkill(primary))
	fmt.Printf("Recipes containing %s:\n", primary)
	for _, recipe := range recipes {
		if strings.Contains(recipe, primary) {
			fmt.Printf("  %s\n", recipe)
		}
	}
}

func runSkillsSelftest() {
	for _, fixture := range routingFixtures {
		prompt, expected := fixture[0], fixture[1]
		got := routePrompt(prompt)
		if got != expected {
			emitSK("SK-06", agentsFile, 0,
				fmt.Sprintf("routing self-test failed: prompt %q resolved to %q but expected %q", prompt, got, expected))
		}
	}
}

func runSkillsAudit(flag string) {
	resolveProfile()
	auditSkillsParity()
	auditSkillsFrontmatter()
	auditEntrypointParity()
	auditTriggerCoherence()
	auditMirrorParity()
	if flag == "--selftest" {
		runSkillsSelftest()
	}
	fmt.Printf("Skills: %d finding(s)\n", skFailures)
	if skFailures > 0 {
		os.Exit(1)
	}
}

func copyDir(src, dst string) error {
	if err := os.MkdirAll(dst, 0o755); err != nil {
		return err
	}
	entries, err := os.ReadDir(src)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		srcPath := filepath.Join(src, entry.Name())
		dstPath := filepath.Join(dst, entry.Name())
		if entry.IsDir() {
			if err := copyDir(srcPath, dstPath); err != nil {
				return err
			}
			continue
		}
		data, err := os.ReadFile(srcPath)
		if err != nil {
			return err
		}
		if err := os.WriteFile(dstPath, data, 0o644); err != nil {
			return err
		}
	}
	return nil
}

func runSkillsSyncMirrors(flag string) {
	checkOnly := flag == "--check"
	resolveProfile()
	repaired := 0
	for _, dir := range mirrorDirs {
		if !mirrorPresent(dir) {
			continue
		}
		if info, err := os.Lstat(dir); err == nil && info.Mode()&os.ModeSymlink != 0 {
			target, _ := os.Readlink(dir)
			if target == "../.agents/skills" {
				if stat, err := os.Stat(dir); err == nil && stat.IsDir() {
					fmt.Printf("✅ %s is a symlink to .agents/skills (parity by construction)\n", dir)
					continue
				}
			}
		}
		if info, err := os.Stat(dir); err != nil || !info.IsDir() {
			continue
		}
		for _, skill := range skillsCatalog {
			canonical := skillDir(skill) + "/SKILL.md"
			if !fileExists(canonical) {
				continue
			}
			if entry, ok := mirrorOf(dir, skill); ok {
				if !checkOnly && !filesEqual(canonical, entry) {
					data, err := os.ReadFile(canonical)
					if err == nil {
						_ = os.WriteFile(entry, data, 0o644)
						fmt.Printf("🔧 %s: repaired mirror for %s (canonical catalog is authoritative)\n", dir, skill)
						repaired++
					}
				}
				continue
			}
			if checkOnly {
				continue
			}
			target := dir + "/" + skill
			if err := os.Symlink("../.agents/skills/"+skill, target); err == nil {
				if _, statErr := os.Stat(target); statErr == nil {
					fmt.Printf("🔧 %s: created mirror link for %s\n", dir, skill)
					repaired++
					continue
				}
			}
			_ = os.Remove(target)
			if err := copyDir(skillDir(skill), target); err == nil {
				fmt.Printf("🔧 %s: created mirror copy for %s\n", dir, skill)
				repaired++
			}
		}
	}
	skFailures = 0
	divergences := auditMirrorParity()
	if checkOnly {
		if divergences > 0 {
			fmt.Printf("Mirrors: %d divergence(s) detected\n", divergences)
			os.Exit(1)
		}
		fmt.Println("Mirrors: parity verified")
		return
	}
	if divergences > 0 {
		fmt.Printf("Mirrors: %d divergence(s) remain (user-owned entries are preserved)\n", divergences)
		os.Exit(1)
	}
	fmt.Printf("Mirrors: %d entry(ies) synchronized, parity verified\n", repaired)
}

// ------------------------------------------------------------------------------
// lint / doctor / quality gate / sync / metrics
// ------------------------------------------------------------------------------

func normalizeMirrorText(text string) string {
	var builder strings.Builder
	for _, line := range strings.Split(text, "\n") {
		if strings.HasPrefix(line, "<!--") {
			continue
		}
		for _, char := range line {
			switch char {
			case ' ', '\t', '\r', '\n':
				continue
			}
			builder.WriteRune(char)
		}
	}
	return builder.String()
}

var (
	reSecretScan   = regexp.MustCompile(`(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)`)
	reSuppression  = regexp.MustCompile(`(//[[:space:]]*ignore:|/\*[[:space:]]*eslint-disable|//[[:space:]]*@ts-ignore|#[[:space:]]*noqa|#[[:space:]]*type:[[:space:]]*ignore|//nolint|#\[allow\(|@Suppress\(|//[[:space:]]*swiftlint:disable|#pragma warning disable)`)
	reSuppressSafe = regexp.MustCompile(`(deprecated_member_use|type=lint|SA1019|CS0618|CS0612|DEPRECATION|DeprecatedCallableAddReplaceWith|#\[allow\(deprecated\)|@typescript-eslint/no-deprecated|W1505|B005|deprecated-method|type:[[:space:]]*ignore\[deprecated\]|DO NOT EDIT|@generated|\.g\.)`)
)

func suppressionScan() []string {
	var hits []string
	skipDirs := map[string]bool{
		".git": true, "node_modules": true, "build": true, "dist": true, "docs": true,
		"tool": true, "templates": true, ".agents": true,
	}
	_ = filepath.WalkDir(".", func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if entry.IsDir() {
			if path != "." && skipDirs[entry.Name()] {
				return fs.SkipDir
			}
			return nil
		}
		rel := filepath.ToSlash(strings.TrimPrefix(path, "./"))
		if strings.HasSuffix(rel, ".md") {
			return nil
		}
		for index, line := range readLines(rel) {
			if reSuppression.MatchString(line) && !reSuppressSafe.MatchString(line) {
				hits = append(hits, fmt.Sprintf("%s:%d:%s", rel, index+1, line))
			}
		}
		return nil
	})
	sort.Strings(hits)
	return hits
}

func secretScan() []string {
	var hits []string
	if !fileExists("docs") {
		return hits
	}
	_ = filepath.WalkDir("docs", func(path string, entry fs.DirEntry, err error) error {
		if err != nil || entry.IsDir() {
			return nil
		}
		rel := filepath.ToSlash(path)
		for index, line := range readLines(rel) {
			if reSecretScan.MatchString(line) {
				hits = append(hits, fmt.Sprintf("%s:%d:%s", rel, index+1, line))
			}
		}
		return nil
	})
	return hits
}

func runLint() {
	resolveProfile()
	failed := false

	if fileExists(agentsFile) && fileExists("CLAUDE.md") {
		agents, errA := os.ReadFile(agentsFile)
		claude, errB := os.ReadFile("CLAUDE.md")
		if errA == nil && errB == nil && normalizeMirrorText(string(agents)) != normalizeMirrorText(string(claude)) {
			fmt.Fprintln(os.Stderr, `❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run "oaef sync".`)
			failed = true
		}
	}

	if hits := secretScan(); len(hits) > 0 {
		for _, hit := range hits {
			fmt.Println(hit)
		}
		fmt.Fprintln(os.Stderr, "🚨 [SECURITY] Potential secret detected in docs/!")
		failed = true
	}

	if hits := suppressionScan(); len(hits) > 0 {
		fmt.Fprintln(os.Stderr, "🚨 [LINT] Unallowed linter/compiler suppression comments detected:")
		for _, hit := range hits {
			fmt.Fprintln(os.Stderr, hit)
		}
		failed = true
	}

	runCleanCodeChecks()
	auditSkillsParity()
	auditSkillsFrontmatter()
	auditEntrypointParity()
	auditTriggerCoherence()
	auditMirrorParity()
	runSkillsSelftest()
	if skFailures > 0 {
		failed = true
	}

	if failed {
		fmt.Fprintln(os.Stderr, "❌ LINT FAILED.")
		os.Exit(1)
	}
	fmt.Println("✅ [LINT] All integrity and secret audits passed cleanly.")
}

var requiredConformanceFiles = []string{
	"AGENTS.md", "CLAUDE.md", "llms.txt", "oaef.context.json",
	"docs/INDEX.md", "docs/MANIFESTO.md", "docs/DESIGN.md", "docs/HARNESSES.md",
	"docs/standards/coding_patterns.md", "docs/standards/testing.md", "docs/standards/logging.md",
	"docs/standards/clean_code.md", "docs/standards/solid.md", "docs/standards/review.md",
	"docs/standards/analytics_and_telemetry.md", "docs/standards/governance_checks.md",
	"docs/wiki/metrics/baseline.json", "docs/wiki/memory/handoff.md", "docs/wiki/log.md",
	".github/workflows/ci.yml", ".github/pull_request_template.md", ".gitignore",
	"CONTRIBUTING.md", "SECURITY.md",
}

func runConform() {
	resolveProfile()
	checks := 0
	passed := 0
	failed := false
	check := func(condition bool, label string) {
		checks++
		if condition {
			passed++
			fmt.Printf("✅ %s\n", label)
			return
		}
		fmt.Fprintf(os.Stderr, "❌ %s\n", label)
		failed = true
	}

	fmt.Println("🩺 OAEF Conformance Audit (doctor)...")
	for _, required := range requiredConformanceFiles {
		check(fileExists(required), required+" present")
	}
	for _, skill := range skillsCatalog {
		check(fileExists(skillDir(skill)+"/SKILL.md"), ".agents/skills/"+skill+"/SKILL.md present")
	}

	if fileExists(agentsFile) && fileExists("CLAUDE.md") {
		agents, errA := os.ReadFile(agentsFile)
		claude, errB := os.ReadFile("CLAUDE.md")
		check(errA == nil && errB == nil && normalizeMirrorText(string(agents)) == normalizeMirrorText(string(claude)),
			"CLAUDE.md mirror parity verified")
	} else {
		check(false, "mirror parity not verifiable (missing AGENTS.md or CLAUDE.md)")
	}

	placeholders := regexp.MustCompile(`\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}`)
	placeholderHits := false
	for _, candidate := range []string{agentsFile, llmsFile} {
		if data, err := os.ReadFile(candidate); err == nil && placeholders.Match(data) {
			placeholderHits = true
		}
	}
	check(!placeholderHits, "no unresolved template placeholders")

	divergences := auditMirrorParity()
	check(divergences == 0, "harness skill mirrors in parity")

	skFailures = 0
	runSkillsSelftest()
	check(skFailures == 0, "routing self-test (SK-06) passed")

	fmt.Printf("\n📊 Conformance: %d/%d checks passed\n", passed, checks)
	if failed {
		os.Exit(1)
	}
}

func runQualityGate() {
	resolveProfile()
	fmt.Println("🔍 Initiating OAEF Quality Gate Audit (Go)...")

	oversized := 0
	for _, file := range productionFiles() {
		if data, err := os.ReadFile(file); err == nil {
			lineCount := strings.Count(string(data), "\n")
			if lineCount > 300 {
				fmt.Fprintf(os.Stderr, "⚠️  Oversized file (%dL > 300L): %s\n", lineCount, file)
				oversized++
			}
		}
	}
	if oversized > 0 {
		fmt.Fprintf(os.Stderr, "❌ Quality Gate Failed: %d oversized files detected.\n", oversized)
		os.Exit(1)
	}

	if fileExists("go.mod") {
		fmt.Println("ℹ️  Running go test with coverage...")
		testCommand := exec.Command("go", "test", "-coverprofile=coverage.out", "./...")
		testCommand.Stdout = os.Stdout
		testCommand.Stderr = os.Stderr
		if err := testCommand.Run(); err != nil {
			fmt.Fprintln(os.Stderr, "❌ Tests failed.")
			os.Exit(1)
		}
	}

	runCleanCodeChecks()
	printCleanCodeSummary()
	if profile == "strict" && !isAdoption() && ccTotal > 0 {
		fmt.Fprintf(os.Stderr, "❌ Quality Gate Failed: %d clean-code violation(s).\n", ccTotal)
		os.Exit(1)
	}
	fmt.Println("🎉 Quality Gates PASSED!")
}

func runSync() {
	data, err := os.ReadFile(agentsFile)
	if err != nil {
		return
	}
	var builder strings.Builder
	builder.WriteString("<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n")
	builder.WriteString("<!-- To modify rules, edit AGENTS.md and run 'oaef sync'. -->\n")
	builder.WriteString("\n")
	builder.Write(data)
	if err := os.WriteFile("CLAUDE.md", []byte(builder.String()), 0o644); err != nil {
		return
	}
	fmt.Println("✅ Synchronized AGENTS.md -> CLAUDE.md")
}

func runMetrics() {
	data, err := os.ReadFile(baselineFile)
	if err != nil {
		return
	}
	fmt.Print(string(data))
}

func usage() {
	fmt.Println("OAEF Governance Tool (Go Engine)")
	fmt.Println("Usage: go run tool/governance.go <command>")
	fmt.Println("Commands:")
	fmt.Println("  quality-gate|audit        Quality Gate audit (coverage, sizing, clean code)")
	fmt.Println("  clean-code                Governance barriers (docs/standards/governance_checks.md)")
	fmt.Println("  ponytail-debt             Report every \"// ponytail:\" debt marker (PT-01)")
	fmt.Println("  ponytail-audit            Advisory anti-slop audit")
	fmt.Println("  skills-audit [--selftest] Skill activation invariants (SK-01..SK-06)")
	fmt.Println("  skills-route \"<query>\"    Resolve a prompt to its governing skill and recipe")
	fmt.Println("  skills sync-mirrors [--check] Rebuild or validate the harness skill mirrors")
	fmt.Println("  lint                      Mirror parity, secrets, anti-suppression, skills")
	fmt.Println("  doctor|conform            Conformance audit")
	fmt.Println("  metrics                   Display baseline thresholds")
	fmt.Println("  sync                      Synchronize AGENTS.md to CLAUDE.md")
}

func firstOr(args []string, fallback string) string {
	if len(args) > 0 {
		return args[0]
	}
	return fallback
}

func secondOr(args []string, fallback string) string {
	if len(args) > 1 {
		return args[1]
	}
	return fallback
}

func contains(args []string, wanted string) bool {
	for _, arg := range args {
		if arg == wanted {
			return true
		}
	}
	return false
}

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}
	command := os.Args[1]
	args := os.Args[2:]

	switch command {
	case "quality-gate", "audit":
		runQualityGate()
	case "clean-code", "governance-check":
		runCleanCode(contains(args, "--standard"))
	case "ponytail-debt":
		runPonytailDebt()
	case "ponytail-audit":
		runPonytailAudit()
	case "ponytail":
		if firstOr(args, "debt") == "audit" {
			runPonytailAudit()
		} else {
			runPonytailDebt()
		}
	case "skills-audit":
		runSkillsAudit(firstOr(args, ""))
	case "skills-route":
		runSkillsRoute(args)
	case "skills":
		switch firstOr(args, "") {
		case "sync-mirrors":
			runSkillsSyncMirrors(secondOr(args, ""))
		case "audit":
			runSkillsAudit(secondOr(args, ""))
		case "route":
			runSkillsRoute(args[1:])
		default:
			usage()
			os.Exit(1)
		}
	case "lint":
		runLint()
	case "conform", "doctor":
		runConform()
	case "metrics":
		runMetrics()
	case "sync":
		runSync()
	default:
		usage()
		os.Exit(1)
	}
}
