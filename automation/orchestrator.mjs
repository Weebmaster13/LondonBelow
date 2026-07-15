import { mkdirSync } from "node:fs";
import { join } from "node:path";
import {
  buildToolEnv,
  checkTool,
  git,
  inspectRepository,
  readJson,
  verifyRequiredFiles
} from "./repository-state.mjs";
import { determineNextPhase, createRunId, generateArchitectureReview, generateSpecification } from "./phase-planner.mjs";
import { readState, writeState, markStatus, updateFromRepository } from "./state-manager.mjs";
import { runCodexTask } from "./codex-runner.mjs";
import {
  loadForbiddenConfig,
  loadValidationConfig,
  removeArtifacts,
  runForbiddenScan,
  runValidation,
  writeValidationLog,
  writeValidationMarkdown
} from "./validator.mjs";
import { commitPhase, pushAndVerify } from "./certifier.mjs";
import { writeRepositoryBaseline, writeSafeStop } from "./report-writer.mjs";

const cwd = process.cwd();
const config = readJson("automation/config/automation-config.json");
const validationConfig = loadValidationConfig();
const forbiddenConfig = loadForbiddenConfig();

function parseArgs(argv) {
  const args = { mode: argv[2] ?? "status", phases: 4 };
  for (let index = 3; index < argv.length; index += 1) {
    if (argv[index] === "--phases") {
      args.phases = Number(argv[index + 1]);
      index += 1;
    }
  }
  return args;
}

function runRoot(runId) {
  return join(config.runDirectory ?? "automation/runs", runId);
}

function printResult(label, ok, detail = "") {
  console.log(`${ok ? "OK" : "FAIL"} ${label}${detail ? ` - ${detail}` : ""}`);
}

function verifyEnvironment(repo = null) {
  const env = buildToolEnv(config);
  const requiredFiles = verifyRequiredFiles(validationConfig.requiredFiles ?? [], cwd);
  const tools = [
    checkTool("node", "node", ["--version"], { cwd }),
    checkTool("npm", "npm", ["--version"], { cwd }),
    checkTool("git", config.gitExecutable ?? "git", ["--version"], { cwd }),
    checkTool("gh", config.ghExecutable ?? "gh", ["--version"], { cwd }),
    checkTool("codex", config.codexExecutable ?? "codex", ["--version"], { cwd }),
    checkTool("stylua", "stylua", ["--version"], { cwd, env }),
    checkTool("selene", "selene", ["--version"], { cwd, env }),
    checkTool("rojo", "rojo", ["--version"], { cwd, env })
  ];
  const ghAuth = checkTool("gh auth", config.ghExecutable ?? "gh", ["auth", "status"], { cwd });
  const remote = git(config, ["remote", "-v"], { cwd });
  const state = readState();
  const allRequiredFiles = requiredFiles.every((item) => item.exists);
  const allTools = tools.every((tool) => tool.ok);
  return {
    ok: allRequiredFiles && allTools && ghAuth.ok && remote.ok && Boolean(state) && repo.workingTreeClean,
    requiredFiles,
    tools,
    ghAuth,
    remote,
    repo
  };
}

function printCheck() {
  const repo = inspectRepository(config, cwd);
  const result = verifyEnvironment(repo);
  console.log("London Engine Autopilot Check\n");
  for (const file of result.requiredFiles) {
    printResult(`required file ${file.path}`, file.exists);
  }
  for (const tool of result.tools) {
    printResult(`tool ${tool.name}`, tool.ok, tool.output.split(/\r?\n/)[0] ?? "");
  }
  printResult("gh auth status", result.ghAuth.ok, result.ghAuth.output.split(/\r?\n/)[0] ?? "");
  printResult("git remote", result.remote.ok);
  printResult("working tree clean", repo.workingTreeClean);
  console.log(`\nBranch: ${repo.branch}`);
  console.log(`Local HEAD: ${repo.localHead}`);
  console.log(`Remote HEAD: ${repo.remoteHead}`);
  if (!result.ok) {
    process.exitCode = 1;
  }
}

function printStatus() {
  const state = readState();
  const repo = inspectRepository(config, cwd);
  console.log("London Engine Autopilot Status\n");
  console.log(`Status: ${state?.status ?? "missing state"}`);
  console.log(`Last certified phase: ${state?.lastCertifiedPhase} - ${state?.lastCertifiedPhaseName}`);
  console.log(`Last certified commit: ${state?.lastCertifiedCommit}`);
  console.log(`Next recommended phase: ${state?.nextRecommendedPhase} - ${state?.nextRecommendedPhaseName}`);
  console.log(`Branch: ${repo.branch}`);
  console.log(`Local HEAD: ${repo.localHead}`);
  console.log(`Remote HEAD: ${repo.remoteHead}`);
  console.log(`Working tree clean: ${repo.workingTreeClean}`);
}

function ensureCleanOrStop(repo) {
  if (!repo.workingTreeClean) {
    throw new Error("Working tree has uncommitted changes.");
  }
}

function planOnly() {
  const state = readState();
  if (!state) throw new Error("Missing automation/state/phase-state.json");
  const repo = inspectRepository(config, cwd);
  const runId = createRunId();
  const dir = runRoot(runId);
  ensureCleanOrStop(repo);
  mkdirSync(dir, { recursive: true });
  writeRepositoryBaseline(dir, repo);
  const phase = determineNextPhase(state);
  const specPath = generateSpecification({ phase, repo, runId, runRoot: dir });
  const reviewPath = generateArchitectureReview({ phase, runRoot: dir });
  console.log(`Generated plan for Phase ${phase.phase} - ${phase.name}`);
  console.log(`Specification: ${specPath}`);
  console.log(`Architecture review: ${reviewPath}`);
}

function validateCurrent(runDir, phase, baseCommit = null) {
  const validation = runValidation(config, validationConfig, cwd);
  const scan = runForbiddenScan(forbiddenConfig, cwd, { config, baseCommit });
  const cleanup = removeArtifacts(validationConfig.generatedArtifacts, cwd);
  const ok = validation.every((item) => item.ok) && scan.ok && cleanup.every((item) => item.ok);
  writeValidationLog(join(runDir, `phase-${phase.phase}-validation.log`), validation, scan, cleanup);
  writeValidationMarkdown(join(runDir, `phase-${phase.phase}-validation.md`), validation, scan, cleanup);
  return { ok, validation, scan, cleanup };
}

function auto(mode, requestedPhases) {
  const maximum = Math.min(
    Number.isFinite(requestedPhases) ? requestedPhases : config.maximumPhasesPerBatch,
    config.maximumPhasesPerBatch
  );
  if (maximum < 1) throw new Error("--phases must be at least 1");
  const state = readState();
  if (!state) throw new Error("Missing automation/state/phase-state.json");
  const repo = inspectRepository(config, cwd);
  const runId = createRunId();
  const dir = runRoot(runId);
  ensureCleanOrStop(repo);
  mkdirSync(dir, { recursive: true });
  writeRepositoryBaseline(dir, repo);
  const environment = verifyEnvironment(repo);
  if (!environment.ok) {
    const nextState = markStatus(updateFromRepository(state, repo), "authentication_required", "Environment check failed.", {
      lastRunId: runId
    });
    writeState(nextState);
    writeSafeStop(dir, {
      ...nextState,
      reason: "Environment check failed. Run npm run london:check for details.",
      nextAction: "Install or authenticate missing tools, then run npm run london:continue -- --phases 1."
    });
    console.log("Environment check failed. Run npm run london:check for details.");
    process.exitCode = 1;
    return;
  }
  let currentState = markStatus(updateFromRepository(state, repo), mode === "continue" ? "ready" : "implementing", null, {
    completedInCurrentBatch: 0,
    lastRunId: runId
  });
  for (let count = 0; count < maximum; count += 1) {
    const latestRepo = inspectRepository(config, cwd);
    ensureCleanOrStop(latestRepo);
    const phase = determineNextPhase(currentState);
    const specPath = generateSpecification({ phase, repo: latestRepo, runId, runRoot: dir });
    const reviewPath = generateArchitectureReview({ phase, runRoot: dir });
    currentState = markStatus(updateFromRepository(currentState, latestRepo), "implementing", null, {
      activePhase: phase.phase,
      activePhaseName: phase.name
    });
    const codex = runCodexTask({ config, phase, specPath, reviewPath, runRoot: dir, cwd });
    if (!codex.ok) {
      const nextState = markStatus(currentState, "blocked", codex.reason ?? "Codex task failed.", {
        lastRunId: runId
      });
      writeState(nextState);
      writeSafeStop(dir, {
        ...nextState,
        reason: codex.reason ?? "Codex task failed.",
        nextAction: `Review ${codex.promptPath}, enable Codex execution, then rerun npm run london:continue -- --phases 1.`
      });
      console.log(codex.reason ?? "Codex task failed.");
      process.exitCode = 1;
      return;
    }
    const validation = validateCurrent(dir, phase, currentState.lastCertifiedCommit);
    if (!validation.ok) {
      const nextState = markStatus(currentState, "validation_failed", "Validation failed.", {
        lastValidationPassed: false,
        lastForbiddenScanPassed: validation.scan.ok
      });
      writeState(nextState);
      process.exitCode = 1;
      return;
    }
    const commit = commitPhase(config, `Phase ${phase.phase} - ${phase.name}`, cwd);
    if (!commit.ok) {
      throw new Error(`Commit failed at ${commit.step}`);
    }
    const exact = validateCurrent(dir, phase, currentState.lastCertifiedCommit);
    if (!exact.ok) {
      throw new Error("Exact-commit validation failed.");
    }
    const pushed = pushAndVerify(config, cwd);
    if (!pushed.ok) {
      throw new Error("Push or remote verification failed.");
    }
    currentState = markStatus(updateFromRepository(currentState, inspectRepository(config, cwd)), "ready", null, {
      lastCertifiedPhase: phase.phase,
      lastCertifiedPhaseName: phase.name,
      lastCertifiedCommit: commit.commit,
      completedInCurrentBatch: count + 1,
      lastValidationPassed: true,
      lastForbiddenScanPassed: true,
      lastRemoteVerificationPassed: true
    });
  }
  writeState(currentState);
}

const args = parseArgs(process.argv);

try {
  if (args.mode === "check") {
    printCheck();
  } else if (args.mode === "status") {
    printStatus();
  } else if (args.mode === "plan") {
    planOnly();
  } else if (args.mode === "auto" || args.mode === "continue") {
    auto(args.mode, args.phases);
  } else {
    throw new Error(`Unknown mode: ${args.mode}`);
  }
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
