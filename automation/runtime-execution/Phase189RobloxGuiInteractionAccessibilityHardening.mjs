import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const base = "src/StarterPlayer/StarterPlayerScripts/ClientCore/Rendering";
const runtimeFiles = [
  "RobloxGuiInteractionTypes.lua", "RobloxGuiAccessibilityMetadata.lua", "RobloxGuiAccessibilityContractHardening.lua",
  "RobloxGuiAccessibilityPreferences.lua", "RobloxGuiFocusManager.lua", "RobloxGuiFocusScope.lua",
  "RobloxGuiInteractionConnectionLedger.lua", "RobloxGuiInteractionGenerationGuard.lua", "RobloxGuiReconciliationBudget.lua",
  "RobloxGuiInteractionRuntime.lua", "RobloxGuiRenderingValidator.lua", "RobloxGuiRenderingRuntime.lua",
  "RobloxGuiRenderingController.client.lua", "README.md",
].map((name) => `${base}/${name}`);
const documents = [
  "00_BASELINE.md", "01_HARDENING_ARCHITECTURE.md", "02_GENERATION_FENCING.md", "03_REENTRANCY.md",
  "04_CONNECTION_LEDGER.md", "05_MODAL_FOCUS_SCOPES.md", "06_ACCESSIBILITY_PREFERENCES.md",
  "07_LIVE_REGIONS.md", "08_RECONCILIATION_RATE_LIMIT.md", "09_PLAYERGUI_REMOUNT.md",
  "10_FAILURE_INJECTION.md", "11_STRESS_AND_LEAK_TESTING.md", "12_SECURITY_AUTHORITY.md",
  "13_DIAGNOSTICS_GOVERNANCE.md", "14_STUDIO_CERTIFICATION_MATRIX.md", "15_PRODUCTION_REVIEW.md",
  "16_COMPLETION_REPORT.md", "17_BLANK_CONTEXT_RECOVERY.md",
];
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
const exists = (file) => fs.existsSync(path.join(root, file));
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");

for (const file of runtimeFiles) check(`required runtime ${file}`, exists(file));
for (const doc of documents) {
  const file = `docs/phases/phase-189/${doc}`;
  check(`required document ${doc}`, exists(file));
  if (exists(file)) for (const heading of ["## Ownership", "## Non-Ownership", "## Certification Boundary"]) check(`${doc} ${heading}`, read(file).includes(heading));
}
const source = runtimeFiles.filter((file) => file.endsWith(".lua") && exists(file)).map(read).join("\n");
for (const token of [
  "189.1.0", "StaleActivation", "ReentrantActivation", "InvalidPreferences", "InvalidFocusScope", "FocusScopeBlocked", "RemountFailed",
  "ReconciliationRateExceeded", "ReconciliationPermitInvalid", "GenerationGuard.advance", "GenerationGuard.isCurrent", "GenerationGuard.enter",
  "ConnectionLedger.add", "ConnectionLedger.disconnectAll", "connectedTotal", "disconnectedTotal", "balanced",
  "FocusScope.resolve", "modal", "scopePriority", "initialFocus", "activeScopeId", "eligibleControlCount",
  "autoFocusMode", "PreserveOnly", "announceLiveRegions", "liveRegion", "LiveRegion", "Assertive",
  "ReconciliationBudget.consume", "maxReconciliationsPerWindow", "os.clock", "Runtime.remount",
  "player.ChildAdded", "child:IsA(\"PlayerGui\")", "playerGuiConnection:Disconnect",
]) check(`hardening token ${token}`, source.includes(token));
for (const [name, pattern] of [
  ["RemoteEvent", /RemoteEvent/], ["RemoteFunction", /RemoteFunction/], ["remote fire", /Fire(?:Server|Client|AllClients)\s*\(/],
  ["server invoke", /InvokeServer\s*\(/], ["DataStore", /DataStoreService/], ["HTTP", /HttpService/],
  ["Workspace service", /game:GetService\(["']Workspace["']\)/], ["analytics", /AnalyticsService/],
  ["telemetry", /TelemetryService/], ["global action binding", /BindAction/], ["virtual input", /VirtualInputManager/],
]) check(`forbidden ${name}`, !pattern.test(source));

const interaction = read(`${base}/RobloxGuiInteractionRuntime.lua`);
check("stale fence precedes disabled", interaction.indexOf("GenerationGuard.isCurrent") < interaction.indexOf("if control.disabled"));
check("disabled precedes action lookup", interaction.indexOf("if control.disabled") < interaction.indexOf("actions[control.actionId]"));
check("reentrancy enter precedes callback", interaction.indexOf("GenerationGuard.enter") < interaction.indexOf("pcall(callback"));
check("reentrancy released after callback", interaction.indexOf("pcall(callback") < interaction.lastIndexOf("GenerationGuard.leave"));
check("rate limit permit API exists", interaction.includes("function Runtime.beginReconcile"));
check("reconcile requires exact permit", interaction.includes("pendingReconcilePermit ~= permit"));
check("generation advances after disconnect", interaction.indexOf("disconnectControls()", interaction.indexOf("function Runtime.reconcile")) < interaction.indexOf("GenerationGuard.advance", interaction.indexOf("function Runtime.reconcile")));
check("scope resolves before focus restore", interaction.indexOf("FocusScope.resolve") < interaction.indexOf("FocusManager.restore"));
check("modal blocks outside selection", interaction.includes("control.instance.Selectable = false"));
check("modal blocks outside activation", interaction.includes("control.instance.Interactable = false"));
check("scope block checked before disabled", interaction.indexOf("if control.scopeBlocked") < interaction.indexOf("if control.disabled"));
check("ledger visible in diagnostics", interaction.includes("connectionLedger = ConnectionLedger.inspect()"));
check("budget visible in diagnostics", interaction.includes("reconciliationBudget = ReconciliationBudget.inspect()"));
check("hardening state reset on shutdown", ["ConnectionLedger.reset()", "GenerationGuard.reset()", "Preferences.reset()", "ReconciliationBudget.reset()"].every((token) => interaction.includes(token)));
const generationGuard = read(`${base}/RobloxGuiInteractionGenerationGuard.lua`);
const advanceBody = generationGuard.slice(generationGuard.indexOf("function Guard.advance"), generationGuard.indexOf("function Guard.isCurrent"));
check("generation advance preserves active action locks", !advanceBody.includes("table.clear(activeActions)"));
const ledger = read(`${base}/RobloxGuiInteractionConnectionLedger.lua`);
check("ledger retires auto-disconnected entries", ledger.indexOf("disconnected += 1") > ledger.indexOf("if connection.Connected"));
const preferences = read(`${base}/RobloxGuiAccessibilityPreferences.lua`);
check("false preferences preserved without boolean fallback bug", preferences.includes("local function choose") && preferences.includes("announceFocus = choose"));
const focus = read(`${base}/RobloxGuiFocusManager.lua`);
check("never mode denies focus mutation", focus.indexOf('autoFocusMode == "Never"') < focus.indexOf("GuiService.SelectedObject = preferred.instance"));
check("preserve only blocks fallback", focus.includes('autoFocusMode == "PreserveOnly"'));
check("initial focus precedes generic fallback", focus.indexOf("control.initialFocus") < focus.lastIndexOf("for _, control in ipairs(orderedControls)"));
const renderer = read(`${base}/RobloxGuiRenderingRuntime.lua`);
check("rate permit precedes transaction staging", renderer.indexOf("InteractionRuntime.beginReconcile") < renderer.indexOf("Transaction.stage"));
check("stage failure cancels permit", renderer.indexOf("InteractionRuntime.cancelReconcile") < renderer.indexOf("return fail(stageReason"));
check("renderer exposes remount", renderer.includes("function Runtime.remount"));
check("remount rejects busy", renderer.indexOf("function Runtime.remount") < renderer.indexOf("if busy", renderer.indexOf("function Runtime.remount")));
const validator = read(`${base}/RobloxGuiRenderingValidator.lua`);
check("contract hardening invoked", validator.includes("AccessibilityHardening.validate(contract)"));
const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
check("governance system", governance.includes("Roblox GUI Interaction and Accessibility Production Hardening and Studio Certification"));
check("governance provider", governance.includes("robloxGuiInteractionAccessibilityHardeningRuntime"));
for (const file of ["ROADMAP.md", "TASKS.md", "LONDON_ENGINE.md", "LONDON_ENGINE_MASTER_CONTEXT.md"]) check(`${file} phase 189`, read(file).includes("Phase 189: Roblox GUI Interaction and Accessibility Production Hardening and Studio Certification"));
const packageJson = read("package.json");
for (const token of ["london:phase189:selfcheck", "london:roblox-gui-interaction-hardening", "london:roblox-gui-interaction-hardening:validate"]) check(`package ${token}`, packageJson.includes(token));

const requiredStudioCases = [
  "mouse", "touch", "keyboard", "gamepad", "disabled", "unknown-action", "callback-failure", "reentrant-action",
  "stale-generation", "rapid-revision-120", "rapid-revision-rate-limit", "connection-balance", "modal-containment",
  "nested-modal-priority", "initial-focus", "preserve-only", "autofocus-never", "live-region-polite",
  "live-region-assertive", "preferences-rejection", "playergui-remount", "respawn-recovery", "unmount-cleanup",
  "shutdown-cleanup", "multiplayer-isolation", "low-end-budget",
];
const evidencePath = path.join(root, "automation/runtime-evidence/phase-189/studio-result.json");
let runtime = { status: "executionBlocked", executionBlocked: true, authoritative: false };
if (fs.existsSync(evidencePath)) {
  try {
    const evidence = JSON.parse(fs.readFileSync(evidencePath, "utf8"));
    const passed = new Set(Array.isArray(evidence.tests) ? evidence.tests.filter((test) => test?.passed === true).map((test) => test.id) : []);
    const valid = evidence.schemaVersion === 1 && evidence.phase === 189 && evidence.environment === "RobloxStudio" && evidence.authoritative === true && evidence.passed === true && typeof evidence.runId === "string" && evidence.runId.length > 0 && requiredStudioCases.every((id) => passed.has(id));
    runtime = valid ? { status: "passed", executionBlocked: false, authoritative: true, runId: evidence.runId, testCount: passed.size } : { status: "evidenceRejected", executionBlocked: true, authoritative: false };
  } catch { runtime = { status: "evidenceRejected", executionBlocked: true, authoritative: false }; }
}
const failures = checks.filter((item) => !item.ok);
const selfCheck = { phase: 189, ok: failures.length === 0, total: checks.length, passed: checks.length - failures.length, failed: failures.length, failures };
if (process.argv.includes("--runtime")) {
  const directory = path.join(root, "automation/runtime-evidence/phase-189");
  fs.mkdirSync(directory, { recursive: true });
  fs.writeFileSync(path.join(directory, "phase-189-runtime-report.md"), `# Phase 189 Runtime Evidence\n\nStatic checks: ${selfCheck.passed}/${selfCheck.total}\n\nRequired Studio cases: ${requiredStudioCases.length}\n\nRuntime: ${runtime.status}\n\nAuthoritative Roblox Studio evidence: ${runtime.authoritative ? "accepted" : "not imported"}\n`);
  console.log(JSON.stringify({ ok: selfCheck.ok && runtime.status === "passed", selfCheck, runtime }, null, 2));
  process.exit(selfCheck.ok && runtime.status === "passed" ? 0 : selfCheck.ok ? 2 : 1);
}
console.log(JSON.stringify(selfCheck, null, 2));
process.exit(selfCheck.ok ? 0 : 1);
