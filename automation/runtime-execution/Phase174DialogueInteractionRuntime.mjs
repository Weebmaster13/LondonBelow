import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 174;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-174");
const reportPath = path.join(evidenceDir, "phase-174-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Dialogue/Core/RuntimeDialogueInteraction.lua",
  "src/ServerScriptService/Dialogue/Core/DialogueInteractionCoordinator.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionSessionRegistry.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionRequestManager.lua",
  "src/ServerScriptService/Dialogue/Core/PendingChoiceQueue.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionValidator.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionTimeoutManager.lua",
  "src/ServerScriptService/Dialogue/Core/DialogueInterruptionManager.lua",
  "src/ServerScriptService/Dialogue/Core/NestedConversationManager.lua",
  "src/ServerScriptService/Dialogue/Core/RuntimeEventCoordinator.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionDiagnostics.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionSnapshots.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionEvidence.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionMetrics.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionProfiler.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionValidation.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionBudgets.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionGovernance.lua",
  "src/ServerScriptService/Dialogue/Core/InteractionCertification.lua",
  "src/ServerScriptService/Dialogue/Core/DialogueInteractionTypes.lua",
  "src/ServerScriptService/Dialogue/Core/DialogueInteractionSelfChecks.lua",
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
    "dialogueRuntimeInteraction",
    "DialogueInteractionCoordinator",
    "RuntimeDialogueInteraction",
    "InteractionSessionRegistry",
    "InteractionRequestManager",
    "PendingChoiceQueue",
    "InteractionValidator",
    "InteractionTimeoutManager",
    "DialogueInterruptionManager",
    "NestedConversationManager",
    "RuntimeEventCoordinator",
    "dialogueInteractionPosture",
    "pendingInteractions",
    "activeWaits",
    "interruptions",
    "nestedConversations",
    "runtimeQueue",
    "noRemoteEvents",
    "noRemoteFunctions",
    "noNetworking",
    "noGameplayExecution",
    "ProductionCandidate",
  ]) checks.push(check(`source contains ${token}`, joined.includes(token)));

  checks.push(check("interaction registers after dialogue execution", bootstrap.indexOf('"DialogueExecutionCoordinator"') < bootstrap.indexOf('"DialogueInteractionCoordinator"')));
  checks.push(check("interaction registers before lobby", bootstrap.indexOf('"DialogueInteractionCoordinator"') < bootstrap.indexOf('"LobbyService"')));
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase174:selfcheck")));
  checks.push(check("package dialogue interaction script exists", packageJson.includes("london:dialogue-runtime-interaction")));
  checks.push(check("roadmap records phase 174", roadmap.includes("Phase 174: Dialogue Interaction and Runtime Event Coordination")));
  checks.push(check("tasks records phase 174", tasks.includes("Phase 174: Dialogue Interaction and Runtime Event Coordination")));
  checks.push(check("engine records phase 174", engine.includes("Phase 174: Dialogue Interaction and Runtime Event Coordination")));
  checks.push(check("master context records phase 174", context.includes("Phase 174: Dialogue Interaction and Runtime Event Coordination")));
  checks.push(check("governance contract exists", governance.includes("Dialogue Interaction and Runtime Event Coordination")));
  checks.push(check("governance provider exists", governance.includes('"dialogueRuntimeInteraction"')));

  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-174");
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
    "# Phase 174 Runtime Evidence",
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
    "Phase 174 is Production Candidate. Authoritative Roblox Studio runtime evidence has not been imported.",
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
