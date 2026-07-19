import { existsSync, readdirSync, statSync } from "node:fs";
import { basename, dirname, join } from "node:path";
import { createHash } from "node:crypto";
import { readJson, runCommand } from "../../repository-state.mjs";

const config = readJson("automation/config/automation-config.json");

function normalizePath(value) {
  let normalized = value.replaceAll("\\", "/");
  const replacements = [
    [process.cwd().replaceAll("\\", "/"), "<repo>"],
    [(process.env.USERPROFILE ?? "").replaceAll("\\", "/"), "<user-profile>"],
    [(process.env.LOCALAPPDATA ?? "").replaceAll("\\", "/"), "<local-app-data>"],
    [(process.env.APPDATA ?? "").replaceAll("\\", "/"), "<app-data>"],
    [(process.env.TEMP ?? "").replaceAll("\\", "/"), "<temp>"],
    [(process.env.TMP ?? "").replaceAll("\\", "/"), "<temp>"]
  ].filter(([prefix]) => prefix !== "");
  for (const [prefix, token] of replacements) normalized = normalized.replaceAll(prefix, token);
  return normalized;
}

function versionFromPath(executable) {
  const parent = basename(dirname(executable));
  return parent.startsWith("version-") ? parent : "unknown";
}

function hashIdentity(value) {
  return createHash("sha256").update(value).digest("hex").slice(0, 16);
}

function commandExists(command) {
  const probe = process.platform === "win32" ? runCommand("where", [command]) : runCommand("command", ["-v", command], { shell: true });
  return probe.ok ? probe.stdout.split(/\r?\n/).find(Boolean)?.trim() ?? null : null;
}

function studioCandidate(executable, source) {
  const stats = statSync(executable);
  return {
    executable: normalizePath(executable),
    executableIdentity: hashIdentity(executable),
    source,
    platform: process.platform,
    architecture: process.arch,
    versionId: versionFromPath(executable),
    modifiedAt: stats.mtime.toISOString(),
    detected: true,
    launchable: true,
    playRunCapable: false,
    structuredCaptureCapable: false
  };
}

export function discoverStudioInstallations() {
  const candidates = [];
  const configured = config.studioCertification?.studioExecutablePaths ?? [];
  for (const path of configured) {
    if (path && existsSync(path)) candidates.push(studioCandidate(path, "configuredPath"));
  }
  for (const command of [config.studioCertification?.studioExecutableName ?? "RobloxStudioBeta", "RobloxStudioLauncherBeta"]) {
    const found = commandExists(command);
    if (found && existsSync(found)) candidates.push(studioCandidate(found, "PATH"));
  }
  if (process.platform === "win32" && process.env.LOCALAPPDATA) {
    const versionsRoot = join(process.env.LOCALAPPDATA, "Roblox", "Versions");
    if (existsSync(versionsRoot)) {
      for (const entry of readdirSync(versionsRoot, { withFileTypes: true })) {
        const executable = join(versionsRoot, entry.name, "RobloxStudioBeta.exe");
        if (entry.isDirectory() && existsSync(executable)) candidates.push(studioCandidate(executable, "localVersions"));
      }
    }
  }
  const seen = new Set();
  return candidates
    .filter((candidate) => {
      if (seen.has(candidate.executableIdentity)) return false;
      seen.add(candidate.executableIdentity);
      return true;
    })
    .sort((left, right) => right.modifiedAt.localeCompare(left.modifiedAt) || left.executable.localeCompare(right.executable));
}

export function discoverStudioMcp() {
  if (process.platform === "win32" && process.env.LOCALAPPDATA) {
    const command = join(process.env.LOCALAPPDATA, "Roblox", "mcp.bat");
    if (existsSync(command)) {
      return {
        detected: true,
        command: normalizePath(command),
        commandIdentity: hashIdentity(command),
        repositoryOptIn: (config.studioCertification?.structuredCaptureMethods ?? []).includes("studioMcp"),
        structuredCaptureCapable: false,
        reason: "MCP command is present, but no repository-supported runner command is exposed."
      };
    }
  }
  return {
    detected: false,
    command: null,
    commandIdentity: null,
    repositoryOptIn: false,
    structuredCaptureCapable: false,
    reason: "No Studio MCP command detected."
  };
}
