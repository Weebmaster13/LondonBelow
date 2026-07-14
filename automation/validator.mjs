import { existsSync, rmSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { buildToolEnv, listFiles, readJson, runCommand } from "./repository-state.mjs";

export function removeArtifacts(artifacts, cwd = process.cwd()) {
  for (const artifact of artifacts ?? []) {
    const path = join(cwd, artifact);
    if (existsSync(path)) {
      rmSync(path, { force: true });
    }
  }
}

export function runValidation(config, validationConfig, cwd = process.cwd()) {
  const env = buildToolEnv(config);
  const results = [];
  for (const item of validationConfig.commands ?? []) {
    const command = item.useConfiguredGit ? config.gitExecutable ?? "git" : item.command;
    results.push({
      name: item.name,
      ...runCommand(command, item.args ?? [], { cwd, env, maxBuffer: 1024 * 1024 * 50 })
    });
  }
  return results;
}

export function runForbiddenScan(scanConfig, cwd = process.cwd()) {
  const ignored = new Set(scanConfig.ignoredPaths ?? []);
  const roots = scanConfig.defaultScanRoots ?? ["src"];
  const patterns = scanConfig.patterns ?? [];
  const files = roots.flatMap((root) =>
    listFiles(join(cwd, root), (path) => /\.(lua|luau|js|mjs|json|md)$/i.test(path))
  );
  const matches = [];
  for (const file of files) {
    const relativePath = file.slice(cwd.length + 1).replaceAll("\\", "/");
    if ([...ignored].some((prefix) => relativePath.startsWith(prefix))) {
      continue;
    }
    const text = readFileSync(file, "utf8");
    for (const pattern of patterns) {
      const index = text.toLowerCase().indexOf(pattern.toLowerCase());
      if (index >= 0) {
        matches.push({ file: relativePath, pattern });
      }
    }
  }
  return { ok: matches.length === 0, matches };
}

export function writeValidationLog(path, validationResults, scanResult) {
  const lines = [];
  for (const result of validationResults) {
    lines.push(`## ${result.name}`);
    lines.push(`status=${result.status}`);
    if (result.stdout) lines.push(result.stdout.trim());
    if (result.stderr) lines.push(result.stderr.trim());
    if (result.error) lines.push(result.error);
    lines.push("");
  }
  lines.push("## forbidden scan");
  lines.push(JSON.stringify(scanResult, null, 2));
  writeFileSync(path, `${lines.join("\n")}\n`);
}

export function loadValidationConfig() {
  return readJson("automation/config/validation-config.json");
}

export function loadForbiddenConfig() {
  return readJson("automation/config/forbidden-surfaces.json");
}
