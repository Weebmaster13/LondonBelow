import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { runCommand } from "../../repository-state.mjs";

export function createPlaceArtifactPath(sessionId) {
  return join("automation", "local-state", "runtime-execution", sessionId, "runtime-execution.rbxlx");
}

export function buildTemporaryPlace(sessionId, projectPath = "default.project.json", options = {}) {
  const outputPath = options.outputPath ?? createPlaceArtifactPath(sessionId);
  mkdirSync(dirname(outputPath), { recursive: true });
  const startedAt = new Date().toISOString();
  const result = runCommand("rojo", ["build", projectPath, "--output", outputPath], {
    timeout: options.timeoutMs ?? 120000,
    maxBuffer: 1024 * 1024 * 20
  });
  const exists = existsSync(outputPath);
  const sizeBytes = exists ? statSync(outputPath).size : 0;
  const checksum = exists && sizeBytes > 0 ? createHash("sha256").update(readFileSync(outputPath)).digest("hex") : null;
  return {
    artifactId: `${sessionId}.place`,
    command: `rojo build ${projectPath} --output ${outputPath.replaceAll("\\", "/")}`,
    path: outputPath.replaceAll("\\", "/"),
    startedAt,
    finishedAt: new Date().toISOString(),
    exitCode: result.exitCode,
    failureKind: result.failureKind,
    stdout: result.stdout.trim(),
    stderr: result.stderr.trim(),
    exists,
    sizeBytes,
    checksum,
    stale: false,
    cleanupPolicy: options.retain ? "retain" : "deleteAfterRun",
    ok: result.ok && exists && sizeBytes > 0
  };
}
