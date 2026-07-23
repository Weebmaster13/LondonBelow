import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 175;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-175");
const reportPath = path.join(evidenceDir, "phase-175-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Dialogue/Core/RuntimeDialoguePresentationContract.lua",
  "src/ServerScriptService/Dialogue/Core/DialoguePresentationCoordinator.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationContractRegistry.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationRequestRegistry.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationRequestBuilder.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationDescriptorValidator.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationAcknowledgementRegistry.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationSynchronizationManager.lua",
  "src/ServerScriptService/Dialogue/Core/LocalizationReferenceRegistry.lua",
  "src/ServerScriptService/Dialogue/Core/AccessibilityMetadataRegistry.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationDiagnostics.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationSnapshots.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationEvidence.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationMetrics.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationProfiler.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationBudgets.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationValidation.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationGovernance.lua",
  "src/ServerScriptService/Dialogue/Core/PresentationCertification.lua",
  "src/ServerScriptService/Dialogue/Core/DialoguePresentationTypes.lua",
  "src/ServerScriptService/Dialogue/Core/DialoguePresentationSelfChecks.lua",
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
    "dialoguePresentationContract",
    "dialogueRuntimePresentationContract",
    "DialoguePresentationCoordinator",
    "RuntimeDialoguePresentationContract",
    "PresentationContractRegistry",
    "PresentationRequestRegistry",
    "PresentationRequestBuilder",
    "PresentationDescriptorValidator",
    "PresentationAcknowledgementRegistry",
    "PresentationSynchronizationManager",
    "LocalizationReferenceRegistry",
    "AccessibilityMetadataRegistry",
    "dialoguePresentationContractPosture",
    "activePresentationRequests",
    "pendingAcknowledgements",
    "synchronizationState",
    "localizationReferences",
    "accessibilityMetadata",
    "noUiRendering",
    "noNetworking",
    "noRemoteEvents",
    "noRemoteFunctions",
    "noWorkspaceMutation",
    "noClientAuthority",
    "ProductionCandidate",
  ]) checks.push(check(`source contains ${token}`, joined.includes(token)));

  checks.push(check("presentation registers after interaction", bootstrap.indexOf('"DialogueInteractionCoordinator"') < bootstrap.indexOf('"DialoguePresentationCoordinator"')));
  checks.push(check("presentation registers before lobby", bootstrap.indexOf('"DialoguePresentationCoordinator"') < bootstrap.indexOf('"LobbyService"')));
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase175:selfcheck")));
  checks.push(check("package dialogue presentation script exists", packageJson.includes("london:dialogue-presentation-contract")));
  checks.push(check("roadmap records phase 175", roadmap.includes("Phase 175: Dialogue Presentation Contract Foundation")));
  checks.push(check("tasks records phase 175", tasks.includes("Phase 175: Dialogue Presentation Contract Foundation")));
  checks.push(check("engine records phase 175", engine.includes("Phase 175: Dialogue Presentation Contract Foundation")));
  checks.push(check("master context records phase 175", context.includes("Phase 175: Dialogue Presentation Contract Foundation")));
  checks.push(check("governance contract exists", governance.includes("Dialogue Presentation Contract Foundation")));
  checks.push(check("governance provider exists", governance.includes('"dialogueRuntimePresentationContract"')));

  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-175");
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
    "# Phase 175 Runtime Evidence",
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
    "Phase 175 is Production Candidate. Authoritative Roblox Studio runtime evidence has not been imported.",
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
