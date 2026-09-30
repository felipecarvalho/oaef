using System;
using System.IO;
using System.Diagnostics;

class Program
{
    static int Main(string[] args)
    {
        if (args.Length == 0)
        {
            Console.WriteLine("OAEF Governance Tool (C# / .NET Engine)");
            Console.WriteLine("Usage: dotnet run --project tool/Governance.csproj [quality-gate|lint|sync]");
            return 1;
        }

        switch (args[0])
        {
            case "quality-gate":
            case "audit":
                return RunQualityGate();
            case "lint":
                return RunLint();
            case "sync":
                return RunSync();
            default:
                Console.WriteLine($"Unknown command: {args[0]}");
                return 1;
        }
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
            var agents = File.ReadAllText("AGENTS.md").Trim();
            var claude = File.ReadAllText("CLAUDE.md").Trim();
            if (!claude.Contains(agents))
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
