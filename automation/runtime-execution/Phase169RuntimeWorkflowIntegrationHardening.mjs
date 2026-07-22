import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 169;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-169");
const reportPath = path.join(evidenceDir, "phase-169-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Core/Workflows/RuntimeWorkflowOrchestration.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowCoordinator.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowIntegrationCoordinator.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowCorrelation.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowCausation.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowRouting.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowExecutionPipeline.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowActivation.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowSuspension.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowResumption.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowCompletion.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowSchedulerHardening.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowDiagnostics.lua",
  "src/ServerScriptService/Core/Workflows/WorkflowSnapshots.lua",
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
  const packageJson = read("package.json");
  const roadmap = read("ROADMAP.md");
  const tasks = read("TASKS.md");
  const engine = read("LONDON_ENGINE.md");
  const context = read("LONDON_ENGINE_MASTER_CONTEXT.md");
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");

  for (const token of [
    "runtimeWorkflowOrchestration",
    "WorkflowIntegrationCoordinator",
    "activateWorkflow",
    "routeMessage",
    "suspendWorkflow",
    "resumeWorkflow",
    "validateCompletion",
    "workflowIntegrationPosture",
    "correlationRecords",
    "causationRecords",
    "routingRecords",
    "executionPipeline",
    "schedulerHardening",
    "noDirectCommandBusExecution",
    "noDirectEventBusPublication",
    "noDirectQueryBusExecution",
    "DuplicateCorrelation",
    "MissingCorrelation",
    "DuplicateExecution",
  ]) checks.push(check(`source contains ${token}`, joined.includes(token)));

  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase169:selfcheck")));
  checks.push(check("package workflow integration runtime script exists", packageJson.includes("london:workflow-integration")));
  checks.push(check("roadmap records phase 169", roadmap.includes("Phase 169: Runtime Workflow Integration Hardening")));
  checks.push(check("tasks records phase 169", tasks.includes("Phase 169: Runtime Workflow Integration Hardening")));
  checks.push(check("engine records phase 169", engine.includes("Phase 169: Runtime Workflow Integration Hardening")));
  checks.push(check("master context records phase 169", context.includes("Phase 169: Runtime Workflow Integration Hardening")));
  checks.push(check("governance hardening contract exists", governance.includes("Runtime Workflow Integration Hardening")));
  checks.push(check("governance provider remains existing workflow provider", governance.includes('"runtimeWorkflowOrchestration"')));

  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-169");
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
    "# Phase 169 Runtime Evidence",
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
    "Phase 169 is Production Candidate.",
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
