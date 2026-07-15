import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { readJson, runCommand } from "./repository-state.mjs";

const cwd = process.cwd();
const config = readJson("automation/config/automation-config.json");
const phaseArg = process.argv.find((arg) => arg.startsWith("--phase="));
const phase = phaseArg?.split("=")[1] ?? "109";
const phaseConfig = {
  "109": {
    harness: "automation/local-state/phase109-selfchecks.luau",
    reportPath: "automation/local-state/phase109-selfcheck-runtime-report.md",
    studioRunner: "ServerScriptService.Chapter0Home.Studio.Phase109SelfCheckRunner",
    studioFlag: "LondonPhase109RunSelfChecks",
    certificationPhaseLabel: "Phase 109"
  },
  "110": {
    harness: "automation/local-state/phase110-selfchecks.luau",
    reportPath: "automation/local-state/phase110-selfcheck-runtime-report.md",
    studioRunner: "ServerScriptService.Chapter0Home.Studio.Phase110CertificationRunner",
    studioFlag: "LondonPhase110RunSelfChecks",
    certificationPhaseLabel: "Phase 110"
  }
}[phase];

if (phaseConfig === undefined) {
  console.error(`Unsupported self-check phase: ${phase}`);
  process.exit(1);
}

function executableName(base) {
  return process.platform === "win32" ? `${base}.exe` : base;
}

function normalize(path) {
  return path.replaceAll("\\", "/");
}

function commandExists(command) {
  const probe =
    process.platform === "win32"
      ? runCommand("where", [command], { cwd })
      : runCommand("command", ["-v", command], { cwd, shell: true });
  return probe.ok ? probe.stdout.split(/\r?\n/).find(Boolean)?.trim() ?? command : null;
}

function existingPath(paths) {
  for (const path of paths) {
    if (existsSync(path)) {
      return path;
    }
  }

  return null;
}

function detectRuntime() {
  const bundledLuauPaths = [
    ...(config.selfCheckRuntime?.bundledLuauPaths ?? []),
    join("automation", "runtime", executableName("luau")),
    join("automation", "bin", executableName("luau")),
    join("tools", "luau", executableName("luau"))
  ];
  const bundledLuau = existingPath(bundledLuauPaths);

  if (bundledLuau !== null) {
    return {
      kind: "local bundled Luau runtime",
      executable: bundledLuau,
      args: [phaseConfig.harness],
      commandLine: `${bundledLuau} ${phaseConfig.harness}`
    };
  }

  const localLune = commandExists(config.selfCheckRuntime?.luneExecutable ?? "lune");
  if (localLune !== null) {
    return {
      kind: "local Lune runtime",
      executable: localLune,
      args: ["run", phaseConfig.harness],
      commandLine: `${localLune} run ${phaseConfig.harness}`
    };
  }

  const robloxCli = commandExists(config.selfCheckRuntime?.robloxCliExecutable ?? "roblox-cli");
  if (robloxCli !== null) {
    return {
      kind: "Roblox CLI",
      executable: robloxCli,
      args: ["run", phaseConfig.harness],
      commandLine: `${robloxCli} run ${phaseConfig.harness}`
    };
  }

  return {
    kind: "none",
    executable: null,
    args: [],
    commandLine: null
  };
}

function parseTotals(stdout) {
  const total = stdout.match(/^TOTAL\s+(\d+)/m);
  const failures = stdout.match(/^FAILURES\s+(\d+)/m);
  return {
    total: total ? Number(total[1]) : null,
    failures: failures ? Number(failures[1]) : null
  };
}

function writeReport(report) {
  mkdirSync(dirname(phaseConfig.reportPath), { recursive: true });
  const commandLines =
    report.commands.length === 0
      ? "- None"
      : report.commands.map((command) => `- \`${command}\``).join("\n");

  writeFileSync(
    phaseConfig.reportPath,
    `# ${phaseConfig.certificationPhaseLabel} Self-Check Runtime Report

Status: ${report.status}

Runtime detected: ${report.runtimeDetected}

Commands executed:

${commandLines}

Totals: ${report.total ?? "not executed"}

Failures: ${report.failures ?? "not executed"}

Certification complete: false

Notes:

${report.notes.map((note) => `- ${note}`).join("\n")}
`
  );
}

function main() {
  const runtime = detectRuntime();

  if (runtime.kind === "none") {
    const report = {
      status: "Runtime unavailable - Roblox Studio required",
      runtimeDetected: "none",
      commands: [],
      total: null,
      failures: null,
      notes: [
        "No local bundled Luau runtime, local Lune runtime, or Roblox CLI was detected.",
        `${phaseConfig.certificationPhaseLabel} modules use Roblox APIs; Roblox Studio is the authoritative runtime for this self-check suite.`,
        `Run ${phaseConfig.studioRunner} manually in Studio with Workspace attribute ${phaseConfig.studioFlag} = true.`,
        "Self-check execution skipped truthfully.",
        `${phaseConfig.certificationPhaseLabel} certification remains incomplete.`
      ]
    };
    writeReport(report);
    console.log("Runtime unavailable");
    console.log("Roblox Studio required");
    console.log("Runtime detected: none");
    console.log("Commands executed: none");
    console.log("Totals: not executed");
    console.log("Failures: not executed");
    console.log(`Report: ${normalize(phaseConfig.reportPath)}`);
    process.exitCode = 1;
    return;
  }

  if (!existsSync(phaseConfig.harness)) {
    const report = {
      status: "Runtime unavailable",
      runtimeDetected: runtime.kind,
      commands: [],
      total: null,
      failures: null,
      notes: [`Harness not found: ${phaseConfig.harness}`, "Self-check execution skipped truthfully."]
    };
    writeReport(report);
    console.log("Runtime unavailable");
    console.log(`Runtime detected: ${runtime.kind}`);
    console.log(`Report: ${normalize(phaseConfig.reportPath)}`);
    process.exitCode = 1;
    return;
  }

  const result = runCommand(runtime.executable, runtime.args, {
    cwd,
    maxBuffer: 1024 * 1024 * 20
  });
  const totals = parseTotals(result.stdout);
  const report = {
    status: result.ok && totals.failures === 0 ? "Self-checks passed" : "Self-checks failed",
    runtimeDetected: runtime.kind,
    commands: [runtime.commandLine],
    total: totals.total,
    failures: totals.failures,
    notes: [
      `Exit code: ${result.exitCode}`,
      `Duration: ${result.durationMs} ms`,
      result.stderr.trim() === "" ? "stderr empty" : `stderr: ${result.stderr.trim()}`
    ]
  };
  writeReport(report);
  process.stdout.write(result.stdout);
  process.stderr.write(result.stderr);
  console.log(`Runtime detected: ${runtime.kind}`);
  console.log(`Commands executed: ${runtime.commandLine}`);
  console.log(`Totals: ${totals.total ?? "not parsed"}`);
  console.log(`Failures: ${totals.failures ?? "not parsed"}`);
  console.log(`Report: ${normalize(phaseConfig.reportPath)}`);

  if (!result.ok || totals.failures !== 0) {
    process.exitCode = 1;
  }
}

main();
