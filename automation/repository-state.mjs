import { spawnSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";

export function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

export function expandPathToken(value) {
  return value.replaceAll("%TEMP%", process.env.TEMP ?? process.env.TMP ?? "");
}

export function buildToolEnv(config) {
  const prefixes = (config.validationToolPathPrefixes ?? []).map(expandPathToken);
  return {
    ...process.env,
    PATH: [...prefixes, process.env.PATH ?? ""].filter(Boolean).join(";")
  };
}

export function runCommand(command, args = [], options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? process.cwd(),
    env: options.env ?? process.env,
    encoding: "utf8",
    shell: options.shell ?? process.platform === "win32",
    input: options.input,
    maxBuffer: options.maxBuffer ?? 1024 * 1024 * 20
  });
  return {
    command,
    args,
    status: result.status ?? 1,
    ok: result.status === 0,
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
    error: result.error ? String(result.error.message ?? result.error) : null
  };
}

export function git(config, args, options = {}) {
  return runCommand(config.gitExecutable ?? "git", args, options);
}

export function listFiles(root, predicate = () => true) {
  const output = [];
  function visit(dir) {
    if (!existsSync(dir)) {
      return;
    }
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const path = join(dir, entry.name);
      if (entry.isDirectory()) {
        if (entry.name === ".git" || entry.name === "node_modules") {
          continue;
        }
        visit(path);
      } else if (predicate(path)) {
        output.push(path);
      }
    }
  }
  visit(root);
  return output;
}

export function inspectRepository(config, cwd = process.cwd()) {
  const branch = git(config, ["branch", "--show-current"], { cwd });
  const head = git(config, ["rev-parse", "HEAD"], { cwd });
  const remote = git(config, ["rev-parse", `origin/${config.branch ?? "main"}`], { cwd });
  const status = git(config, ["status", "--short", "--branch"], { cwd });
  const log = git(config, ["log", "--oneline", "--decorate", "-n", "25"], { cwd });
  return {
    branch: branch.stdout.trim(),
    localHead: head.stdout.trim(),
    remoteHead: remote.stdout.trim(),
    statusText: status.stdout.trim(),
    recentLog: log.stdout.trim(),
    workingTreeClean: status.stdout
      .split(/\r?\n/)
      .filter((line) => line.trim() && !line.startsWith("##")).length === 0,
    commandResults: { branch, head, remote, status, log }
  };
}

export function verifyRequiredFiles(paths, cwd = process.cwd()) {
  return paths.map((path) => ({
    path,
    exists: existsSync(join(cwd, path))
  }));
}

export function checkTool(name, command, args, options = {}) {
  const result = runCommand(command, args, options);
  return {
    name,
    command,
    ok: result.ok,
    output: (result.stdout || result.stderr || result.error || "").trim()
  };
}

export function getChangedFiles(config, fromCommit, toCommit = "HEAD", cwd = process.cwd()) {
  const result = git(config, ["diff", "--name-only", `${fromCommit}..${toCommit}`], { cwd });
  return result.ok ? result.stdout.split(/\r?\n/).filter(Boolean) : [];
}

export function fileSize(path) {
  return existsSync(path) ? statSync(path).size : 0;
}

export function rel(cwd, path) {
  return relative(cwd, path).replaceAll("\\", "/");
}
