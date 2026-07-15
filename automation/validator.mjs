import { existsSync, rmSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { buildToolEnv, listFiles, readJson, runCommand } from "./repository-state.mjs";

export function removeArtifacts(artifacts, cwd = process.cwd()) {
  const results = [];
  for (const artifact of artifacts ?? []) {
    const path = join(cwd, artifact);
    const result = {
      path: artifact,
      existed: existsSync(path),
      removed: false,
      ok: true,
      error: null
    };
    if (existsSync(path)) {
      try {
        rmSync(path, { force: true });
        result.removed = true;
      } catch (error) {
        result.ok = false;
        result.error = error instanceof Error ? error.message : String(error);
      }
    }
    results.push(result);
  }
  return results;
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

function normalizeRelativePath(path) {
  return path.replaceAll("\\", "/").replace(/^"|"$/g, "");
}

function getChangedFiles(scanConfig, cwd, options) {
  const roots = scanConfig.defaultScanRoots ?? ["src"];
  const gitCommand = options.config?.gitExecutable ?? "git";
  const rootArgs = roots.flatMap((root) => [root]);
  const commands = [];
  if (options.baseCommit) {
    commands.push(["diff", "--name-only", `${options.baseCommit}..HEAD`, "--", ...rootArgs]);
  }
  commands.push(["diff", "--name-only", "--cached", "--", ...rootArgs]);
  commands.push(["diff", "--name-only", "--", ...rootArgs]);
  commands.push(["ls-files", "--others", "--exclude-standard", "--", ...rootArgs]);

  const paths = new Set();
  for (const args of commands) {
    const result = runCommand(gitCommand, args, {
      cwd,
      env: options.env ?? process.env,
      maxBuffer: 1024 * 1024 * 20
    });
    if (!result.ok) {
      continue;
    }
    for (const line of result.stdout.split(/\r?\n/)) {
      const relativePath = normalizeRelativePath(line.trim());
      if (relativePath) {
        paths.add(relativePath);
      }
    }
  }
  return [...paths];
}

function lineWithoutStringLiterals(line) {
  let output = "";
  let quote = null;
  let escaped = false;
  for (let index = 0; index < line.length; index += 1) {
    const char = line[index];
    if (quote) {
      output += " ";
      if (escaped) {
        escaped = false;
      } else if (char === "\\") {
        escaped = true;
      } else if (char === quote) {
        quote = null;
      }
      continue;
    }
    if (char === "\"" || char === "'") {
      quote = char;
      output += " ";
      continue;
    }
    output += char;
  }
  return output;
}

function isServiceLikePattern(pattern) {
  return /^(RemoteEvent|RemoteFunction|BindableEvent|BindableFunction|DataStore|HttpService|MessagingService|ContentProvider|InsertService)$/i.test(
    pattern
  );
}

function findForbiddenMatches(text, pattern) {
  const matches = [];
  const loweredPattern = pattern.toLowerCase();
  const lines = text.split(/\r?\n/);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const executableLine = lineWithoutStringLiterals(line);
    const loweredExecutable = executableLine.toLowerCase();
    const loweredRaw = line.toLowerCase();
    if (loweredExecutable.includes(loweredPattern)) {
      matches.push({ line: index + 1, evidence: line.trim() });
      continue;
    }
    if (
      isServiceLikePattern(pattern) &&
      loweredRaw.includes(loweredPattern) &&
      /(GetService|Instance\.new|FindFirstChild|WaitForChild)/.test(executableLine)
    ) {
      matches.push({ line: index + 1, evidence: line.trim() });
    }
  }
  return matches;
}

function resolveScanFiles(scanConfig, cwd, options) {
  const ignored = new Set(scanConfig.ignoredPaths ?? []);
  const roots = scanConfig.defaultScanRoots ?? ["src"];
  const extensions = scanConfig.includeExtensions ?? [".lua", ".luau", ".js", ".mjs", ".json", ".md"];
  const changedOnly = scanConfig.scanChangedFilesOnly !== false;
  const relativeFiles = changedOnly ? getChangedFiles(scanConfig, cwd, options) : null;
  const files = relativeFiles
    ? relativeFiles.map((relativePath) => join(cwd, relativePath))
    : roots.flatMap((root) =>
        listFiles(join(cwd, root), (path) =>
          extensions.some((extension) => path.toLowerCase().endsWith(extension.toLowerCase()))
        )
      );
  return files.filter((file) => {
    const relativePath = file.slice(cwd.length + 1).replaceAll("\\", "/");
    if ([...ignored].some((prefix) => relativePath.startsWith(prefix))) {
      return false;
    }
    return extensions.some((extension) => file.toLowerCase().endsWith(extension.toLowerCase()));
  });
}

export function runForbiddenScan(scanConfig, cwd = process.cwd(), options = {}) {
  const patterns = scanConfig.patterns ?? [];
  const files = resolveScanFiles(scanConfig, cwd, options);
  const matches = [];
  for (const file of files) {
    const relativePath = file.slice(cwd.length + 1).replaceAll("\\", "/");
    const text = readFileSync(file, "utf8");
    for (const pattern of patterns) {
      for (const match of findForbiddenMatches(text, pattern)) {
        matches.push({ file: relativePath, pattern, line: match.line, evidence: match.evidence });
      }
    }
  }
  return {
    ok: matches.length === 0,
    scannedFiles: files.map((file) => file.slice(cwd.length + 1).replaceAll("\\", "/")),
    matches
  };
}

function commandStatus(result) {
  return result.ok ? "PASS" : "FAIL";
}

function firstFailure(validationResults, scanResult) {
  const failedCommand = validationResults.find((result) => !result.ok);
  if (failedCommand) {
    return {
      command: failedCommand.commandLine ?? [failedCommand.command, ...(failedCommand.args ?? [])].join(" "),
      output: [failedCommand.stdout, failedCommand.stderr, failedCommand.error].filter(Boolean).join("\n").trim(),
      kind: failedCommand.failureKind ?? "nonzero_exit"
    };
  }
  if (!scanResult.ok) {
    return {
      command: "forbidden API scan",
      output: JSON.stringify(scanResult.matches, null, 2),
      kind: "forbidden_scan_match"
    };
  }
  return null;
}

export function writeValidationLog(path, validationResults, scanResult, cleanupResults = []) {
  const lines = [];
  for (const result of validationResults) {
    lines.push(`## ${result.name}`);
    lines.push(`command=${result.commandLine ?? [result.command, ...(result.args ?? [])].join(" ")}`);
    lines.push(`exitCode=${result.exitCode ?? result.status}`);
    lines.push(`durationMs=${result.durationMs ?? "unknown"}`);
    lines.push(`status=${commandStatus(result)}`);
    lines.push(`failureKind=${result.failureKind ?? (result.ok ? "none" : "nonzero_exit")}`);
    lines.push("stdout:");
    if (result.stdout) lines.push(result.stdout.trim());
    lines.push("stderr:");
    if (result.stderr) lines.push(result.stderr.trim());
    lines.push("error:");
    if (result.error) lines.push(result.error);
    lines.push("");
  }
  lines.push("## forbidden scan");
  lines.push(JSON.stringify(scanResult, null, 2));
  lines.push("");
  lines.push("## artifact cleanup");
  lines.push(JSON.stringify(cleanupResults, null, 2));
  writeFileSync(path, `${lines.join("\n")}\n`);
}

export function writeValidationMarkdown(path, validationResults, scanResult, cleanupResults = []) {
  const failed = firstFailure(validationResults, scanResult);
  const cleanupOk = cleanupResults.every((result) => result.ok);
  const overallOk = validationResults.every((result) => result.ok) && scanResult.ok && cleanupOk;
  const lines = [
    `# Validation Report`,
    "",
    `Overall status: ${overallOk ? "PASS" : "FAIL"}`,
    "",
    "## Command Results",
    ""
  ];
  for (const result of validationResults) {
    lines.push(`### ${result.name}`);
    lines.push("");
    lines.push(`- Command: \`${result.commandLine ?? [result.command, ...(result.args ?? [])].join(" ")}\``);
    lines.push(`- Exit code: ${result.exitCode ?? result.status}`);
    lines.push(`- Duration: ${result.durationMs ?? "unknown"} ms`);
    lines.push(`- Status: ${commandStatus(result)}`);
    lines.push(`- Failure kind: ${result.failureKind ?? (result.ok ? "none" : "nonzero_exit")}`);
    lines.push("");
    lines.push("Stdout:");
    lines.push("```text");
    lines.push((result.stdout ?? "").trim() || "(empty)");
    lines.push("```");
    lines.push("");
    lines.push("Stderr:");
    lines.push("```text");
    lines.push((result.stderr ?? "").trim() || "(empty)");
    lines.push("```");
    lines.push("");
  }
  lines.push("## Forbidden API Scan");
  lines.push("");
  lines.push(`- Status: ${scanResult.ok ? "PASS" : "FAIL"}`);
  lines.push(`- Files scanned: ${scanResult.scannedFiles?.length ?? 0}`);
  lines.push(`- Matches: ${scanResult.matches?.length ?? 0}`);
  if (!scanResult.ok) {
    lines.push("");
    lines.push("Matches:");
    lines.push("```json");
    lines.push(JSON.stringify(scanResult.matches, null, 2));
    lines.push("```");
  }
  lines.push("");
  lines.push("## Exact Failing Command");
  lines.push("");
  if (failed) {
    lines.push(`- Command: \`${failed.command}\``);
    lines.push(`- Failure kind: ${failed.kind}`);
    lines.push("");
    lines.push("Failure output:");
    lines.push("```text");
    lines.push(failed.output || "(empty)");
    lines.push("```");
  } else {
    lines.push("- None");
  }
  lines.push("");
  lines.push("## Artifact Cleanup");
  lines.push("");
  for (const result of cleanupResults) {
    lines.push(
      `- ${result.path}: ${result.ok ? "OK" : "FAILED"}; existed=${result.existed}; removed=${result.removed}${
        result.error ? `; error=${result.error}` : ""
      }`
    );
  }
  if (cleanupResults.length === 0) {
    lines.push("- No configured artifacts.");
  }
  lines.push("");
  lines.push("## Next Action");
  lines.push("");
  lines.push(
    overallOk
      ? "Validation passed. Continue certification only after the implementation and self-check requirements are reviewed."
      : "Fix the exact failing command or forbidden scan matches, then rerun validation."
  );
  writeFileSync(path, `${lines.join("\n")}\n`);
}

export function loadValidationConfig() {
  return readJson("automation/config/validation-config.json");
}

export function loadForbiddenConfig() {
  return readJson("automation/config/forbidden-surfaces.json");
}
