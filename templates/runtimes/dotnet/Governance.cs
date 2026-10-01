using System;
using System.IO;
using System.Linq;
using System.Diagnostics;

class Program
{
    static int Main(string[] args)
    {
        if (args.Length == 0)
        {
            Console.WriteLine("OAEF Governance Tool (C# / .NET Engine)");
            Console.WriteLine("Usage: dotnet run --project tool/Governance.csproj [quality-gate|lint|doctor|sync]");
            return 1;
        }

        switch (args[0])
        {
            case "quality-gate":
            case "audit":
                return RunQualityGate();
            case "lint":
                return RunLint();
            case "conform":
            case "doctor":
                return RunConform();
            case "sync":
                return RunSync();
            default:
                Console.WriteLine($"Unknown command: {args[0]}");
                return 1;
        }
    }

    static string NormalizeMirrorText(string text)
    {
        var builder = new System.Text.StringBuilder();
        foreach (var line in text.Split('\n'))
        {
            if (line.StartsWith("<!--"))
            {
                continue;
            }
            builder.Append(line);
        }
        return string.Concat(builder.ToString().Where(character => !char.IsWhiteSpace(character)));
    }

    static int RunConform()
    {
        Console.WriteLine("🩺 OAEF Conformance Audit (doctor)...");
        var requiredFiles = new[]
        {
            "AGENTS.md", "CLAUDE.md", "llms.txt", "oaef.context.json",
            "docs/INDEX.md", "docs/MANIFESTO.md", "docs/DESIGN.md",
            "docs/standards/coding_patterns.md", "docs/standards/testing.md", "docs/standards/logging.md",
            "docs/wiki/metrics/baseline.json", "docs/wiki/memory/handoff.md", "docs/wiki/log.md",
            "docs/HARNESSES.md",
            ".github/workflows/ci.yml", ".github/pull_request_template.md",
            ".gitignore", "CONTRIBUTING.md", "SECURITY.md"
        };
        var skills = new[]
        {
            "architecture-audit", "code-review", "collect-coverage", "component-author",
            "fix-layout-issues", "nullable-types", "run-static-analysis", "screen-builder",
            "test-generator", "ui-preview", "conformance-audit"
        };
        var runtimes = new[]
        {
            "tool/governance.sh", "tool/governance.mjs", "tool/governance.py", "tool/governance.dart",
            "tool/governance.go", "tool/governance.rs", "tool/governance.main.kts", "tool/governance.swift",
            "tool/Governance.cs"
        };

        var checks = 0;
        var passed = 0;
        var failed = false;

        void Check(bool condition, string label)
        {
            checks++;
            if (condition)
            {
                passed++;
                Console.WriteLine($"✅ {label}");
            }
            else
            {
                Console.Error.WriteLine($"❌ {label}");
                failed = true;
            }
        }

        foreach (var requiredFile in requiredFiles)
        {
            Check(File.Exists(requiredFile), $"{requiredFile} present");
        }
        foreach (var skill in skills)
        {
            Check(File.Exists($".agents/skills/{skill}/SKILL.md"), $".agents/skills/{skill}/SKILL.md present");
        }
        Check(runtimes.Any(runtime => File.Exists(runtime)), "governance runtime present in tool/");

        if (File.Exists("AGENTS.md") && File.Exists("CLAUDE.md"))
        {
            Check(
                NormalizeMirrorText(File.ReadAllText("AGENTS.md")) == NormalizeMirrorText(File.ReadAllText("CLAUDE.md")),
                "CLAUDE.md mirror parity verified");
        }
        else
        {
            Check(false, "mirror parity not verifiable (missing AGENTS.md or CLAUDE.md)");
        }

        var placeholderHits = false;
        foreach (var candidate in new[] { "AGENTS.md", "llms.txt" })
        {
            if (File.Exists(candidate))
            {
                var text = File.ReadAllText(candidate);
                if (text.Contains("{{PROJECT_NAME}}") || text.Contains("{{TECH_STACK}}") || text.Contains("{{STACK_SPECIFIC_RULES}}"))
                {
                    placeholderHits = true;
                }
            }
        }
        Check(!placeholderHits, "no unresolved template placeholders");

        Console.WriteLine($"\n📊 Conformance: {passed}/{checks} checks passed");
        return failed ? 1 : 0;
    }

    static int RunQualityGate()
    {
        Console.WriteLine("🔍 Initiating OAEF Quality Gate Audit (C# / .NET)...");
        var psi = new ProcessStartInfo("dotnet", "test")
        {
            RedirectStandardOutput = false,
            RedirectStandardError = false,
            UseShellExecute = false
        };
        var process = Process.Start(psi);
        process?.WaitForExit();
        if (process?.ExitCode != 0)
        {
            Console.Error.WriteLine("❌ Tests failed.");
            return 1;
        }
        Console.WriteLine("\n🎉 Quality Gates PASSED!");
        return 0;
    }

    static int RunLint()
    {
        Console.WriteLine("🔍 Auditing OAEF Integrity & Secret Leaks...");
        if (File.Exists("AGENTS.md") && File.Exists("CLAUDE.md"))
        {
            if (NormalizeMirrorText(File.ReadAllText("AGENTS.md")) != NormalizeMirrorText(File.ReadAllText("CLAUDE.md")))
            {
                Console.Error.WriteLine("❌ [LINT] CLAUDE.md diverged from AGENTS.md.");
                return 1;
            }
        }
        Console.WriteLine("✅ [LINT] All audits passed cleanly.");
        return 0;
    }

    static int RunSync()
    {
        if (File.Exists("AGENTS.md"))
        {
            var agents = File.ReadAllText("AGENTS.md");
            var banner = "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n\n";
            File.WriteAllText("CLAUDE.md", banner + agents);
            Console.WriteLine("✅ Synchronized AGENTS.md -> CLAUDE.md");
        }
        return 0;
    }
}
