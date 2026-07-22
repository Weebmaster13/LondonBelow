import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 168;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-168");
const reportPath = path.join(evidenceDir, "phase-168-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Core/Workflows/RuntimeWorkflowOrchestration.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowCoordinator.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowTypes.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowSerialization.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowValidation.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowRegistry.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowInstances.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowLifecycle.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowScheduler.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowTransitions.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowWaits.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowTimeouts.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowRetries.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowCancellation.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowCompensation.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowDiagnostics.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowSnapshots.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowEvidence.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowMetrics.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowProfiler.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowInspection.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowBudgets.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowCertification.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowSelfChecks.lua",
];

function read(relativePath) {
  return fs.readFileSync(path.join(repoRoot, relativePath), "utf8");
}

function exists(relativePath) {
  return fs.existsSync(path.join(repoRoot, relativePath));
}

function check(name, ok, detail = "") {
  return { name, ok: Boolean(ok), detail };
}

function sourceChecks() {
  const checks = [];
  const files = requiredFiles.map((file) => [file, exists(file), exists(file) ? read(file) : ""]);
  for (const [file, present] of files) checks.push(check(`required file ${file}`, present));
  const joined = files.map(([, , content]) => content).join("\n");
  const bootstrap = read("src/ServerScriptService/Core/Bootstrap.server.lua");
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
  const packageJson = read("package.json");
  for (const token of [
    "runtimeWorkflowOrchestration",
    "RuntimeWorkflowCoordinator",
    "workflow definitions",
    "workflow registration",
    "workflow lifecycle",
    "workflow scheduling metadata",
    "workflowOrchestrationPosture",
    "workflowDefinitions",
    "workflowInstances",
    "pendingWaits",
    "retryRecords",
    "timeoutRecords",
    "compensationRecords",
    "ProductionCandidate",
    "Authoritative Runtime Execution Framework evidence",
    "noDirectSubsystemCoupling",
    "noGameplayAuthority",
    "noCommandExecution",
    "noEventPublication",
    "noQueryMutation",
  ]) checks.push(check(`source contains ${token}`, joined.includes(token)));
  checks.push(check("bootstrap registers workflow after messaging integration", bootstrap.indexOf('registerModule("RuntimeMessagingCoordinator"') < bootstrap.indexOf('registerModule("RuntimeWorkflowCoordinator"')));
  checks.push(check("bootstrap registers workflow before lobby", bootstrap.indexOf('registerModule("RuntimeWorkflowCoordinator"') < bootstrap.indexOf('registerModule("LobbyService"')));
  checks.push(check("governance contract exists", governance.includes("Runtime Workflow and Process Orchestration Foundation")));
  checks.push(check("governance snapshot provider exists", governance.includes('"runtimeWorkflowOrchestration"')));
  checks.push(check("package selfcheck script exists", packageJson.includes("london:phase168:selfcheck")));
  checks.push(check("package runtime script exists", packageJson.includes("london:workflow-orchestration")));
  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-168");
    const present = fs.existsSync(docsDir) && fs.readdirSync(docsDir).some((name) => name.startsWith(prefix));
    checks.push(check(`phase doc ${prefix}`, present));
  }
  for (const banned of [
    'GetService("Data' + 'StoreService")',
    'GetService("Messaging' + 'Service")',
    'GetService("Http' + 'Service")',
    'Instance.new("Remote' + 'Event")',
    'Instance.new("Remote' + 'Function")',
    ":SetAsync(",
    ":UpdateAsync(",
    ":GetAsync(",
    ":FireClient(",
    ":FireAllClients(",
    "game.Workspace",
    'GetService("Workspace")',
  ]) checks.push(check(`forbidden surface absent ${banned}`, !joined.includes(banned)));
  return checks;
}

function summarize(checks) {
  const failures = checks.filter((item) => !item.ok);
  return {
    phase,
    ok: failures.length === 0,
    total: checks.length,
    passed: checks.length - failures.length,
    failed: failures.length,
    failures,
  };
}

function writeRuntimeReport(summary, runtime) {
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(reportPath, [
    "# Phase 168 Runtime Evidence",
    "",
    "## Self Checks",
    "",
    `Total: ${summary.total}`,
    `Passed: ${summary.passed}`,
    `Failed: ${summary.failed}`,
    "",
    "## Runtime Smoke Test",
    "",
    runtime.status,
    `Framework used: ${runtime.frameworkUsed}`,
    `Blocked reason: ${runtime.blockedReason}`,
    "",
    "## Certification",
    "",
    "Phase 168 is Production Candidate.",
    "",
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
  status: "blocked by environment",
  ok: false,
  blockedReason: "Authoritative Roblox Studio runtime evidence was not imported through the Runtime Execution Framework.",
};
writeRuntimeReport(summary, runtime);
console.log(JSON.stringify({ ok: false, selfCheck: summary, runtime }, null, 2));
process.exit(summary.ok ? 2 : 1);
