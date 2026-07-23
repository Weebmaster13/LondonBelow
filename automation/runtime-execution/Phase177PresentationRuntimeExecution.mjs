import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 177;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-177");
const reportPath = path.join(evidenceDir, "phase-177-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Presentation/Core/RuntimePresentationExecution.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionCoordinator.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionScheduler.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionQueue.lua",
  "src/ServerScriptService/Presentation/Core/SessionExecutionEngine.lua",
  "src/ServerScriptService/Presentation/Core/LifecycleExecutionEngine.lua",
  "src/ServerScriptService/Presentation/Core/AcknowledgementExecutionEngine.lua",
  "src/ServerScriptService/Presentation/Core/SynchronizationExecutionEngine.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionRecovery.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionDiagnostics.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionSnapshots.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionEvidence.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionMetrics.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionProfiler.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionValidation.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionGovernance.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionCertification.lua",
  "src/ServerScriptService/Presentation/Core/PresentationExecutionSelfChecks.lua",
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
  const packageJson = read("package.json");
  const roadmap = read("ROADMAP.md");
  const tasks = read("TASKS.md");
  const engine = read("LONDON_ENGINE.md");
  const context = read("LONDON_ENGINE_MASTER_CONTEXT.md");
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");

  for (const token of [
    "presentationRuntimeExecution",
    "PresentationExecutionCoordinator",
    "RuntimePresentationExecution",
    "PresentationExecutionScheduler",
    "PresentationExecutionQueue",
    "SessionExecutionEngine",
    "LifecycleExecutionEngine",
    "AcknowledgementExecutionEngine",
    "SynchronizationExecutionEngine",
    "PresentationExecutionRecovery",
    "presentationExecutionPosture",
    "executionQueue",
    "executingSessions",
    "noRendering",
    "noGui",
    "noNetworking",
    "noRemoteEvents",
    "noRemoteFunctions",
    "noWorkspaceMutation",
    "noClientAuthority",
    "ProductionCandidate",
  ]) checks.push(check(`source contains ${token}`, joined.includes(token)));

  checks.push(check("execution registers after presentation runtime", bootstrap.indexOf('"PresentationRuntimeCoordinator"') < bootstrap.indexOf('"PresentationExecutionCoordinator"')));
  checks.push(check("execution registers before lobby", bootstrap.indexOf('"PresentationExecutionCoordinator"') < bootstrap.indexOf('"LobbyService"')));
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase177:selfcheck")));
  checks.push(check("package presentation execution script exists", packageJson.includes("london:presentation-execution")));
  checks.push(check("roadmap records phase 177", roadmap.includes("Phase 177: Presentation Runtime Execution and Session Management")));
  checks.push(check("tasks records phase 177", tasks.includes("Phase 177: Presentation Runtime Execution and Session Management")));
  checks.push(check("engine records phase 177", engine.includes("Phase 177: Presentation Runtime Execution and Session Management")));
  checks.push(check("master context records phase 177", context.includes("Phase 177: Presentation Runtime Execution and Session Management")));
  checks.push(check("governance contract exists", governance.includes("Presentation Runtime Execution and Session Management")));
  checks.push(check("governance provider exists", governance.includes('"presentationRuntimeExecution"')));

  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-177");
    const present = fs.existsSync(docsDir) && fs.readdirSync(docsDir).some((name) => name.startsWith(prefix));
    checks.push(check(`phase doc ${prefix}`, present));
  }

  for (const banned of [
    'GetService("Data' + 'StoreService")',
    'GetService("Messaging' + 'Service")',
    'GetService("Http' + 'Service")',
    'Instance.new("Remote' + 'Event")',
    'Instance.new("Remote' + 'Function")',
    ":Set" + "Async(",
    ":Update" + "Async(",
    ":Get" + "Async(",
    ":Fire" + "Client(",
    ":FireAll" + "Clients(",
    "game." + "Workspace",
    'GetService("Workspace")',
  ]) checks.push(check(`forbidden surface absent ${banned}`, !joined.includes(banned)));

  return checks;
}

function summarize(checks) {
  const failures = checks.filter((item) => !item.ok);
  return { phase, ok: failures.length === 0, total: checks.length, passed: checks.length - failures.length, failed: failures.length, failures };
}

function writeRuntimeReport(summary, runtime) {
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(reportPath, [
    "# Phase 177 Runtime Evidence",
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
    "Phase 177 is Production Candidate. Authoritative Roblox Studio runtime evidence has not been imported.",
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
