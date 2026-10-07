// ==============================================================================
// OAEF Governance Engine (C# / .NET)
// Implements docs/standards/governance_checks.md for the `dotnet` stack.
// Invocation: dotnet run --project tool/Governance.csproj <command>
// Author: Felipe Carvalho | License: Apache 2.0
// ==============================================================================

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Text.RegularExpressions;

class Program
{
    // --------------------------------------------------------------------------
    // Canonical catalog (must stay byte-identical to AGENTS.md section 3)
    // --------------------------------------------------------------------------
    static readonly string[] Skills = new string[]
    {
        "ponytail", "nullable-types", "architecture-audit", "screen-builder", "component-author",
        "responsive-layout", "ui-preview", "fix-layout-issues", "test-generator", "collect-coverage",
        "run-static-analysis", "code-review", "conformance-audit"
    };

    static readonly string[] MirrorDirs = new string[]
    {
        ".claude/skills", ".cursor/rules", ".windsurf/skills", ".cline/skills", ".grok/agents"
    };

    static readonly string[] EngineFiles = new string[]
    {
        "tool/governance.dart", "tool/governance.mjs", "tool/governance.py", "tool/governance.go",
        "tool/governance.rs", "tool/governance.main.kts", "tool/governance.swift",
        "tool/Governance.cs", "tool/governance.sh"
    };

    static readonly string[] Recipes = new string[]
    {
        "1. Feature / Screen Construction: ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review",
        "2. Reusable Component / Module Authoring: ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis",
        "3. Bug Fix / Root-Cause Remediation: ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis",
        "4. Domain, Data & Infrastructure: ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis",
        "5. Pre-Submission / Pull Request Cycle: collect-coverage -> run-static-analysis -> code-review"
    };

    static readonly string[] RoutingFixtures = new string[]
    {
        "create a new screen for the booking flow|screen-builder",
        "build a reusable button component|component-author",
        "the layout overflows on small screens|fix-layout-issues",
        "add responsive breakpoints for tablet|responsive-layout",
        "write unit tests for the payment service|test-generator",
        "collect coverage and check the branch floor|collect-coverage",
        "fix all analyzer warnings|run-static-analysis",
        "this optional list parameter is always null|nullable-types",
        "audit module boundaries and cyclic imports|architecture-audit",
        "verify the repo conforms to the framework|conformance-audit",
        "review my PR before I open it|code-review",
        "remove the dead code and the 1-line use case|ponytail"
    };

    static readonly string[] RequiredFiles = new string[]
    {
        "AGENTS.md", "CLAUDE.md", "llms.txt", "oaef.context.json",
        "docs/INDEX.md", "docs/MANIFESTO.md", "docs/DESIGN.md", "docs/HARNESSES.md",
        "docs/standards/coding_patterns.md", "docs/standards/testing.md", "docs/standards/logging.md",
        "docs/standards/clean_code.md", "docs/standards/solid.md", "docs/standards/review.md",
        "docs/standards/analytics_and_telemetry.md", "docs/standards/governance_checks.md",
        "docs/wiki/metrics/baseline.json", "docs/wiki/memory/handoff.md", "docs/wiki/log.md",
        ".github/workflows/ci.yml", ".github/pull_request_template.md",
        ".gitignore", "CONTRIBUTING.md", "SECURITY.md"
    };

    static readonly string[] CcIds = new string[]
    {
        "CC-01", "CC-02", "CC-03", "CC-04", "CC-05", "CC-06",
        "CC-07", "CC-08", "CC-09", "CC-10", "CC-11"
    };

    // Production scope: repository root recursive, *.cs only (governance_checks.md 2.1)
    static readonly string[] ExcludedSegments = new string[]
    {
        ".git", ".github", ".agents", ".claude", ".cursor", ".windsurf", ".cline", ".grok", ".oaef",
        "node_modules", "vendor", "build", "dist", "target", "obj", "bin", "tool", "docs", "templates",
        "examples", "coverage", "generated", ".venv", "venv", "__pycache__", ".dart_tool", ".gradle", ".idea"
    };

    static readonly string[] TestSegments = new string[]
    {
        "test", "tests", "__tests__", "spec", "specs", "androidTest", "iosTest"
    };

    static readonly string[] Cryptic = new string[]
    {
        "cb", "fn", "res", "req", "btn", "val", "tmp", "ctx", "el", "usr",
        "mgr", "idx", "cnt", "buf", "str", "num", "doc", "elem", "curr", "prev"
    };

    static readonly string[] ServiceLocatorTokens = new string[]
    {
        "serviceProvider.GetService<", "GetRequiredService<", "ServiceLocator.Get<"
    };

    static readonly string[] SuppressionAllowlist = new string[]
    {
        "CS0618", "CS0612", "DEPRECATION", "deprecated-method", "DO NOT EDIT", "@generated", ".g."
    };

    // --------------------------------------------------------------------------
    // Regexes (line by line; see governance_checks.md section 4.1)
    // --------------------------------------------------------------------------
    // CC-01 binding sites: lambda parameters, catch bindings and local declarations.
    static readonly Regex RxDeclaration = new Regex(@"(?:^|[^A-Za-z0-9_.])(var|string|bool)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=");
    static readonly Regex RxLambda = new Regex(@"(\([^()]*\)|[A-Za-z_][A-Za-z0-9_]*)\s*=>");
    static readonly Regex RxCatchBinding = new Regex(@"catch\s*\(([^)]*)\)");
    static readonly Regex RxLastIdentifier = new Regex(@"([A-Za-z_][A-Za-z0-9_]*)\s*$");
    static readonly Regex RxIdentifierOnly = new Regex(@"^([A-Za-z_][A-Za-z0-9_]*)$");

    // CC-04 placeholder / secret keys.
    static readonly Regex RxSecret = new Regex(@"(dummy_|changeme|TODO_KEY|(api[_-]?key|apikey|secret|password|token)\s*[:=]\s*""[^""]*"")");

    // CC-05 raw print / debug output.
    static readonly Regex RxPrint = new Regex(@"Console\.Error\.Write(Line)?\(|Console\.Write(Line)?\(|Debug\.WriteLine\(");

    // CC-06 empty handler detection.
    static readonly Regex RxCatchInlineEmpty = new Regex(@"catch\s*(\([^)]*\))?\s*\{\s*\}\s*(//.*)?$");
    static readonly Regex RxCatchBlockOpen = new Regex(@"catch\s*(\([^)]*\))?\s*\{\s*$");
    static readonly Regex RxCatchHeaderOnly = new Regex(@"catch\s*(\([^)]*\))?\s*$");

    // CC-08 nullable collection parameters.
    static readonly Regex RxNullableCollection = new Regex(@"(?:^|[^A-Za-z0-9_.])(List|IEnumerable|Dictionary)\s*<[^<>;()]*>\s*\?\s+([A-Za-z_][A-Za-z0-9_]*)\b(?!\s*\()");

    // CC-09 / CC-10 unimplemented placeholders and concrete network clients.
    static readonly Regex RxUnimplemented = new Regex(@"new\s+(System\.)?NotImplementedException\s*\(");
    static readonly Regex RxHttpClient = new Regex(@"new\s+([A-Za-z_][A-Za-z0-9_]*\.)*HttpClient\s*\(");

    // CC-11 loop detection.
    static readonly Regex RxLoopKeyword = new Regex(@"\b(for|foreach|while|do)\b");

    // Frontmatter and lint helpers.
    static readonly Regex RxFrontmatterKey = new Regex(@"^([A-Za-z][A-Za-z0-9_-]*):\s*(.*)$");
    static readonly Regex RxBlockScalar = new Regex(@"^[>|][-+]?$");
    static readonly Regex RxSuppression = new Regex(@"//\s*ignore:|/\*\s*eslint-disable|//\s*@ts-ignore|#\s*noqa|#\s*type:\s*ignore|//nolint|#\[allow\(|@Suppress\(|//\s*swiftlint:disable|#pragma\s+warning\s+disable");
    static readonly Regex RxSecretPattern = new Regex(@"sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----");
    static readonly Regex RxCoverageRate = new Regex("line-rate=\"([0-9.]+)\"");

    // --------------------------------------------------------------------------
    // Status glyphs and paths
    // --------------------------------------------------------------------------
    const string Dash = "\u2014";
    const string IconSearch = "\U0001F50D";
    const string IconCheck = "\u2705";
    const string IconCross = "\u274C";
    const string IconAlert = "\U0001F6A8";
    const string IconChart = "\U0001F4CA";
    const string IconParty = "\U0001F389";
    const string IconStethoscope = "\U0001FA7A";
    const string IconWrench = "\U0001F527";
    const string IconLock = "\U0001F512";
    const string IconInfo = "\u2139\uFE0F";
    const string IconWarning = "\u26A0\uFE0F";

    const string ContextFile = "oaef.context.json";
    const string BaselineFile = "docs/wiki/metrics/baseline.json";
    const string AdoptionLedger = "docs/wiki/metrics/adoption.json";
    const string AgentsFile = "AGENTS.md";
    const string ClaudeFile = "CLAUDE.md";
    const string LlmsFile = "llms.txt";

    static string Root = ".";

    // --------------------------------------------------------------------------
    // Global state
    // --------------------------------------------------------------------------
    static string Profile = "strict";
    static string AdoptionMode = "install";
    static int CcTotal = 0;
    static readonly Dictionary<string, int> CcCounts = new Dictionary<string, int>();
    static int SkFailures = 0;

    // --------------------------------------------------------------------------
    // Entry point
    // --------------------------------------------------------------------------
    static int Main(string[] args)
    {
        Root = ResolveRoot();
        if (args.Length == 0)
        {
            Usage();
            return 1;
        }

        string command = args[0];
        string[] rest = SubArray(args, 1);

        switch (command)
        {
            case "quality-gate":
            case "audit":
                return RunQualityGate(rest);
            case "metrics":
                return RunMetrics();
            case "lint":
                return RunLint();
            case "conform":
            case "doctor":
                return RunConform();
            case "sync":
                return RunSync();
            case "clean-code":
            case "governance-check":
                return RunCleanCode(rest);
            case "ponytail-debt":
                return RunPonytailDebt();
            case "ponytail-audit":
                return RunPonytailAudit();
            case "ponytail":
                if (rest.Length > 0 && rest[0] == "debt")
                {
                    return RunPonytailDebt();
                }
                return RunPonytailAudit();
            case "skills-audit":
                return RunSkillsAudit(rest);
            case "skills-route":
                return RunSkillsRoute(rest);
            case "skills-sync-mirrors":
                return RunSkillsSyncMirrors(rest);
            case "skills":
                if (rest.Length == 0)
                {
                    Usage();
                    return 1;
                }
                switch (rest[0])
                {
                    case "sync-mirrors":
                        return RunSkillsSyncMirrors(SubArray(rest, 1));
                    case "audit":
                        return RunSkillsAudit(SubArray(rest, 1));
                    case "route":
                        return RunSkillsRoute(SubArray(rest, 1));
                    default:
                        Usage();
                        return 1;
                }
            default:
                Usage();
                return 1;
        }
    }

    static void Usage()
    {
        Console.WriteLine("OAEF Governance Tool (C# / .NET Engine)");
        Console.WriteLine("Usage: dotnet run --project tool/Governance.csproj <command>");
        Console.WriteLine("Commands:");
        Console.WriteLine("  quality-gate|audit [--record] Quality Gate audit (coverage, sizing, clean code)");
        Console.WriteLine("  clean-code [--standard]       Governance barriers (docs/standards/governance_checks.md)");
        Console.WriteLine("  ponytail-debt                 Report every ponytail: debt marker (PT-01)");
        Console.WriteLine("  ponytail-audit                Advisory anti-slop audit");
        Console.WriteLine("  skills-audit [--selftest]     Skill activation invariants (SK-01..SK-06)");
        Console.WriteLine("  skills-route \"<query>\"        Resolve a prompt to its governing skill and recipe");
        Console.WriteLine("  skills-sync-mirrors [--check] Rebuild or validate the harness skill mirrors");
        Console.WriteLine("  lint                          Mirror parity, secrets, anti-suppression, clean code, skills");
        Console.WriteLine("  doctor|conform                Conformance audit");
        Console.WriteLine("  metrics                       Display baseline thresholds");
        Console.WriteLine("  sync                          Synchronize AGENTS.md to CLAUDE.md");
    }

    static string[] SubArray(string[] source, int start)
    {
        if (start >= source.Length)
        {
            return new string[0];
        }
        string[] result = new string[source.Length - start];
        Array.Copy(source, start, result, 0, result.Length);
        return result;
    }

    static bool HasFlag(string[] args, string flag)
    {
        foreach (string argument in args)
        {
            if (argument == flag)
            {
                return true;
            }
        }
        return false;
    }

    // --------------------------------------------------------------------------
    // Repository root resolution (dotnet run may change the working directory)
    // --------------------------------------------------------------------------
    static string ResolveRoot()
    {
        string[] starts = new string[] { Environment.CurrentDirectory, AppContext.BaseDirectory };
        foreach (string start in starts)
        {
            try
            {
                DirectoryInfo info = new DirectoryInfo(Path.GetFullPath(start));
                while (info != null)
                {
                    if (File.Exists(Path.Combine(info.FullName, AgentsFile)) ||
                        File.Exists(Path.Combine(info.FullName, ContextFile)) ||
                        (Directory.Exists(Path.Combine(info.FullName, "tool")) &&
                         File.Exists(Path.Combine(info.FullName, "tool", "Governance.cs"))))
                    {
                        return info.FullName;
                    }
                    info = info.Parent;
                }
            }
            catch
            {
                // Fall through to the next candidate.
            }
        }
        return Environment.CurrentDirectory;
    }

    // --------------------------------------------------------------------------
    // Profile, adoption mode and baseline thresholds
    // --------------------------------------------------------------------------
    static string ReadText(string relativePath)
    {
        try
        {
            return File.ReadAllText(Path.Combine(Root, relativePath));
        }
        catch
        {
            return "";
        }
    }

    static string[] ReadLines(string relativePath)
    {
        try
        {
            return File.ReadAllLines(Path.Combine(Root, relativePath));
        }
        catch
        {
            return new string[0];
        }
    }

    static bool Exists(string relativePath)
    {
        try
        {
            return File.Exists(Path.Combine(Root, relativePath)) || Directory.Exists(Path.Combine(Root, relativePath));
        }
        catch
        {
            return false;
        }
    }

    static string JsonValue(string relativePath, string key)
    {
        string text = ReadText(relativePath);
        if (text.Length == 0)
        {
            return "";
        }
        Match match = Regex.Match(text, "\"" + Regex.Escape(key) + "\"\\s*:\\s*\"([^\"]*)\"");
        return match.Success ? match.Groups[1].Value : "";
    }

    static double BaselineNumber(string section, string key, double fallback)
    {
        string text = ReadText(BaselineFile);
        if (text.Length == 0)
        {
            return fallback;
        }
        int sectionIndex = text.IndexOf("\"" + section + "\"", StringComparison.Ordinal);
        string scope = sectionIndex >= 0 ? text.Substring(sectionIndex) : text;
        Match match = Regex.Match(scope, "\"" + Regex.Escape(key) + "\"\\s*:\\s*([0-9][0-9.]*)");
        if (!match.Success)
        {
            return fallback;
        }
        double parsed;
        if (double.TryParse(match.Groups[1].Value, NumberStyles.Float, CultureInfo.InvariantCulture, out parsed))
        {
            return parsed;
        }
        return fallback;
    }

    static void ResolveProfile(bool forceStandard)
    {
        Profile = "strict";
        string contextProfile = JsonValue(ContextFile, "strictness");
        if (contextProfile.Length > 0)
        {
            Profile = contextProfile;
        }
        else
        {
            string baselineProfile = JsonValue(BaselineFile, "profile");
            if (baselineProfile.Length > 0)
            {
                Profile = baselineProfile;
            }
        }
        string adoption = JsonValue(ContextFile, "adoption_mode");
        AdoptionMode = adoption.Length > 0 ? adoption : "install";
        if (forceStandard)
        {
            Profile = "standard";
        }
    }

    static bool IsAdoption()
    {
        return AdoptionMode != "install";
    }

    static bool UserOwnedSkill(string skill)
    {
        string text = ReadText(AdoptionLedger);
        if (text.Length == 0)
        {
            return false;
        }
        int start = text.IndexOf("\"user_skills\"", StringComparison.Ordinal);
        if (start < 0)
        {
            return false;
        }
        int end = text.IndexOf(']', start);
        if (end < 0)
        {
            end = text.Length;
        }
        string slice = text.Substring(start, end - start);
        return Regex.IsMatch(slice, "\"" + Regex.Escape(skill) + "\"");
    }

    static bool CcBlocking(string checkId)
    {
        if (checkId == "CC-04")
        {
            return true;
        }
        if (checkId == "CC-11")
        {
            return false;
        }
        if (IsAdoption())
        {
            return false;
        }
        return Profile == "strict";
    }

    static string ThresholdKey(string checkId)
    {
        switch (checkId)
        {
            case "CC-01": return "max_single_letter_identifiers";
            case "CC-02": return "max_cryptic_abbreviations";
            case "CC-03": return "max_mutable_lazy_initializations";
            case "CC-04": return "max_dummy_keys";
            case "CC-05": return "max_raw_prints";
            case "CC-06": return "max_silent_catches";
            case "CC-07": return "max_service_locator_leaks";
            case "CC-08": return "max_nullable_collections";
            case "CC-09": return "max_unimplemented_placeholders";
            case "CC-10": return "max_concrete_client_instantiations";
            case "CC-11": return "max_avoidable_allocations";
            default: return "";
        }
    }

    static int CcThreshold(string checkId)
    {
        string key = ThresholdKey(checkId);
        if (key.Length == 0)
        {
            return 0;
        }
        return (int)BaselineNumber("clean_code", key, 0.0);
    }

    // --------------------------------------------------------------------------
    // File discovery
    // --------------------------------------------------------------------------
    static bool IsGeneratedName(string name)
    {
        return name.Contains(".g.") ||
               name.EndsWith("_pb2.py", StringComparison.Ordinal) ||
               name.EndsWith("_pb2_grpc.py", StringComparison.Ordinal) ||
               name.Contains(".min.js") ||
               name.Contains(".generated.") ||
               name.Contains(".freezed.") ||
               name.Contains(".designer.");
    }

    static bool IsExcludedPath(string relativePath)
    {
        string[] segments = relativePath.Split('/');
        foreach (string segment in segments)
        {
            if (Array.IndexOf(ExcludedSegments, segment) >= 0)
            {
                return true;
            }
        }
        return false;
    }

    static bool IsTestPath(string relativePath)
    {
        string[] segments = relativePath.Split('/');
        foreach (string segment in segments)
        {
            if (Array.IndexOf(TestSegments, segment) >= 0)
            {
                return true;
            }
        }
        string name = FileName(relativePath);
        return name.EndsWith("Tests.cs", StringComparison.Ordinal) ||
               name.EndsWith("Test.kt", StringComparison.Ordinal) ||
               name.Contains("_test.") ||
               name.Contains(".spec.") ||
               name.Contains(".test.") ||
               (name.StartsWith("test_", StringComparison.Ordinal) && name.EndsWith(".py", StringComparison.Ordinal));
    }

    static string FileName(string relativePath)
    {
        int slash = relativePath.LastIndexOf('/');
        return slash >= 0 ? relativePath.Substring(slash + 1) : relativePath;
    }

    static void WalkFiles(string absoluteDirectory, string relativeDirectory, List<string> results)
    {
        string[] files;
        try
        {
            files = Directory.GetFiles(absoluteDirectory);
        }
        catch
        {
            files = new string[0];
        }
        foreach (string file in files)
        {
            string name = Path.GetFileName(file);
            if (!name.EndsWith(".cs", StringComparison.Ordinal))
            {
                continue;
            }
            if (IsGeneratedName(name))
            {
                continue;
            }
            string relative = relativeDirectory.Length == 0 ? name : relativeDirectory + "/" + name;
            if (IsExcludedPath(relative))
            {
                continue;
            }
            results.Add(relative);
        }

        string[] directories;
        try
        {
            directories = Directory.GetDirectories(absoluteDirectory);
        }
        catch
        {
            directories = new string[0];
        }
        foreach (string directory in directories)
        {
            string name = Path.GetFileName(directory);
            if (Array.IndexOf(ExcludedSegments, name) >= 0)
            {
                continue;
            }
            try
            {
                FileAttributes attributes = File.GetAttributes(directory);
                if ((attributes & FileAttributes.ReparsePoint) != 0)
                {
                    continue;
                }
            }
            catch
            {
                continue;
            }
            string relative = relativeDirectory.Length == 0 ? name : relativeDirectory + "/" + name;
            WalkFiles(directory, relative, results);
        }
    }

    static List<string> AllSourceFiles()
    {
        List<string> results = new List<string>();
        WalkFiles(Root, "", results);
        results.Sort(StringComparer.Ordinal);
        return results;
    }

    static List<string> ProductionFiles()
    {
        List<string> production = new List<string>();
        foreach (string relative in AllSourceFiles())
        {
            if (!IsTestPath(relative))
            {
                production.Add(relative);
            }
        }
        return production;
    }

    // --------------------------------------------------------------------------
    // Finding emission
    // --------------------------------------------------------------------------
    static void Emit(string checkId, string path, int line, string message)
    {
        Console.WriteLine(checkId + " " + path + ":" + line + " " + Dash + " " + message);
        int count;
        CcCounts.TryGetValue(checkId, out count);
        CcCounts[checkId] = count + 1;
        if (checkId.StartsWith("CC-", StringComparison.Ordinal))
        {
            CcTotal++;
        }
    }

    static void EmitSkill(string checkId, string path, int line, string message)
    {
        Console.WriteLine(checkId + " " + path + ":" + line + " " + Dash + " " + message);
        SkFailures++;
    }

    static int CountOf(string checkId)
    {
        int count;
        return CcCounts.TryGetValue(checkId, out count) ? count : 0;
    }

    static void ResetCounters()
    {
        CcTotal = 0;
        CcCounts.Clear();
    }

    // --------------------------------------------------------------------------
    // Line sanitizer: blanks comments and string/char literals (same length)
    // --------------------------------------------------------------------------
    static string Sanitize(string line)
    {
        char[] characters = line.ToCharArray();
        int index = 0;
        while (index < characters.Length)
        {
            char current = characters[index];
            if (current == '/' && index + 1 < characters.Length && characters[index + 1] == '/')
            {
                for (int cursor = index; cursor < characters.Length; cursor++)
                {
                    characters[cursor] = ' ';
                }
                break;
            }
            if (current == '"')
            {
                bool verbatim = index > 0 && characters[index - 1] == '@';
                characters[index] = ' ';
                index++;
                while (index < characters.Length)
                {
                    if (verbatim)
                    {
                        if (characters[index] == '"')
                        {
                            if (index + 1 < characters.Length && characters[index + 1] == '"')
                            {
                                characters[index] = ' ';
                                characters[index + 1] = ' ';
                                index += 2;
                                continue;
                            }
                            characters[index] = ' ';
                            index++;
                            break;
                        }
                    }
                    else
                    {
                        if (characters[index] == '\\' && index + 1 < characters.Length)
                        {
                            characters[index] = ' ';
                            characters[index + 1] = ' ';
                            index += 2;
                            continue;
                        }
                        if (characters[index] == '"')
                        {
                            characters[index] = ' ';
                            index++;
                            break;
                        }
                    }
                    characters[index] = ' ';
                    index++;
                }
                continue;
            }
            if (current == '\'')
            {
                characters[index] = ' ';
                index++;
                while (index < characters.Length)
                {
                    if (characters[index] == '\\' && index + 1 < characters.Length)
                    {
                        characters[index] = ' ';
                        characters[index + 1] = ' ';
                        index += 2;
                        continue;
                    }
                    if (characters[index] == '\'')
                    {
                        characters[index] = ' ';
                        index++;
                        break;
                    }
                    characters[index] = ' ';
                    index++;
                }
                continue;
            }
            index++;
        }
        return new string(characters);
    }

    static bool IsCryptic(string name)
    {
        string lowered = name.ToLowerInvariant();
        foreach (string token in Cryptic)
        {
            if (token == lowered)
            {
                return true;
            }
        }
        return false;
    }

    static bool IsBlankOrComment(string line)
    {
        string trimmed = line.Trim();
        if (trimmed.Length == 0)
        {
            return true;
        }
        if (trimmed.StartsWith("//", StringComparison.Ordinal))
        {
            return true;
        }
        if (trimmed.StartsWith("/*", StringComparison.Ordinal))
        {
            return true;
        }
        if (trimmed.StartsWith("*", StringComparison.Ordinal))
        {
            return true;
        }
        return false;
    }

    static bool StartsWithClosingBrace(string line)
    {
        return line.TrimStart().StartsWith("}", StringComparison.Ordinal);
    }

    static bool StartsWithOpeningBrace(string line)
    {
        return line.TrimStart().StartsWith("{", StringComparison.Ordinal);
    }

    static bool MatchesAt(string text, int index, string needle)
    {
        if (index + needle.Length > text.Length)
        {
            return false;
        }
        return string.CompareOrdinal(text, index, needle, 0, needle.Length) == 0;
    }

    // --------------------------------------------------------------------------
    // CC-01 / CC-02 : identifier discipline
    // --------------------------------------------------------------------------
    static void CheckIdentifierDiscipline(string path, string[] lines)
    {
        for (int index = 0; index < lines.Length; index++)
        {
            string line = Sanitize(lines[index]);
            List<string> names = new List<string>();

            foreach (Match match in RxDeclaration.Matches(line))
            {
                names.Add(match.Groups[2].Value);
            }

            foreach (Match match in RxLambda.Matches(line))
            {
                string group = match.Groups[1].Value;
                if (group.StartsWith("(", StringComparison.Ordinal))
                {
                    string inner = group.Substring(1, group.Length - 2);
                    foreach (string rawPart in inner.Split(','))
                    {
                        string part = rawPart;
                        int equals = part.IndexOf('=');
                        if (equals >= 0)
                        {
                            part = part.Substring(0, equals);
                        }
                        Match nameMatch = RxLastIdentifier.Match(part.Trim());
                        if (nameMatch.Success)
                        {
                            names.Add(nameMatch.Groups[1].Value);
                        }
                    }
                }
                else
                {
                    names.Add(group);
                }
            }

            foreach (Match match in RxCatchBinding.Matches(line))
            {
                string inner = match.Groups[1].Value.Trim();
                if (inner.Length == 0)
                {
                    continue;
                }
                string[] parts = inner.Split(new char[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length < 2)
                {
                    continue;
                }
                Match nameMatch = RxIdentifierOnly.Match(parts[parts.Length - 1]);
                if (nameMatch.Success)
                {
                    names.Add(nameMatch.Groups[1].Value);
                }
            }

            HashSet<string> seen = new HashSet<string>();
            foreach (string name in names)
            {
                if (name.Length == 0 || !seen.Add(name))
                {
                    continue;
                }
                if (name.Length == 1)
                {
                    if (name == "_")
                    {
                        continue;
                    }
                    if ((name == "i" || name == "j") && line.IndexOf("for", StringComparison.Ordinal) >= 0)
                    {
                        continue;
                    }
                    Emit("CC-01", path, index + 1, "prohibited single-letter identifier \"" + name + "\"; use a descriptive name");
                }
                else if (IsCryptic(name))
                {
                    Emit("CC-02", path, index + 1, "prohibited cryptic abbreviation \"" + name + "\"; use the full identifier");
                }
            }
        }
    }

    // --------------------------------------------------------------------------
    // CC-03 : mutable lazy initialization
    // --------------------------------------------------------------------------
    static void CheckLazyInit(string path, string[] lines)
    {
        for (int index = 0; index < lines.Length; index++)
        {
            string line = Sanitize(lines[index]);
            if (line.IndexOf("??=", StringComparison.Ordinal) < 0)
            {
                continue;
            }
            string lowered = line.ToLowerInvariant();
            if (lowered.Contains("client") || lowered.Contains("instance") ||
                lowered.Contains("service") || lowered.Contains("provider"))
            {
                Emit("CC-03", path, index + 1, "prohibited mutable lazy initialization; inject the dependency via constructor");
            }
        }
    }

    // --------------------------------------------------------------------------
    // CC-04 : hardcoded placeholder / secret (blocking under every profile)
    // --------------------------------------------------------------------------
    static void CheckSecrets(string path, string[] lines)
    {
        for (int index = 0; index < lines.Length; index++)
        {
            if (RxSecret.IsMatch(lines[index]))
            {
                Emit("CC-04", path, index + 1, "prohibited hardcoded placeholder/secret; source it from configuration/environment");
            }
        }
    }

    // --------------------------------------------------------------------------
    // CC-05 : raw print / debug output
    // --------------------------------------------------------------------------
    static void CheckRawPrints(string path, string[] lines)
    {
        for (int index = 0; index < lines.Length; index++)
        {
            if (RxPrint.IsMatch(Sanitize(lines[index])))
            {
                Emit("CC-05", path, index + 1, "prohibited raw print/debug output in production code; use the logging interface");
            }
        }
    }

    // --------------------------------------------------------------------------
    // CC-06 : silent exception swallowing
    // --------------------------------------------------------------------------
    static void CheckSilentCatches(string path, string[] lines)
    {
        for (int index = 0; index < lines.Length; index++)
        {
            // The handler header is matched on the sanitized line so that a comment or a
            // string literal mentioning "catch" is never reported (governance_checks.md 4.1).
            string line = Sanitize(lines[index]);
            if (line.IndexOf("catch", StringComparison.Ordinal) < 0)
            {
                continue;
            }

            if (RxCatchInlineEmpty.IsMatch(line))
            {
                Emit("CC-06", path, index + 1, "prohibited silent exception swallowing; log with error+stack trace or rethrow");
                continue;
            }

            if (RxCatchBlockOpen.IsMatch(line))
            {
                bool emptied = false;
                int cursor = index + 1;
                while (cursor < lines.Length)
                {
                    string upcoming = lines[cursor];
                    if (IsBlankOrComment(upcoming))
                    {
                        cursor++;
                        continue;
                    }
                    if (StartsWithClosingBrace(upcoming))
                    {
                        emptied = true;
                    }
                    break;
                }
                if (emptied)
                {
                    Emit("CC-06", path, index + 1, "prohibited silent exception swallowing; log with error+stack trace or rethrow");
                    continue;
                }
            }

            if (RxCatchHeaderOnly.IsMatch(line))
            {
                int cursor = index + 1;
                while (cursor < lines.Length && IsBlankOrComment(lines[cursor]))
                {
                    cursor++;
                }
                if (cursor < lines.Length && StartsWithOpeningBrace(lines[cursor]))
                {
                    int closer = cursor + 1;
                    while (closer < lines.Length && IsBlankOrComment(lines[closer]))
                    {
                        closer++;
                    }
                    if (closer < lines.Length && StartsWithClosingBrace(lines[closer]))
                    {
                        Emit("CC-06", path, index + 1, "prohibited silent exception swallowing; log with error+stack trace or rethrow");
                    }
                }
            }
        }
    }

    // --------------------------------------------------------------------------
    // CC-07 : service-locator confinement
    // --------------------------------------------------------------------------
    static void CheckServiceLocator(string path, string[] lines)
    {
        string name = FileName(path);
        if (name == "Program.cs" || name == "Startup.cs" ||
            name.IndexOf("CompositionRoot", StringComparison.Ordinal) >= 0)
        {
            return;
        }
        for (int index = 0; index < lines.Length; index++)
        {
            string line = Sanitize(lines[index]);
            foreach (string token in ServiceLocatorTokens)
            {
                if (line.IndexOf(token, StringComparison.Ordinal) >= 0)
                {
                    Emit("CC-07", path, index + 1, "prohibited service-locator resolution outside the composition root/presentation layer; inject via constructor");
                    break;
                }
            }
        }
    }

    // --------------------------------------------------------------------------
    // CC-08 : nullable collection parameters
    // --------------------------------------------------------------------------
    static void CheckNullableCollections(string path, string[] lines)
    {
        for (int index = 0; index < lines.Length; index++)
        {
            if (RxNullableCollection.IsMatch(Sanitize(lines[index])))
            {
                Emit("CC-08", path, index + 1, "prohibited nullable collection parameter; default to a constant empty collection");
            }
        }
    }

    // --------------------------------------------------------------------------
    // CC-09 : unimplemented placeholder
    // --------------------------------------------------------------------------
    static void CheckUnimplemented(string path, string[] lines)
    {
        for (int index = 0; index < lines.Length; index++)
        {
            if (RxUnimplemented.IsMatch(Sanitize(lines[index])))
            {
                Emit("CC-09", path, index + 1, "prohibited unimplemented placeholder in production contract; implement the contract (LSP)");
            }
        }
    }

    // --------------------------------------------------------------------------
    // CC-10 : concrete network-client instantiation (DIP)
    // --------------------------------------------------------------------------
    static void CheckConcreteClients(string path, string[] lines)
    {
        for (int index = 0; index < lines.Length; index++)
        {
            if (RxHttpClient.IsMatch(Sanitize(lines[index])))
            {
                Emit("CC-10", path, index + 1, "prohibited concrete network-client instantiation outside the composition root; depend on an abstraction (DIP)");
            }
        }
    }

    // --------------------------------------------------------------------------
    // CC-11 : avoidable allocation on a hot path (advisory; also scans tests)
    // --------------------------------------------------------------------------
    static void CheckAllocations(string path, string[] lines)
    {
        const string ToListToken = ".ToList()";
        List<bool> loopStack = new List<bool>();
        bool pendingLoopHeader = false;

        for (int index = 0; index < lines.Length; index++)
        {
            string line = Sanitize(lines[index]);
            if (line.Trim().Length == 0)
            {
                continue;
            }

            bool[] loopWordAt = new bool[line.Length];
            bool lineHasLoopWord = false;
            foreach (Match match in RxLoopKeyword.Matches(line))
            {
                lineHasLoopWord = true;
                for (int offset = match.Index; offset < match.Index + match.Length && offset < line.Length; offset++)
                {
                    loopWordAt[offset] = true;
                }
            }

            int depth = 0;
            int segmentStart = 0;
            bool loopSeenOnLine = false;
            bool emitted = false;

            for (int cursor = 0; cursor < line.Length; cursor++)
            {
                if (loopWordAt[cursor])
                {
                    loopSeenOnLine = true;
                }
                char current = line[cursor];
                if (current == '(' || current == '[')
                {
                    depth++;
                    continue;
                }
                if (current == ')' || current == ']')
                {
                    if (depth > 0)
                    {
                        depth--;
                    }
                    continue;
                }
                if (current == '{')
                {
                    string header = line.Substring(segmentStart, cursor - segmentStart);
                    bool isLoop = RxLoopKeyword.IsMatch(header) || (header.Trim().Length == 0 && pendingLoopHeader);
                    loopStack.Add(isLoop);
                    segmentStart = cursor + 1;
                    continue;
                }
                if (current == '}')
                {
                    if (loopStack.Count > 0)
                    {
                        loopStack.RemoveAt(loopStack.Count - 1);
                    }
                    segmentStart = cursor + 1;
                    continue;
                }
                if (current == ';')
                {
                    if (depth == 0)
                    {
                        segmentStart = cursor + 1;
                        loopSeenOnLine = false;
                    }
                    continue;
                }
                if (!emitted && MatchesAt(line, cursor, ToListToken))
                {
                    if (loopStack.Contains(true) || pendingLoopHeader || (loopSeenOnLine && depth == 0))
                    {
                        Emit("CC-11", path, index + 1, "[advisory] avoidable allocation on hot path; inspect without copying and return the original reference");
                        emitted = true;
                    }
                }
            }

            bool hasBrace = line.IndexOf('{') >= 0;
            if (hasBrace)
            {
                pendingLoopHeader = false;
            }
            else if (lineHasLoopWord)
            {
                pendingLoopHeader = !line.TrimEnd().EndsWith(";", StringComparison.Ordinal);
            }
            else if (pendingLoopHeader && line.TrimEnd().EndsWith(";", StringComparison.Ordinal))
            {
                pendingLoopHeader = false;
            }
        }
    }

    // --------------------------------------------------------------------------
    // The CC-* suite
    // --------------------------------------------------------------------------
    static void RunCleanCodeReport()
    {
        ResetCounters();
        foreach (string relative in AllSourceFiles())
        {
            string[] lines = ReadLines(relative);
            if (!IsTestPath(relative))
            {
                CheckIdentifierDiscipline(relative, lines);
                CheckLazyInit(relative, lines);
                CheckSecrets(relative, lines);
                CheckRawPrints(relative, lines);
                CheckSilentCatches(relative, lines);
                CheckServiceLocator(relative, lines);
                CheckNullableCollections(relative, lines);
                CheckUnimplemented(relative, lines);
                CheckConcreteClients(relative, lines);
            }
            CheckAllocations(relative, lines);
        }
    }

    static int BlockingTotal()
    {
        int total = 0;
        foreach (string checkId in CcIds)
        {
            int count = CountOf(checkId);
            if (count <= 0)
            {
                continue;
            }
            if (CcBlocking(checkId) && count > CcThreshold(checkId))
            {
                total += count;
            }
        }
        return total;
    }

    static int RunCleanCode(string[] args)
    {
        ResolveProfile(HasFlag(args, "--standard"));
        RunCleanCodeReport();
        string behavior = CcBlocking("CC-01") ? "blocking" : "advisory";
        Console.WriteLine("Clean Code: " + CcTotal + " violation(s) (" + Profile + " profile: " + behavior + ")");
        if (BlockingTotal() > 0)
        {
            return 1;
        }
        return 0;
    }

    // --------------------------------------------------------------------------
    // PT-01 : ponytail debt markers
    // --------------------------------------------------------------------------
    static void ScanDebtMarkers(List<string> files)
    {
        foreach (string relative in files)
        {
            string[] lines = ReadLines(relative);
            for (int index = 0; index < lines.Length; index++)
            {
                string line = lines[index];
                int position = line.IndexOf("ponytail:", StringComparison.Ordinal);
                if (position < 0)
                {
                    continue;
                }
                string prefix = line.Substring(0, position);
                if (prefix.IndexOf("//", StringComparison.Ordinal) < 0 &&
                    prefix.IndexOf("/*", StringComparison.Ordinal) < 0 &&
                    prefix.IndexOf("#", StringComparison.Ordinal) < 0 &&
                    prefix.IndexOf("--", StringComparison.Ordinal) < 0 &&
                    prefix.IndexOf("<!--", StringComparison.Ordinal) < 0)
                {
                    continue;
                }
                string reason = line.Substring(position + "ponytail:".Length).Trim();
                Console.WriteLine("PT-01 " + relative + ":" + (index + 1) + " " + Dash + " " + reason);
            }
        }
    }

    static int RunPonytailDebt()
    {
        ScanDebtMarkers(AllSourceFiles());
        return 0;
    }

    static readonly Regex RxNarrationComment = new Regex(@"^\s*//\s*(increment|decrement|set|assign|call|return|loop|iterate|initialize|create|check|store)\b");
    static readonly Regex RxSingleStatementDelegation = new Regex(@"=>\s*[A-Za-z_][A-Za-z0-9_.]*\([^)]*\)[;]?\s*$|^\s*\{\s*return\s+[A-Za-z_][A-Za-z0-9_.]*\([^)]*\);\s*\}\s*$");

    static int RunPonytailAudit()
    {
        ScanDebtMarkers(AllSourceFiles());
        foreach (string relative in ProductionFiles())
        {
            string[] lines = ReadLines(relative);
            for (int index = 0; index < lines.Length; index++)
            {
                if (RxNarrationComment.IsMatch(lines[index]))
                {
                    Console.WriteLine("[advisory] [DELETE] " + relative + ":" + (index + 1) + " " + Dash + " narration comment restates the next line");
                }
                if (RxSingleStatementDelegation.IsMatch(lines[index]))
                {
                    Console.WriteLine("[advisory] [SHRINK] " + relative + ":" + (index + 1) + " " + Dash + " single-statement delegation; verify a caller justifies the layer");
                }
            }
        }
        return 0;
    }

    // --------------------------------------------------------------------------
    // SK-01 .. SK-06 : skill activation invariants
    // --------------------------------------------------------------------------
    static string SkillDir(string skill)
    {
        return ".agents/skills/" + skill;
    }

    static string SkillFile(string skill)
    {
        return SkillDir(skill) + "/SKILL.md";
    }

    static string FrontmatterValue(string skill, string key)
    {
        string[] lines = ReadLines(SkillFile(skill));
        if (lines.Length == 0 || lines[0].Trim() != "---")
        {
            return "";
        }
        string value = "";
        bool collecting = false;
        for (int index = 1; index < lines.Length; index++)
        {
            string line = lines[index];
            if (line.Trim() == "---")
            {
                break;
            }
            Match match = RxFrontmatterKey.Match(line);
            if (match.Success)
            {
                if (match.Groups[1].Value == key)
                {
                    value = match.Groups[2].Value.Trim();
                    collecting = true;
                }
                else
                {
                    collecting = false;
                }
                continue;
            }
            if (!collecting)
            {
                continue;
            }
            if (line.StartsWith(" ", StringComparison.Ordinal) || line.StartsWith("\t", StringComparison.Ordinal))
            {
                string trimmed = line.Trim();
                if (RxBlockScalar.IsMatch(value) || value.Length == 0)
                {
                    value = trimmed;
                }
                else
                {
                    value = value + " " + trimmed;
                }
                continue;
            }
            collecting = false;
        }
        return value.TrimEnd();
    }

    static List<string> FrontmatterKeys(string skill)
    {
        List<string> keys = new List<string>();
        string[] lines = ReadLines(SkillFile(skill));
        if (lines.Length == 0 || lines[0].Trim() != "---")
        {
            return keys;
        }
        for (int index = 1; index < lines.Length; index++)
        {
            string line = lines[index];
            if (line.Trim() == "---")
            {
                break;
            }
            Match match = RxFrontmatterKey.Match(line);
            if (match.Success)
            {
                keys.Add(match.Groups[1].Value);
            }
        }
        return keys;
    }

    static bool BodyContains(string relativePath, string marker)
    {
        string[] lines = ReadLines(relativePath);
        foreach (string line in lines)
        {
            if (line.StartsWith(marker, StringComparison.Ordinal))
            {
                return true;
            }
        }
        return false;
    }

    static void AuditSkillsParity()
    {
        string agents = ReadText(AgentsFile);
        string readme = ReadText("README.md");
        foreach (string skill in Skills)
        {
            if (!Exists(SkillFile(skill)))
            {
                EmitSkill("SK-01", SkillDir(skill), 0, "skill \"" + skill + "\" is not listed in .agents/skills (parity required)");
                continue;
            }
            if (agents.Length > 0 && agents.IndexOf("`" + skill + "`", StringComparison.Ordinal) < 0)
            {
                EmitSkill("SK-01", AgentsFile, 0, "skill \"" + skill + "\" is not listed in AGENTS.md (parity required)");
            }
            if (readme.Length > 0 && readme.IndexOf(skill, StringComparison.Ordinal) < 0)
            {
                EmitSkill("SK-01", "README.md", 0, "skill \"" + skill + "\" is not listed in README.md (parity required)");
            }
        }
    }

    static void AuditSkillsFrontmatter()
    {
        const string message = "skill \"{0}\" frontmatter must declare \"Use when\", \"Triggers on:\" and \"Chains into:\" with >=150 characters and name==directory";
        foreach (string skill in Skills)
        {
            if (!Exists(SkillFile(skill)))
            {
                continue;
            }
            if (IsAdoption() && UserOwnedSkill(skill))
            {
                continue;
            }
            string description = FrontmatterValue(skill, "description");
            if (description.Length == 0 ||
                description.IndexOf("Use when", StringComparison.Ordinal) < 0 ||
                description.IndexOf("Triggers on:", StringComparison.Ordinal) < 0 ||
                description.IndexOf("Chains into:", StringComparison.Ordinal) < 0 ||
                description.Length < 150)
            {
                EmitSkill("SK-02", SkillFile(skill), 0, string.Format(message, skill));
                continue;
            }
            string declaredName = FrontmatterValue(skill, "name");
            if (declaredName != skill)
            {
                EmitSkill("SK-02", SkillFile(skill), 0, string.Format(message, skill));
                continue;
            }
            foreach (string key in FrontmatterKeys(skill))
            {
                if (key == "name" || key == "description" || key == "argument-hint" ||
                    key == "license" || key == "metadata")
                {
                    continue;
                }
                EmitSkill("SK-02", SkillFile(skill), 0, string.Format(message, skill));
            }
            if (!BodyContains(SkillFile(skill), "## Territory"))
            {
                EmitSkill("SK-02", SkillFile(skill), 0, string.Format(message, skill));
            }
        }
    }

    static void AuditEntrypointParity()
    {
        string llms = ReadText(LlmsFile);
        foreach (string skill in Skills)
        {
            if (llms.Length > 0 && llms.IndexOf(skill, StringComparison.Ordinal) < 0)
            {
                EmitSkill("SK-03", LlmsFile, 0, "skill \"" + skill + "\" is not listed in llms.txt");
            }
        }
        string[] entrypoints = new string[] { "README.md", "docs/INDEX.md", "docs/MANIFESTO.md" };
        foreach (string entry in entrypoints)
        {
            string text = ReadText(entry);
            if (text.Length == 0)
            {
                continue;
            }
            if (text.IndexOf("llms.txt", StringComparison.Ordinal) < 0)
            {
                EmitSkill("SK-03", entry, 0, "entrypoint " + entry + " does not reference llms.txt");
            }
        }
    }

    static List<KeyValuePair<string, string>> MatrixRows()
    {
        List<KeyValuePair<string, string>> rows = new List<KeyValuePair<string, string>>();
        string[] lines = ReadLines(AgentsFile);
        bool inside = false;
        foreach (string line in lines)
        {
            if (line.StartsWith("### 3.3", StringComparison.Ordinal))
            {
                inside = true;
                continue;
            }
            if (inside && line.StartsWith("#", StringComparison.Ordinal))
            {
                inside = false;
            }
            if (!inside || !line.StartsWith("|", StringComparison.Ordinal))
            {
                continue;
            }
            string[] cells = line.Split('|');
            if (cells.Length < 7)
            {
                continue;
            }
            string triggers = cells[3].Trim(' ', '\t');
            string primary = Regex.Replace(cells[4], "[`\\s]", "");
            if (primary.Length == 0 || primary == "PrimarySkill")
            {
                continue;
            }
            rows.Add(new KeyValuePair<string, string>(primary, triggers));
        }
        return rows;
    }

    static void AuditTriggerCoherence()
    {
        List<KeyValuePair<string, string>> rows = MatrixRows();
        foreach (string skill in Skills)
        {
            string triggers = null;
            foreach (KeyValuePair<string, string> row in rows)
            {
                if (row.Key == skill)
                {
                    triggers = row.Value;
                    break;
                }
            }
            if (triggers == null)
            {
                EmitSkill("SK-04", AgentsFile, 0, "skill \"" + skill + "\" has no dispatch-matrix row");
                continue;
            }
            if (IsAdoption() && UserOwnedSkill(skill))
            {
                continue;
            }
            string frontmatter = FrontmatterValue(skill, "description").ToLowerInvariant();
            string[] parts = triggers.Split('|');
            foreach (string rawPart in parts)
            {
                string trigger = rawPart;
                if (trigger.StartsWith("\"", StringComparison.Ordinal))
                {
                    trigger = trigger.Substring(1);
                }
                if (trigger.EndsWith("\"", StringComparison.Ordinal) && trigger.Length > 0)
                {
                    trigger = trigger.Substring(0, trigger.Length - 1);
                }
                trigger = trigger.ToLowerInvariant();
                if (trigger.Length == 0)
                {
                    continue;
                }
                if (frontmatter.IndexOf(trigger, StringComparison.Ordinal) < 0)
                {
                    EmitSkill("SK-04", AgentsFile, 0, "trigger \"" + trigger + "\" for skill \"" + skill + "\" is missing from its frontmatter \"Triggers on:\"");
                }
            }
        }
    }

    static bool MirrorPresent(string directory)
    {
        try
        {
            return Directory.Exists(Path.Combine(Root, directory)) || File.Exists(Path.Combine(Root, directory));
        }
        catch
        {
            return false;
        }
    }

    static string MirrorOf(string directory, string skill)
    {
        if (!MirrorPresent(directory))
        {
            return null;
        }
        string nested = directory + "/" + skill;
        if (Directory.Exists(Path.Combine(Root, nested)))
        {
            return nested + "/SKILL.md";
        }
        if (File.Exists(Path.Combine(Root, directory + "/" + skill + ".md")))
        {
            return directory + "/" + skill + ".md";
        }
        if (File.Exists(Path.Combine(Root, directory + "/" + skill + ".mdc")))
        {
            return directory + "/" + skill + ".mdc";
        }
        return null;
    }

    static bool SameBytes(string firstRelative, string secondRelative)
    {
        try
        {
            byte[] first = File.ReadAllBytes(Path.Combine(Root, firstRelative));
            byte[] second = File.ReadAllBytes(Path.Combine(Root, secondRelative));
            if (first.Length != second.Length)
            {
                return false;
            }
            for (int index = 0; index < first.Length; index++)
            {
                if (first[index] != second[index])
                {
                    return false;
                }
            }
            return true;
        }
        catch
        {
            return false;
        }
    }

    static void AuditMirrorParity()
    {
        foreach (string directory in MirrorDirs)
        {
            if (!MirrorPresent(directory))
            {
                continue;
            }
            foreach (string skill in Skills)
            {
                string canonical = SkillFile(skill);
                if (!Exists(canonical))
                {
                    continue;
                }
                string mirror = MirrorOf(directory, skill);
                if (mirror == null || !SameBytes(canonical, mirror))
                {
                    EmitSkill("SK-05", directory, 0, "harness mirror \"" + directory + "\" diverges from .agents/skills for skill \"" + skill + "\" (run: oaef skills sync-mirrors)");
                }
            }
        }
    }

    // --- routing (governance_checks.md section 7.1) ---------------------------
    static string[] TriggersFor(string skill)
    {
        switch (skill)
        {
            case "ponytail":
                return new string[] { "new", "refactor", "add", "simple", "minimal", "yagni", "dead code", "delete", "remove" };
            case "screen-builder":
                return new string[] { "screen", "page", "feature", "flow", "view" };
            case "component-author":
                return new string[] { "component", "widget", "button", "card", "modal" };
            case "ui-preview":
                return new string[] { "preview", "storybook", "isolated render" };
            case "responsive-layout":
                return new string[] { "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport" };
            case "fix-layout-issues":
                return new string[] { "overflow", "unbounded", "layout", "layout broken", "render error" };
            case "test-generator":
                return new string[] { "test", "coverage", "mock", "fixture" };
            case "collect-coverage":
                return new string[] { "coverage", "lcov", "jacoco", "cobertura", "branches" };
            case "run-static-analysis":
                return new string[] { "analyze", "lint", "typecheck", "warnings" };
            case "nullable-types":
                return new string[] { "null", "optional", "nil", "guard clause", "defensive" };
            case "architecture-audit":
                return new string[] { "architecture", "boundary", "coupling", "cycle" };
            case "conformance-audit":
                return new string[] { "conformance", "doctor", "parity", "frontmatter" };
            case "code-review":
                return new string[] { "review", "pr", "checklist", "pre-pr" };
            default:
                return new string[0];
        }
    }

    static string SkillMeta(string skill)
    {
        if (skill == "ponytail" || skill == "collect-coverage" ||
            skill == "run-static-analysis" || skill == "conformance-audit")
        {
            return Dash;
        }
        return "ponytail";
    }

    static List<string> CandidateForms(string token)
    {
        List<string> forms = new List<string>();
        forms.Add(token);
        if (token.EndsWith("ies", StringComparison.Ordinal))
        {
            forms.Add(token.Substring(0, token.Length - 3) + "y");
        }
        if (token.EndsWith("es", StringComparison.Ordinal))
        {
            forms.Add(token.Substring(0, token.Length - 2));
        }
        if (token.EndsWith("s", StringComparison.Ordinal))
        {
            forms.Add(token.Substring(0, token.Length - 1));
        }
        if (token.EndsWith("ing", StringComparison.Ordinal))
        {
            forms.Add(token.Substring(0, token.Length - 3));
        }
        if (token.EndsWith("ed", StringComparison.Ordinal))
        {
            forms.Add(token.Substring(0, token.Length - 2));
        }
        if (token.EndsWith("ion", StringComparison.Ordinal))
        {
            forms.Add(token.Substring(0, token.Length - 3));
        }
        return forms;
    }

    static int CommonPrefix(string left, string right)
    {
        int limit = left.Length < right.Length ? left.Length : right.Length;
        for (int position = 0; position < limit; position++)
        {
            if (left[position] != right[position])
            {
                return position;
            }
        }
        return limit;
    }

    static bool WordMatch(string token, string word)
    {
        if (word.Length == 0)
        {
            return false;
        }
        foreach (string candidate in CandidateForms(token))
        {
            if (candidate == word)
            {
                return true;
            }
            if (candidate.Length >= 4 && CommonPrefix(candidate, word) >= 4)
            {
                return true;
            }
        }
        return false;
    }

    static string RoutePrompt(string prompt)
    {
        string lowered = prompt.ToLowerInvariant();
        string[] tokens = Regex.Split(lowered, "[^a-z0-9-]+");
        const string territory = " features screens pages components shared ui core domain data infra test tests ";
        string best = "ponytail";
        int bestScore = 0;

        foreach (string skill in Skills)
        {
            int score = 0;
            foreach (string nameWord in skill.Split('-'))
            {
                foreach (string token in tokens)
                {
                    if (token.Length == 0)
                    {
                        continue;
                    }
                    if (WordMatch(token, nameWord))
                    {
                        score += 5;
                        break;
                    }
                }
            }
            foreach (string trigger in TriggersFor(skill))
            {
                if (trigger.Length == 0)
                {
                    continue;
                }
                int weight = trigger.Length;
                if (weight > 8)
                {
                    weight = 8;
                }
                if (trigger.IndexOf(' ') >= 0)
                {
                    if (lowered.IndexOf(trigger, StringComparison.Ordinal) >= 0)
                    {
                        score += 3 + weight;
                    }
                    continue;
                }
                foreach (string token in tokens)
                {
                    if (token.Length == 0)
                    {
                        continue;
                    }
                    if (WordMatch(token, trigger))
                    {
                        score += 3 + weight;
                        break;
                    }
                }
            }
            foreach (string token in tokens)
            {
                if (token.Length == 0)
                {
                    continue;
                }
                if (territory.IndexOf(" " + token + " ", StringComparison.Ordinal) >= 0)
                {
                    score += 1;
                }
            }
            if (score > bestScore)
            {
                bestScore = score;
                best = skill;
            }
        }
        if (bestScore == 0)
        {
            best = "ponytail";
        }
        return best;
    }

    static int RunSkillsRoute(string[] args)
    {
        string query = string.Join(" ", args);
        string primary = RoutePrompt(query);
        Console.WriteLine("Routing: \"" + query + "\"");
        Console.WriteLine("Primary skill: " + primary + " " + SkillDir(primary) + "/SKILL.md");
        Console.WriteLine("Meta-skill: " + SkillMeta(primary));
        Console.WriteLine("Recipes containing " + primary + ":");
        foreach (string recipe in Recipes)
        {
            if (recipe.IndexOf(primary, StringComparison.Ordinal) >= 0)
            {
                Console.WriteLine("  " + recipe);
            }
        }
        return 0;
    }

    static void RunSkillsSelftest()
    {
        foreach (string fixture in RoutingFixtures)
        {
            int separator = fixture.IndexOf('|');
            string prompt = fixture.Substring(0, separator);
            string expected = fixture.Substring(separator + 1);
            string got = RoutePrompt(prompt);
            if (got != expected)
            {
                EmitSkill("SK-06", AgentsFile, 0, "routing self-test failed: prompt \"" + prompt + "\" resolved to \"" + got + "\" but expected \"" + expected + "\"");
            }
        }
    }

    static int RunSkillsAudit(string[] args)
    {
        ResolveProfile(false);
        AuditSkillsParity();
        AuditSkillsFrontmatter();
        AuditEntrypointParity();
        AuditTriggerCoherence();
        AuditMirrorParity();
        if (HasFlag(args, "--selftest"))
        {
            RunSkillsSelftest();
        }
        Console.WriteLine("Skills: " + SkFailures + " finding(s)");
        if (SkFailures > 0)
        {
            return 1;
        }
        return 0;
    }

    static void CopyDirectory(string sourceRelative, string targetRelative)
    {
        string source = Path.Combine(Root, sourceRelative);
        string target = Path.Combine(Root, targetRelative);
        Directory.CreateDirectory(target);
        foreach (string file in Directory.GetFiles(source))
        {
            File.Copy(file, Path.Combine(target, Path.GetFileName(file)), true);
        }
        foreach (string directory in Directory.GetDirectories(source))
        {
            string name = Path.GetFileName(directory);
            CopyDirectory(sourceRelative + "/" + name, targetRelative + "/" + name);
        }
    }

    static int RunSkillsSyncMirrors(string[] args)
    {
        bool checkOnly = HasFlag(args, "--check");
        ResolveProfile(false);
        int repaired = 0;
        foreach (string directory in MirrorDirs)
        {
            if (!MirrorPresent(directory))
            {
                continue;
            }
            if (!Directory.Exists(Path.Combine(Root, directory)))
            {
                continue;
            }
            foreach (string skill in Skills)
            {
                string canonical = SkillFile(skill);
                if (!Exists(canonical))
                {
                    continue;
                }
                string entry = MirrorOf(directory, skill);
                if (entry != null)
                {
                    if (!checkOnly && !SameBytes(canonical, entry))
                    {
                        try
                        {
                            File.Copy(Path.Combine(Root, canonical), Path.Combine(Root, entry), true);
                            Console.WriteLine(IconWrench + " " + directory + ": repaired mirror for " + skill + " (canonical catalog is authoritative)");
                            repaired++;
                        }
                        catch
                        {
                            // A user-owned entry that cannot be repaired is reported by SK-05.
                        }
                    }
                    continue;
                }
                if (checkOnly)
                {
                    continue;
                }
                string target = directory + "/" + skill;
                string linkTarget = Path.GetRelativePath(directory, SkillDir(skill)).Replace('\\', '/');
                bool created = false;
                try
                {
                    string absoluteTarget = Path.Combine(Root, target);
                    if (Directory.Exists(absoluteTarget) || File.Exists(absoluteTarget))
                    {
                        Directory.Delete(absoluteTarget, true);
                    }
                    Directory.CreateSymbolicLink(absoluteTarget, linkTarget);
                    created = Directory.Exists(absoluteTarget);
                }
                catch
                {
                    created = false;
                }
                if (created)
                {
                    Console.WriteLine(IconWrench + " " + directory + ": created mirror link for " + skill);
                }
                else
                {
                    try
                    {
                        string absoluteTarget = Path.Combine(Root, target);
                        if (Directory.Exists(absoluteTarget))
                        {
                            Directory.Delete(absoluteTarget, true);
                        }
                        else if (File.Exists(absoluteTarget))
                        {
                            File.Delete(absoluteTarget);
                        }
                        CopyDirectory(SkillDir(skill), target);
                        Console.WriteLine(IconWrench + " " + directory + ": created mirror copy for " + skill);
                    }
                    catch
                    {
                        continue;
                    }
                }
                repaired++;
            }
        }

        SkFailures = 0;
        AuditMirrorParity();
        if (checkOnly)
        {
            if (SkFailures > 0)
            {
                Console.WriteLine("Mirrors: " + SkFailures + " divergence(s) detected");
                return 1;
            }
            Console.WriteLine("Mirrors: parity verified");
            return 0;
        }
        if (SkFailures > 0)
        {
            Console.WriteLine("Mirrors: " + SkFailures + " divergence(s) remain (user-owned entries are preserved)");
            return 1;
        }
        Console.WriteLine("Mirrors: " + repaired + " entry(ies) synchronized, parity verified");
        return 0;
    }

    // --------------------------------------------------------------------------
    // lint / doctor / quality gate / sync / metrics
    // --------------------------------------------------------------------------
    static string NormalizeMirrorText(string text)
    {
        string[] lines = text.Split('\n');
        string joined = "";
        foreach (string line in lines)
        {
            if (line.StartsWith("<!--", StringComparison.Ordinal))
            {
                continue;
            }
            joined = joined + line;
        }
        return Regex.Replace(joined, "\\s+", "");
    }

    static int RunLint()
    {
        ResolveProfile(false);
        Console.WriteLine(IconSearch + " Executing OAEF Integrity & Secret Audits...");
        bool failed = false;

        if (Exists(AgentsFile) && Exists(ClaudeFile))
        {
            if (NormalizeMirrorText(ReadText(AgentsFile)) != NormalizeMirrorText(ReadText(ClaudeFile)))
            {
                Console.Error.WriteLine(IconCross + " [LINT] CLAUDE.md diverged from AGENTS.md. Run \"oaef sync\".");
                failed = true;
            }
        }

        List<string> documentation = new List<string>();
        CollectTree("docs", documentation);
        foreach (string candidate in documentation)
        {
            if (RxSecretPattern.IsMatch(ReadText(candidate)))
            {
                Console.Error.WriteLine(IconAlert + " [SECURITY] Potential secret detected in " + candidate + "!");
                failed = true;
            }
        }

        foreach (string relative in ProductionFiles())
        {
            string text = ReadText(relative);
            if (text.IndexOf("auto-generated", StringComparison.OrdinalIgnoreCase) >= 0 ||
                text.IndexOf("Generated by", StringComparison.Ordinal) >= 0 ||
                text.IndexOf("Code generated", StringComparison.Ordinal) >= 0)
            {
                continue;
            }
            string[] lines = ReadLines(relative);
            for (int index = 0; index < lines.Length; index++)
            {
                string line = lines[index];
                if (!RxSuppression.IsMatch(line))
                {
                    continue;
                }
                bool allowed = false;
                foreach (string token in SuppressionAllowlist)
                {
                    if (line.IndexOf(token, StringComparison.Ordinal) >= 0)
                    {
                        allowed = true;
                        break;
                    }
                }
                if (allowed)
                {
                    continue;
                }
                Console.Error.WriteLine(IconAlert + " [LINT] Unallowed suppression in " + relative + ":" + (index + 1) + ": " + line.Trim());
                failed = true;
            }
        }

        RunCleanCodeReport();
        AuditSkillsParity();
        AuditSkillsFrontmatter();
        AuditEntrypointParity();
        AuditTriggerCoherence();
        AuditMirrorParity();
        RunSkillsSelftest();
        if (SkFailures > 0)
        {
            failed = true;
        }

        if (failed)
        {
            Console.Error.WriteLine(IconCross + " LINT FAILED.");
            return 1;
        }
        Console.WriteLine(IconCheck + " [LINT] All integrity and secret audits passed cleanly.");
        return 0;
    }

    static void CollectTree(string relativeDirectory, List<string> results)
    {
        string absolute = Path.Combine(Root, relativeDirectory);
        string[] files;
        try
        {
            files = Directory.GetFiles(absolute);
        }
        catch
        {
            return;
        }
        foreach (string file in files)
        {
            string name = Path.GetFileName(file);
            results.Add(relativeDirectory + "/" + name);
        }
        string[] directories;
        try
        {
            directories = Directory.GetDirectories(absolute);
        }
        catch
        {
            return;
        }
        foreach (string directory in directories)
        {
            string name = Path.GetFileName(directory);
            CollectTree(relativeDirectory + "/" + name, results);
        }
    }

    static int RunConform()
    {
        ResolveProfile(false);
        Console.WriteLine(IconStethoscope + " OAEF Conformance Audit (doctor)...");
        int checks = 0;
        int passed = 0;
        bool failed = false;

        void Check(bool condition, string label)
        {
            checks++;
            if (condition)
            {
                passed++;
                Console.WriteLine(IconCheck + " " + label);
            }
            else
            {
                Console.Error.WriteLine(IconCross + " " + label);
                failed = true;
            }
        }

        foreach (string entry in RequiredFiles)
        {
            Check(Exists(entry), entry + " present");
        }
        foreach (string skill in Skills)
        {
            Check(Exists(SkillFile(skill)), SkillFile(skill) + " present");
        }
        bool runtimePresent = false;
        foreach (string candidate in EngineFiles)
        {
            if (Exists(candidate))
            {
                runtimePresent = true;
                break;
            }
        }
        Check(runtimePresent, "governance runtime present in tool/");

        if (Exists(AgentsFile) && Exists(ClaudeFile))
        {
            Check(NormalizeMirrorText(ReadText(AgentsFile)) == NormalizeMirrorText(ReadText(ClaudeFile)), "CLAUDE.md mirror parity verified");
        }
        else
        {
            Check(false, "mirror parity not verifiable (missing AGENTS.md or CLAUDE.md)");
        }

        bool placeholderHits = false;
        foreach (string candidate in new string[] { AgentsFile, LlmsFile })
        {
            string text = ReadText(candidate);
            if (text.IndexOf("{{PROJECT_NAME}}", StringComparison.Ordinal) >= 0 ||
                text.IndexOf("{{TECH_STACK}}", StringComparison.Ordinal) >= 0 ||
                text.IndexOf("{{STACK_SPECIFIC_RULES}}", StringComparison.Ordinal) >= 0)
            {
                placeholderHits = true;
            }
        }
        Check(!placeholderHits, "no unresolved template placeholders");

        SkFailures = 0;
        AuditMirrorParity();
        Check(SkFailures == 0, "harness skill mirror parity verified");

        SkFailures = 0;
        RunSkillsSelftest();
        Check(SkFailures == 0, "routing self-test (SK-06) passed");

        Console.WriteLine("");
        Console.WriteLine(IconChart + " Conformance: " + passed + "/" + checks + " checks passed");
        return failed ? 1 : 0;
    }

    static bool RunProcess(string fileName, string arguments)
    {
        try
        {
            ProcessStartInfo info = new ProcessStartInfo(fileName, arguments);
            info.WorkingDirectory = Root;
            info.UseShellExecute = false;
            Process child = Process.Start(info);
            if (child == null)
            {
                return false;
            }
            child.WaitForExit();
            return child.ExitCode == 0;
        }
        catch
        {
            return false;
        }
    }

    static void FindCoverageFiles(string absoluteDirectory, List<string> results, int depth)
    {
        if (depth > 6)
        {
            return;
        }
        string[] files;
        try
        {
            files = Directory.GetFiles(absoluteDirectory);
        }
        catch
        {
            files = new string[0];
        }
        foreach (string file in files)
        {
            if (string.Equals(Path.GetFileName(file), "coverage.cobertura.xml", StringComparison.Ordinal))
            {
                results.Add(file);
            }
        }
        string[] directories;
        try
        {
            directories = Directory.GetDirectories(absoluteDirectory);
        }
        catch
        {
            directories = new string[0];
        }
        foreach (string directory in directories)
        {
            string name = Path.GetFileName(directory);
            if (Array.IndexOf(ExcludedSegments, name) >= 0)
            {
                continue;
            }
            try
            {
                FileAttributes attributes = File.GetAttributes(directory);
                if ((attributes & FileAttributes.ReparsePoint) != 0)
                {
                    continue;
                }
            }
            catch
            {
                continue;
            }
            FindCoverageFiles(directory, results, depth + 1);
        }
    }

    static double ReadCoverage()
    {
        List<string> candidates = new List<string>();
        FindCoverageFiles(Root, candidates, 0);
        candidates.Sort(StringComparer.Ordinal);
        foreach (string candidate in candidates)
        {
            try
            {
                string text = File.ReadAllText(candidate);
                Match match = RxCoverageRate.Match(text);
                if (!match.Success)
                {
                    continue;
                }
                double rate;
                if (double.TryParse(match.Groups[1].Value, NumberStyles.Float, CultureInfo.InvariantCulture, out rate))
                {
                    return rate * 100.0;
                }
            }
            catch
            {
                // A missing or unreadable report is treated as a clean tree.
            }
        }
        return 100.0;
    }

    static void RatchetCoverage(double coverage)
    {
        try
        {
            string path = Path.Combine(Root, BaselineFile);
            string text = File.ReadAllText(path);
            string formatted = coverage.ToString("0.0", CultureInfo.InvariantCulture);
            string updated = Regex.Replace(text, "(\"lines_min_percentage\"\\s*:\\s*)[0-9][0-9.]*", "${1}" + formatted);
            File.WriteAllText(path, updated);
            Console.WriteLine(IconLock + " Monotonic Ratchet: Updated baseline floor to " + formatted + "%");
        }
        catch
        {
            // A non-writable baseline never fails the gate.
        }
    }

    static int RunQualityGate(string[] args)
    {
        ResolveProfile(false);
        Console.WriteLine(IconSearch + " Initiating OAEF Quality Gate Audit (C# / .NET)...");
        double minimumCoverage = BaselineNumber("coverage", "lines_min_percentage", 95.0);
        int maxFileLines = (int)BaselineNumber("clean_sizing", "file_max_lines", 300.0);

        Console.WriteLine(IconInfo + "  Running dotnet test with coverage...");
        if (!RunProcess("dotnet", "test --collect:\"XPlat Code Coverage\""))
        {
            Console.Error.WriteLine(IconCross + " Tests failed.");
            return 1;
        }

        double coverage = ReadCoverage();
        Console.WriteLine(IconChart + " Line Coverage: " + coverage.ToString("0.0", CultureInfo.InvariantCulture) +
                          "% (Floor: " + minimumCoverage.ToString(CultureInfo.InvariantCulture) + "%)");

        int oversized = 0;
        foreach (string relative in ProductionFiles())
        {
            int lineCount = ReadLines(relative).Length;
            if (lineCount > maxFileLines)
            {
                oversized++;
                Console.Error.WriteLine(IconWarning + "  Oversized file (" + lineCount + "L > " + maxFileLines + "L): " + relative);
            }
        }

        if (coverage < minimumCoverage || oversized > 0)
        {
            Console.Error.WriteLine(IconCross + " Quality Gates Failed.");
            return 1;
        }

        RunCleanCodeReport();
        string behavior = CcBlocking("CC-01") ? "blocking" : "advisory";
        Console.WriteLine("Clean Code: " + CcTotal + " violation(s) (" + Profile + " profile: " + behavior + ")");
        if (Profile == "strict" && !IsAdoption() && BlockingTotal() > 0)
        {
            Console.Error.WriteLine(IconCross + " Quality Gate Failed: " + CcTotal + " clean-code violation(s).");
            return 1;
        }

        Console.WriteLine(IconParty + " Quality Gates PASSED!");
        if ((HasFlag(args, "--record") || HasFlag(args, "--ratchet")) && coverage > minimumCoverage)
        {
            RatchetCoverage(coverage);
        }
        return 0;
    }

    static int RunMetrics()
    {
        string text = ReadText(BaselineFile);
        if (text.Length > 0)
        {
            Console.Out.Write(text);
        }
        return 0;
    }

    static int RunSync()
    {
        if (!Exists(AgentsFile))
        {
            return 0;
        }
        string content = ReadText(AgentsFile);
        string banner = "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n" +
                        "<!-- To modify rules, edit AGENTS.md and run \"oaef sync\". -->\n\n";
        try
        {
            File.WriteAllText(Path.Combine(Root, ClaudeFile), banner + content);
        }
        catch
        {
            Console.Error.WriteLine(IconCross + " Unable to write CLAUDE.md.");
            return 1;
        }
        Console.WriteLine(IconCheck + " Synchronized AGENTS.md -> CLAUDE.md");
        return 0;
    }
}
