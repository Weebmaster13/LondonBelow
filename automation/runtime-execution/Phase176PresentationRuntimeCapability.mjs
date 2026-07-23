import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 176;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-176");
const reportPath = path.join(evidenceDir, "phase-176-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Presentation/Core/RuntimePresentationCapability.lua",
  "src/ServerScriptService/Presentation/Core/PresentationRuntimeCoordinator.lua",
  "src/ServerScriptService/Presentation/Core/PresentationCapabilityRegistry.lua",
  "src/ServerScriptService/Presentation/Core/PresentationSessionRegistry.lua",
  "src/ServerScriptService/Presentation/Core/PresentationConsumerRegistry.lua",
  "src/ServerScriptService/Presentation/Core/PresentationQueue.lua",
  "src/ServerScriptService/Presentation/Core/PresentationLifecycleManager.lua",
  "src/ServerScriptService/Presentation/Core/PresentationAcknowledgementProducer.lua",
  "src/ServerScriptService/Presentation/Core/PresentationSynchronizationRuntime.lua",
  "src/ServerScriptService/Presentation/Core/PresentationRuntimeValidation.lua",
  "src/ServerScriptService/Presentation/Core/PresentationRuntimeSelfChecks.lua",
  "src/ServerScriptService/Presentation/Core/PresentationBudgets.lua",
  "src/ServerScriptService/Presentation/Core/PresentationCertification.lua",
  "src/ServerScriptService/Presentation/Core/PresentationGovernance.lua",
  "src/ServerScriptService/Presentation/Core/PresentationMetrics.lua",
  "src/ServerScriptService/Presentation/Core/PresentationProfiler.lua",
  "src/ServerScriptService/Presentation/Core/PresentationTypes.lua",
  "src/ServerScriptService/Presentation/Core/PresentationEvidence.lua",
  "src/ServerScriptService/Presentation/Core/PresentationSerialization.lua",
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
    "presentationRuntimeCapability",
    "presentationRuntime",
    "PresentationRuntimeCoordinator",
    "RuntimePresentationCapability",
    "PresentationCapabilityRegistry",
    "PresentationSessionRegistry",
    "PresentationConsumerRegistry",
    "PresentationQueue",
    "PresentationLifecycleManager",
    "PresentationAcknowledgementProducer",
    "PresentationSynchronizationRuntime",
    "PresentationRuntimeSelfChecks",
    "presentationRuntimePosture",
    "activeSessions",
    "queueState",
    "consumers",
    "acknowledgements",
    "synchronization",
    "noRendering",
    "noGui",
    "noNetworking",
    "noRemoteEvents",
    "noRemoteFunctions",
    "noWorkspaceMutation",
    "noClientAuthority",
    "ProductionCandidate",
  ]) checks.push(check(`source contains ${token}`, joined.includes(token)));

  checks.push(check("presentation runtime registers after dialogue presentation", bootstrap.indexOf('"DialoguePresentationCoordinator"') < bootstrap.indexOf('"PresentationRuntimeCoordinator"')));
  checks.push(check("presentation runtime registers before lobby", bootstrap.indexOf('"PresentationRuntimeCoordinator"') < bootstrap.indexOf('"LobbyService"')));
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase176:selfcheck")));
  checks.push(check("package presentation runtime script exists", packageJson.includes("london:presentation-runtime")));
  checks.push(check("roadmap records phase 176", roadmap.includes("Phase 176: Presentation Runtime Capability Foundation")));
  checks.push(check("tasks records phase 176", tasks.includes("Phase 176: Presentation Runtime Capability Foundation")));
  checks.push(check("engine records phase 176", engine.includes("Phase 176: Presentation Runtime Capability Foundation")));
  checks.push(check("master context records phase 176", context.includes("Phase 176: Presentation Runtime Capability Foundation")));
  checks.push(check("governance contract exists", governance.includes("Presentation Runtime Capability Foundation")));
  checks.push(check("governance provider exists", governance.includes('"presentationRuntime"')));

  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-176");
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
    "# Phase 176 Runtime Evidence",
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
    "Phase 176 is Production Candidate. Authoritative Roblox Studio runtime evidence has not been imported.",
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
