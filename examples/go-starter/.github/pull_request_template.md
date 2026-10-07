## Description
<!-- Provide a clear, concise summary of the changes and the architectural motivation. -->

## Changes Made
<!-- Bulleted list of specific changes, new files, or modifications. -->
- 

## Ecosystem / Stack Impact
<!-- Which tech stacks are affected? (e.g., universal, dart-flutter, react-native, expo, etc.) -->

## Governing Skills
<!-- Declare the skills consulted before planning, one path per applicable skill (see AGENTS.md section 4.18). -->
> Governing Skills: [.agents/skills/<skill>/SKILL.md]

## Agent Skills Applied
<!-- Check every canonical skill exercised by this change; leave unchecked the ones not used. -->
- [ ] `ponytail`
- [ ] `nullable-types`
- [ ] `architecture-audit`
- [ ] `screen-builder`
- [ ] `component-author`
- [ ] `responsive-layout`
- [ ] `ui-preview`
- [ ] `fix-layout-issues`
- [ ] `test-generator`
- [ ] `collect-coverage`
- [ ] `run-static-analysis`
- [ ] `code-review`
- [ ] `conformance-audit`

## Documentation Touched
<!-- Mark every documentation surface updated by this change, or N/A. -->
- [ ] `README.md`
- [ ] `docs/adr/`
- [ ] `docs/standards/`
- [ ] `docs/wiki/log.md`
- [ ] `docs/wiki/memory/handoff.md`
- [ ] `N/A`

## Evidence
<!-- Paste the commands executed and their outcome: test suite, coverage report, analyzer/lint output. -->

## Decisions & Tradeoffs
<!-- Record at least one decision and at least one tradeoff. -->
Decision:
Tradeoff:

## Breaking Changes?
<!-- Describe any breaking change and the migration path; write "No" when there is none. -->

## Contributor Quality Checklist
<!-- Verify each requirement before requesting review. No empty checkbox may remain in a submitted pull request. -->
- [ ] Inviolable Trust Hierarchy respected (Compiler & tests take precedence over assumptions)
- [ ] Strict Clean Code adhered to (No cryptic abbreviations, no single-letter vars, small functions <= 30 LOC)
- [ ] Zero unallowed suppressions (No inline ignore comments without allowed external deprecation tokens)
- [ ] Clean sizing respected (Files <= 300 LOC, functions <= 50 LOC)
- [ ] Automated tests pass and meet Quality Gate coverage floors
- [ ] Zero secrets, API keys, credentials, or PII committed
- [ ] Zero silent exception swallowing (every catch/except logs with error and stack trace, or rethrows)
- [ ] Zero service-locator leakage outside the composition root (dependencies injected via constructor)
- [ ] Zero unimplemented placeholders in production contracts (no Liskov-violating stubs)
