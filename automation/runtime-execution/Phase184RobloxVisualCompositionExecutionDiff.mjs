import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 184;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-184");
const reportPath = path.join(evidenceDir, "phase-184-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Presentation/Core/RuntimeRobloxVisualCompositionExecution.lua",
  "src/ServerScriptService/Presentation/Core/RobloxVisualCompositionExecutionCoordinator.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionSessionRegistry.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionLifecycle.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionScheduler.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionQueue.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionDiffEngine.lua",
  "src/ServerScriptService/Presentation/Core/VisualStructuralDiff.lua",
  "src/ServerScriptService/Presentation/Core/VisualSemanticDiff.lua",
  "src/ServerScriptService/Presentation/Core/VisualDiffNormalizer.lua",
  "src/ServerScriptService/Presentation/Core/VisualOperationTypes.lua",
  "src/ServerScriptService/Presentation/Core/VisualOperationFactory.lua",
  "src/ServerScriptService/Presentation/Core/VisualOperationRegistry.lua",
  "src/ServerScriptService/Presentation/Core/VisualOperationValidation.lua",
  "src/ServerScriptService/Presentation/Core/VisualOperationDependencies.lua",
  "src/ServerScriptService/Presentation/Core/VisualOperationCoalescer.lua",
  "src/ServerScriptService/Presentation/Core/VisualPatchPlanner.lua",
  "src/ServerScriptService/Presentation/Core/VisualPatchPlanRegistry.lua",
  "src/ServerScriptService/Presentation/Core/VisualPatchPlanValidation.lua",
  "src/ServerScriptService/Presentation/Core/VisualPatchDependencyGraph.lua",
  "src/ServerScriptService/Presentation/Core/VisualPatchBatching.lua",
  "src/ServerScriptService/Presentation/Core/VisualRevisionFence.lua",
  "src/ServerScriptService/Presentation/Core/VisualRevisionCompareAndCommit.lua",
  "src/ServerScriptService/Presentation/Core/VisualSupersessionRuntime.lua",
  "src/ServerScriptService/Presentation/Core/VisualTransactionRuntime.lua",
  "src/ServerScriptService/Presentation/Core/VisualRollbackPlanner.lua",
  "src/ServerScriptService/Presentation/Core/VisualCancellationRuntime.lua",
  "src/ServerScriptService/Presentation/Core/VisualRecoveryRuntime.lua",
  "src/ServerScriptService/Presentation/Core/VisualReplayRuntime.lua",
  "src/ServerScriptService/Presentation/Core/VisualIdempotencyRuntime.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionDiagnostics.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionSnapshots.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionEvidence.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionMetrics.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionProfiler.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionBudgets.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionValidation.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionGovernance.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionCertification.lua",
  "src/ServerScriptService/Presentation/Core/VisualExecutionSelfChecks.lua",
];

const phaseDocs = [
  "00_BASELINE.md", "01_ARCHITECTURE.md", "02_EXECUTION_SESSION_MODEL.md", "03_DIFF_ENGINE.md",
  "04_STRUCTURAL_DIFF.md", "05_SEMANTIC_DIFF.md", "06_OPERATION_MODEL.md", "07_OPERATION_ORDERING.md",
  "08_DEPENDENCY_DAG.md", "09_OPERATION_COALESCING.md", "10_PATCH_PLANNER.md", "11_PATCH_LIFECYCLE.md",
  "12_REVISION_FENCES.md", "13_COMPARE_AND_COMMIT.md", "14_TRANSACTION_RUNTIME.md", "15_ROLLBACK_PLANNING.md",
  "16_SUPERSESSION.md", "17_CANCELLATION.md", "18_IDEMPOTENCY.md", "19_REPLAY.md", "20_RECOVERY.md",
  "21_BATCHING.md", "22_PRESSURE_AND_BUDGETS.md", "23_DIAGNOSTICS_AND_SNAPSHOTS.md",
  "24_EVIDENCE_METRICS_PROFILER.md", "25_FAILURE_INJECTION.md", "26_SECURITY_REVIEW.md", "27_GOVERNANCE.md",
  "28_SELF_CHECKS.md", "29_RUNTIME_SMOKE_TEST.md", "30_PRODUCTION_REVIEW.md", "31_COMPLETION_REPORT.md",
];

function read(relativePath) { return fs.readFileSync(path.join(repoRoot, relativePath), "utf8"); }
function exists(relativePath) { return fs.existsSync(path.join(repoRoot, relativePath)); }
function check(name, ok, detail = "") { return { name, ok: Boolean(ok), detail }; }

function executableBannedApiClean(files) {
  const patterns = [
    /Instance\.new\s*\(/i, /ScreenGui/i, /PlayerGui/i, /CoreGui/i,
    /\bFrame\b/i, /TextLabel/i, /TextButton/i, /ImageLabel/i, /ImageButton/i, /ScrollingFrame/i, /ViewportFrame/i,
    /UIListLayout/i, /UIGridLayout/i, /UIPadding/i, /UICorner/i, /UIStroke/i, /UIGradient/i, /UIScale/i,
    /TweenService/i, /ContentProvider/i, /RemoteEvent/i, /RemoteFunction/i, /FireClient\s*\(/i, /FireAllClients\s*\(/i, /InvokeClient\s*\(/i,
    /game\s*:\s*GetService\(\s*["'](?:Workspace|DataStoreService|MessagingService|HttpService|AnalyticsService)["']/i,
    /\bworkspace\b/i,
  ];
  const hits = [];
  for (const file of files) {
    const lines = read(file).split(/\r?\n/);
    lines.forEach((line, index) => {
      if (/doesNotOwn|no Workspace mutation|Workspace mutation|ScreenGui creation|no-gui|no-rendering/i.test(line)) return;
      for (const pattern of patterns) if (pattern.test(line)) hits.push(`${file}:${index + 1}:${line.trim()}`);
    });
  }
  return { ok: hits.length === 0, hits };
}

function sourceChecks() {
  const checks = [];
  for (const file of requiredFiles) checks.push(check(`required file ${file}`, exists(file)));
  const joined = requiredFiles.filter(exists).map(read).join("\n");
  const bootstrap = read("src/ServerScriptService/Core/Bootstrap.server.lua");
  const packageJson = read("package.json");
  const roadmap = read("ROADMAP.md");
  const tasks = read("TASKS.md");
  const engine = read("LONDON_ENGINE.md");
  const context = read("LONDON_ENGINE_MASTER_CONTEXT.md");
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
  const tokens = [
    "robloxVisualCompositionExecutionRuntime", "robloxVisualCompositionExecutionCapability", "robloxVisualCompositionExecutionPosture",
    "RobloxVisualCompositionExecutionCoordinator", "RuntimeRobloxVisualCompositionExecution", "VisualExecutionState", "VisualPatchState",
    "VisualOperationKind", "VisualTransactionState", "VisualRollbackStrategy", "VisualRecoveryDecision", "VisualQueueState",
    "VisualPressureState", "VisualExecutionFailureType", "VisualExecutionLimits", "AddNode", "RemoveNode", "MoveNode",
    "UpdateVisibility", "dependencyGraph", "rollbackPlan", "revisionFence", "transaction", "ProductionCandidate",
    "noGuiMutation", "noInstanceCreation", "noRenderingExecution", "noNetworking", "noClientAuthority",
  ];
  for (const token of tokens) checks.push(check(`source contains ${token}`, joined.includes(token) || read("src/ServerScriptService/Presentation/Core/PresentationTypes.lua").includes(token)));
  checks.push(check("bootstrap registers after visual composition", bootstrap.indexOf('"RobloxVisualCompositionCoordinator"') < bootstrap.indexOf('"RobloxVisualCompositionExecutionCoordinator"')));
  checks.push(check("bootstrap registers before lobby", bootstrap.indexOf('"RobloxVisualCompositionExecutionCoordinator"') < bootstrap.indexOf('"LobbyService"')));
  checks.push(check("governance contract exists", governance.includes("Roblox Visual Composition Execution and Diff Runtime")));
  checks.push(check("governance provider exists", governance.includes('"robloxVisualCompositionExecutionRuntime"')));
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase184:selfcheck")));
  checks.push(check("package runtime script exists", packageJson.includes("london:roblox-visual-composition-execution")));
  checks.push(check("package validate script exists", packageJson.includes("london:roblox-visual-composition-execution:validate")));
  checks.push(check("roadmap records phase 184", roadmap.includes("Phase 184: Roblox Visual Composition Execution and Diff Runtime")));
  checks.push(check("tasks records phase 184", tasks.includes("Phase 184: Roblox Visual Composition Execution and Diff Runtime")));
  checks.push(check("engine records phase 184", engine.includes("Phase 184: Roblox Visual Composition Execution and Diff Runtime")));
  checks.push(check("master context records phase 184", context.includes("Phase 184: Roblox Visual Composition Execution and Diff Runtime")));
  const docsDir = path.join(repoRoot, "docs", "phases", "phase-184");
    for (const doc of phaseDocs) {
    const docPath = path.join(docsDir, doc);
    const present = fs.existsSync(docPath);
    checks.push(check(`phase doc ${doc}`, present));
    if (present) {
      const text = fs.readFileSync(docPath, "utf8");
      checks.push(check(`phase doc ${doc} documents ownership`, text.includes("## Ownership")));
      checks.push(check(`phase doc ${doc} documents non-ownership`, text.includes("## Non-Ownership")));
      checks.push(check(`phase doc ${doc} documents certification boundary`, text.includes("## Certification Boundary")));
    }
  }
  const scan = executableBannedApiClean(requiredFiles.filter((file) => file.endsWith(".lua")));
  checks.push(check("forbidden executable API scan clean", scan.ok, scan.hits.join("\n")));
  return checks;
}

function summarize(checks) {
  const failures = checks.filter((item) => !item.ok);
  return { phase, ok: failures.length === 0, total: checks.length, passed: checks.length - failures.length, failed: failures.length, failures };
}

function writeRuntimeReport(summary, runtime) {
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(reportPath, [
    "# Phase 184 Runtime Evidence", "", "## Static Self Checks", "",
    `Total: ${summary.total}`, `Passed: ${summary.passed}`, `Failed: ${summary.failed}`, "",
    "## Runtime Smoke Test", "", runtime.status, `Framework used: ${runtime.frameworkUsed}`,
    `Execution blocked: ${runtime.executionBlocked}`, `Blocked reason: ${runtime.blockedReason}`, "",
    "## Certification", "", "Phase 184 is Production Candidate. Authoritative Roblox Studio runtime evidence has not been imported.", "",
  ].join("\n"));
}

const summary = summarize(sourceChecks());
const args = new Set(process.argv.slice(2));
if (args.has("--self-check") || args.has("--validate")) {
  console.log(JSON.stringify(summary, null, 2));
  process.exit(summary.ok ? 0 : 1);
}
const runtime = {
  frameworkUsed: true,
  executionBlocked: true,
  status: "executionBlocked",
  ok: false,
  blockedReason: "Authoritative Roblox Studio runtime evidence was not imported through the Runtime Execution Framework.",
};
writeRuntimeReport(summary, runtime);
console.log(JSON.stringify({ ok: false, selfCheck: summary, runtime }, null, 2));
process.exit(summary.ok ? 2 : 1);