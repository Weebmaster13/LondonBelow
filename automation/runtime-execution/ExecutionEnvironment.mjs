import { git, readJson, runCommand } from "../repository-state.mjs";

const config = readJson("automation/config/automation-config.json");

function cleanStatus(statusText) {
  return statusText
    .split(/\r?\n/)
    .filter((line) => line.trim() && !line.startsWith("##")).length === 0;
}

export function collectExecutionEnvironment(cwd = process.cwd()) {
  const branch = git(config, ["branch", "--show-current"], { cwd });
  const head = git(config, ["rev-parse", "HEAD"], { cwd });
  const remote = git(config, ["rev-parse", `origin/${config.branch ?? "main"}`], { cwd });
  const status = git(config, ["status", "--short", "--branch"], { cwd });
  const node = runCommand("node", ["--version"], { cwd });
  const npm = runCommand("npm", ["--version"], { cwd });

  return {
    repository: "LondonBelow",
    branch: branch.stdout.trim(),
    localHead: head.stdout.trim(),
    remoteHead: remote.stdout.trim(),
    workingTreeClean: status.ok && cleanStatus(status.stdout),
    originSynchronized: head.stdout.trim() === remote.stdout.trim(),
    tools: [
      {
        name: "node",
        command: "node --version",
        exitCode: node.exitCode,
        status: node.ok ? "available" : "unavailable",
        output: (node.stdout || node.stderr || node.error || "").trim()
      },
      {
        name: "npm",
        command: "npm --version",
        exitCode: npm.exitCode,
        status: npm.ok ? "available" : "unavailable",
        output: (npm.stdout || npm.stderr || npm.error || "").trim()
      }
    ]
  };
}
