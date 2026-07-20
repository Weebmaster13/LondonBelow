import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { runRuntimeExecution } from "./RuntimeExecutionCoordinator.mjs";
import { runPhase155SelfChecks } from "./Phase155StudioRuntimeExecutionBridge.mjs";

export const phase156Id = 156;
export const phase156Name = "Interaction Runtime Foundation and Validation";
export const evidenceDirectory = "automation/runtime-evidence/phase-156";
export const reportPath = `${evidenceDirectory}/phase-156-runtime-report.md`;

const requiredSourceFiles = Object.freeze([
  "src/ServerScriptService/Interaction/Core/InteractionCoordinator.lua",
  "src/ServerScriptService/Interaction/Core/InteractionRequestRuntime.lua",
  "src/ServerScriptService/Interaction/Core/InteractionValidation.lua",
  "src/ServerScriptService/Interaction/Core/InteractionObjectRuntime.lua",
  "src/ServerScriptService/Interaction/Core/InteractionDiagnostics.lua",
  "src/ServerScriptService/Interaction/Core/InteractionSnapshots.lua",
  "src/ServerScriptService/Interaction/Core/InteractionSelfChecks.lua",
  "src/ServerScriptService/Gameplay/PlayerExperienceService.lua",
  "src/ReplicatedStorage/Shared/PlayerExperienceRemoteNames.lua"
]);

const requiredDocs = Object.freeze([
  "PHASE_156_OVERVIEW.md",
  "PHASE_156_BASELINE.md",
  "PHASE_156_ARCHITECTURE.md",
  "PHASE_156_SCOPE.md",
  "PHASE_156_INTERACTION_MODEL.md",
  "PHASE_156_TARGET_IDENTITY.md",
  "PHASE_156_DEFINITION_CONTRACT.md",
  "PHASE_156_REGISTRY.md",
  "PHASE_156_OBSERVATION_INTEGRATION.md",
  "PHASE_156_ELIGIBILITY_PIPELINE.md",
  "PHASE_156_REQUEST_PROTOCOL.md",
  "PHASE_156_AUTHORIZATION.md",
  "PHASE_156_EXECUTION_LIFECYCLE.md",
  "PHASE_156_SESSION_MODEL.md",
  "PHASE_156_CANCELLATION.md",
  "PHASE_156_COOLDOWNS.md",
  "PHASE_156_CONTENTION.md",
  "PHASE_156_RATE_LIMITING.md",
  "PHASE_156_NETWORK_CONTRACT.md",
  "PHASE_156_DIAGNOSTICS.md",
  "PHASE_156_RUNTIME_EVIDENCE.md",
  "PHASE_156_SECURITY_REVIEW.md",
  "PHASE_156_FAILURE_INJECTION.md",
  "PHASE_156_PERFORMANCE_REVIEW.md",
  "PHASE_156_SELF_CHECKS.md",
  "PHASE_156_RUNTIME_SMOKE_TEST.md",
  "PHASE_156_VALIDATION.md",
  "PHASE_156_COMPLETION_REPORT.md"
]);

function read(path) {
  return readFileSync(path, "utf8");
}

function write(path, text) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, text, "utf8");
}

function add(checks, name, ok, message = "") {
  checks.push({ name, ok, message });
}

function summarize(checks) {
  const total = checks.length;
  const failed = checks.filter((check) => !check.ok);
  return {
    ok: failed.length === 0,
    total,
    passed: total - failed.length,
    failed: failed.length,
    failures: failed
  };
}

export function runPhase156SelfChecks() {
  const checks = [];
  for (const file of requiredSourceFiles) {
    add(checks, `source exists: ${file}`, existsSync(file), "required Phase 156 source file");
  }

  const types = read("src/ServerScriptService/Interaction/Core/InteractionTypes.lua");
  const validation = read("src/ServerScriptService/Interaction/Core/InteractionValidation.lua");
  const coordinator = read("src/ServerScriptService/Interaction/Core/InteractionCoordinator.lua");
  const requestRuntime = read("src/ServerScriptService/Interaction/Core/InteractionRequestRuntime.lua");
  const diagnostics = read("src/ServerScriptService/Interaction/Core/InteractionDiagnostics.lua");
  const selfChecks = read("src/ServerScriptService/Interaction/Core/InteractionSelfChecks.lua");
  const packageJson = JSON.parse(read("package.json"));

  add(checks, "server authoritative mode", types.includes("ServerAuthoritativeInteractionRuntime"));
  add(checks, "target identity limit", types.includes("MaxTargets"));
  add(checks, "session limit", types.includes("MaxSessions"));
  add(checks, "request replay code", types.includes("DuplicateRequest"));
  add(checks, "rate limit code", types.includes("RateLimited"));
  add(checks, "request validation", validation.includes("function Validation.request"));
  add(checks, "target validation", validation.includes("function Validation.target"));
  add(checks, "coordinator target API", coordinator.includes("function InteractionCoordinator.registerTarget"));
  add(checks, "coordinator request API", coordinator.includes("function InteractionCoordinator.requestInteraction"));
  add(checks, "coordinator cancellation API", coordinator.includes("function InteractionCoordinator.cancelSession"));
  add(checks, "authorization before mutation posture", diagnostics.includes("authorizationBeforeMutation"));
  add(checks, "lowerCamelCase posture key", diagnostics.includes("interactionRuntimePosture"));
  add(checks, "request runtime evaluates eligibility", requestRuntime.includes("function RequestRuntime.evaluate"));
  add(checks, "request runtime creates sessions", requestRuntime.includes("state.addSession"));
  add(checks, "request runtime records evidence", requestRuntime.includes("state.recordEvidence"));
  add(checks, "request runtime uses pcall handler boundary", requestRuntime.includes("pcall(handler.execute"));
  add(checks, "self-check duplicate target", selfChecks.includes("duplicateTargetRejects"));
  add(checks, "self-check duplicate request", selfChecks.includes("duplicateRequestRejects"));
  add(checks, "self-check cancellation", selfChecks.includes("cancellationRecords"));
  add(checks, "self-check rate limiting", selfChecks.includes("rateLimitRejects"));
  add(checks, "self-check banned remotes", selfChecks.includes("noRemotes = true"));

  for (const doc of requiredDocs) {
    const path = `docs/phases/phase-156/${doc}`;
    add(checks, `doc exists: ${doc}`, existsSync(path) && read(path).trim().length > 0);
  }

  add(checks, "package script selfcheck", packageJson.scripts["london:phase156:selfcheck"] !== undefined);
  add(checks, "package script runtime", packageJson.scripts["london:interaction-runtime"] !== undefined);
  add(checks, "package script validate", packageJson.scripts["london:interaction-runtime:validate"] !== undefined);

  const upstream = runPhase155SelfChecks();
  const upstreamChecks = Array.isArray(upstream) ? upstream : [];
  const upstreamFailures = upstreamChecks.filter((check) => check.ok !== true);
  add(
    checks,
    "phase155 upstream self-checks",
    upstreamChecks.length > 0 && upstreamFailures.length === 0,
    JSON.stringify(upstreamFailures)
  );

  return summarize(checks);
}

function markdown(result, runtime = null) {
  const lines = [
    "# Phase 156 Runtime Report",
    "",
    `Phase: ${phase156Id} - ${phase156Name}`,
    `Status: ${result.ok ? "STATIC_VALIDATION_PASSED" : "STATIC_VALIDATION_FAILED"}`,
    `Total checks: ${result.total}`,
    `Passed: ${result.passed}`,
    `Failed: ${result.failed}`,
    "",
    "## Failures",
    ""
  ];
  if (result.failures.length === 0) {
    lines.push("None");
  } else {
    for (const failure of result.failures) {
      lines.push(`- ${failure.name}: ${failure.message}`);
    }
  }
  lines.push("", "## Runtime Smoke Test", "");
  if (runtime == null) {
    lines.push("Not executed by this command.");
  } else {
    lines.push(`Framework used: ${runtime.frameworkUsed === true}`);
    lines.push(`Status: ${runtime.status}`);
    lines.push(`Blocked reason: ${runtime.blockedReason ?? "None"}`);
  }
  return `${lines.join("\n")}\n`;
}

export async function runPhase156Runtime() {
  const selfCheck = runPhase156SelfChecks();
  const execution = await runRuntimeExecution({
    phase: phase156Id,
    phaseName: phase156Name,
    runnerId: "runtimeExecution.phase156.interactionRuntimeFoundation",
    expectedEvidenceFile: "runtime-result.json"
  });
  const runtime = {
    frameworkUsed: true,
    status: execution?.status ?? "executionBlocked",
    blockedReason:
      execution?.backendResult?.blockedReason ??
      execution?.backendResult?.reason ??
      "Roblox Studio runtime evidence was not imported."
  };
  write(reportPath, markdown(selfCheck, runtime));
  return {
    ok: selfCheck.ok && runtime.status !== "executionBlocked",
    selfCheck,
    runtime
  };
}

async function main() {
  const args = new Set(process.argv.slice(2));
  const result = runPhase156SelfChecks();
  if (args.has("--runtime")) {
    const runtime = await runPhase156Runtime();
    console.log(JSON.stringify(runtime, null, 2));
    process.exit(runtime.ok ? 0 : 2);
  }
  write(reportPath, markdown(result));
  console.log(JSON.stringify(result, null, 2));
  process.exit(result.ok ? 0 : 1);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
