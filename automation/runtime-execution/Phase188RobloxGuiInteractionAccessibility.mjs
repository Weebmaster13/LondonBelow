import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const base = "src/StarterPlayer/StarterPlayerScripts/ClientCore/Rendering";
const runtimeFiles = [
  "RobloxGuiInteractionTypes.lua", "RobloxGuiAccessibilityMetadata.lua", "RobloxGuiFocusManager.lua",
  "RobloxGuiInteractionRuntime.lua", "RobloxGuiRenderingValidator.lua", "RobloxGuiRenderingRuntime.lua",
  "RobloxGuiRenderTransaction.lua", "RobloxGuiRenderingController.client.lua", "README.md",
].map((file) => `${base}/${file}`);
const docs = [
  "00_BASELINE.md", "01_ARCHITECTURE.md", "02_ACTION_REGISTRY.md", "03_INPUT_PARITY.md",
  "04_ACCESSIBILITY_METADATA.md", "05_FOCUS_NAVIGATION.md", "06_RECONCILIATION.md",
  "07_DISABLED_AND_FAILURE_SAFETY.md", "08_LIFECYCLE_AND_CLEANUP.md", "09_SECURITY_AUTHORITY.md",
  "10_DIAGNOSTICS_BUDGETS.md", "11_STUDIO_TEST_MATRIX.md", "12_PRODUCTION_REVIEW.md",
  "13_COMPLETION_REPORT.md", "14_BLANK_CONTEXT_RECOVERY.md",
];
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
const exists = (file) => fs.existsSync(path.join(root, file));
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");

for (const file of runtimeFiles) check(`required runtime file ${file}`, exists(file));
for (const doc of docs) {
  const file = `docs/phases/phase-188/${doc}`;
  check(`required document ${doc}`, exists(file));
  if (exists(file)) for (const heading of ["## Ownership", "## Non-Ownership", "## Certification Boundary"]) check(`${doc} ${heading}`, read(file).includes(heading));
}
const source = runtimeFiles.filter((file) => file.endsWith(".lua") && exists(file)).map(read).join("\n");
for (const token of [
  "188.1.0", "registerAction", "unregisterAction", "setAnnouncer", "GuiButton", "Activated:Connect",
  "SelectionGained", "SelectionOrder", "Selectable", "Interactable", "DisabledControl", "UnknownAction",
  "CallbackFailed", "captureFocus", "restore", "SelectedObject", "LondonEngineActionId",
  "LondonEngineAccessibilityDescription", "inputAgnosticActivation", "clientPresentationOnly",
  "connectionsDisconnected", "table.clear(actions)", "InteractionRuntime.reconcile",
]) check(`implementation token ${token}`, source.includes(token));
for (const [name, pattern] of [
  ["RemoteEvent", /RemoteEvent/], ["RemoteFunction", /RemoteFunction/],
  ["remote send", /Fire(?:Server|Client|AllClients)\s*\(/], ["invoke server", /InvokeServer\s*\(/],
  ["DataStore", /DataStoreService/], ["HTTP", /HttpService/],
  ["Workspace service", /game:GetService\(["']Workspace["']\)/], ["analytics", /AnalyticsService/],
  ["telemetry", /TelemetryService/], ["ContextAction binding", /BindAction/],
]) check(`forbidden surface ${name}`, !pattern.test(source));
const validator = read(`${base}/RobloxGuiRenderingValidator.lua`);
check("metadata validation before staging boundary", validator.includes("AccessibilityMetadata.validate"));
check("focusable control budget enforced", validator.includes("InteractionTypes.Limits.maxControls"));
const rendering = read(`${base}/RobloxGuiRenderingRuntime.lua`);
check("focus captured before commit", rendering.indexOf("InteractionRuntime.captureFocus") < rendering.indexOf("Transaction.commit"));
check("interaction reconcile after registry commit", rendering.indexOf("Registry.commit") < rendering.indexOf("InteractionRuntime.reconcile"));
check("interaction unmount before instance destruction", rendering.indexOf("InteractionRuntime.unmount") < rendering.indexOf("Transaction.destroy"));
const interaction = read(`${base}/RobloxGuiInteractionRuntime.lua`);
check("disabled checked before action lookup", interaction.indexOf("if control.disabled") < interaction.indexOf("actions[control.actionId]"));
check("callback protected", interaction.includes("pcall(callback, context)"));
check("connections disconnected", interaction.includes("connection:Disconnect()"));
check("actions cleared on shutdown", interaction.indexOf("table.clear(actions)") < interaction.indexOf("state = Types.RuntimeState.Shutdown"));
const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
check("governance system", governance.includes("Roblox GUI Interaction and Accessibility Execution Runtime"));
check("governance provider", governance.includes("robloxGuiInteractionAccessibilityRuntime"));
for (const file of ["ROADMAP.md", "TASKS.md", "LONDON_ENGINE.md", "LONDON_ENGINE_MASTER_CONTEXT.md"]) check(`${file} phase 188`, read(file).includes("Phase 188: Roblox GUI Interaction and Accessibility Execution Runtime"));
const packageJson = read("package.json");
for (const token of ["london:phase188:selfcheck", "london:roblox-gui-interaction", "london:roblox-gui-interaction:validate"]) check(`package command ${token}`, packageJson.includes(token));

const evidencePath = path.join(root, "automation/runtime-evidence/phase-188/studio-result.json");
let runtime = { status: "executionBlocked", executionBlocked: true, authoritative: false };
if (fs.existsSync(evidencePath)) {
  try {
    const value = JSON.parse(fs.readFileSync(evidencePath, "utf8"));
    const requiredCases = ["mouse", "touch", "keyboard", "gamepad", "disabled", "unknown-action", "callback-failure", "focus-first-mount", "focus-revision-restore", "focus-missing-fallback", "unmount-cleanup", "shutdown-cleanup", "multiplayer-isolation", "low-end-budget"];
    const testIds = new Set(Array.isArray(value.tests) ? value.tests.filter((test) => test?.passed === true).map((test) => test.id) : []);
    const valid = value.schemaVersion === 1 && value.phase === 188 && value.environment === "RobloxStudio" && value.authoritative === true && value.passed === true && typeof value.runId === "string" && value.runId.length > 0 && requiredCases.every((id) => testIds.has(id));
    runtime = valid ? { status: "passed", executionBlocked: false, authoritative: true, runId: value.runId, testCount: testIds.size } : { status: "evidenceRejected", executionBlocked: true, authoritative: false };
  } catch { runtime = { status: "evidenceRejected", executionBlocked: true, authoritative: false }; }
}
const failed = checks.filter((item) => !item.ok);
const selfCheck = { phase: 188, ok: failed.length === 0, total: checks.length, passed: checks.length - failed.length, failed: failed.length, failures: failed };
if (process.argv.includes("--runtime")) {
  const directory = path.join(root, "automation/runtime-evidence/phase-188");
  fs.mkdirSync(directory, { recursive: true });
  fs.writeFileSync(path.join(directory, "phase-188-runtime-report.md"), `# Phase 188 Runtime Evidence\n\nStatic checks: ${selfCheck.passed}/${selfCheck.total}\n\nRuntime: ${runtime.status}\n\nAuthoritative Roblox Studio evidence: ${runtime.authoritative ? "accepted" : "not imported"}\n`);
  console.log(JSON.stringify({ ok: selfCheck.ok && runtime.status === "passed", selfCheck, runtime }, null, 2));
  process.exit(selfCheck.ok && runtime.status === "passed" ? 0 : selfCheck.ok ? 2 : 1);
}
console.log(JSON.stringify(selfCheck, null, 2));
process.exit(selfCheck.ok ? 0 : 1);
