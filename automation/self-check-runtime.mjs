import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { readJson, runCommand } from "./repository-state.mjs";

const cwd = process.cwd();
const config = readJson("automation/config/automation-config.json");
const phase109Harness = "automation/local-state/phase109-selfchecks.luau";
const reportPath = "automation/local-state/phase109-selfcheck-runtime-report.md";

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
      args: [phase109Harness],
      commandLine: `${bundledLuau} ${phase109Harness}`
    };
  }

  const localLune = commandExists(config.selfCheckRuntime?.luneExecutable ?? "lune");
  if (localLune !== null) {
    return {
      kind: "local Lune runtime",
      executable: localLune,
      args: ["run", phase109Harness],
      commandLine: `${localLune} run ${phase109Harness}`
    };
  }

  const robloxCli = commandExists(config.selfCheckRuntime?.robloxCliExecutable ?? "roblox-cli");
  if (robloxCli !== null) {
    return {
      kind: "Roblox CLI",
      executable: robloxCli,
      args: ["run", phase109Harness],
      commandLine: `${robloxCli} run ${phase109Harness}`
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
  mkdirSync(dirname(reportPath), { recursive: true });
  const commandLines =
    report.commands.length === 0
      ? "- None"
      : report.commands.map((command) => `- \`${command}\``).join("\n");

  writeFileSync(
    reportPath,
    `# Phase 109 Self-Check Runtime Report

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

  if (!existsSync(phase109Harness)) {
    const report = {
      status: "Runtime unavailable",
      runtimeDetected: runtime.kind,
      commands: [],
      total: null,
      failures: null,
      notes: [`Harness not found: ${phase109Harness}`, "Self-check execution skipped truthfully."]
    };
    writeReport(report);
    console.log("Runtime unavailable");
    console.log(`Runtime detected: ${runtime.kind}`);
    console.log(`Report: ${normalize(reportPath)}`);
    process.exitCode = 1;
    return;
  }

  if (runtime.kind === "none") {
    const report = {
      status: "Runtime unavailable - Roblox Studio required",
      runtimeDetected: "none",
      commands: [],
      total: null,
      failures: null,
      notes: [
        "No local bundled Luau runtime, local Lune runtime, or Roblox CLI was detected.",
        "Phase 109 modules use Roblox APIs; Roblox Studio is the authoritative runtime for this self-check suite.",
        "Run ServerScriptService.Chapter0Home.Studio.Phase109SelfCheckRunner manually in Studio with the explicit Workspace flag.",
        "Self-check execution skipped truthfully.",
        "Phase 109 certification remains incomplete."
      ]
    };
    writeReport(report);
    console.log("Runtime unavailable");
    console.log("Roblox Studio required");
    console.log("Runtime detected: none");
    console.log("Commands executed: none");
    console.log("Totals: not executed");
    console.log("Failures: not executed");
    console.log(`Report: ${normalize(reportPath)}`);
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
  console.log(`Report: ${normalize(reportPath)}`);

  if (!result.ok || totals.failures !== 0) {
    process.exitCode = 1;
  }
}

main();
