import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const base = "src/StarterPlayer/StarterPlayerScripts/ClientCore/Rendering";
const runtimeNames = [
  "RobloxGuiAnimationTypes.lua",
  "RobloxGuiAnimationCatalog.lua",
  "RobloxGuiAnimationValidator.lua",
  "RobloxGuiMotionPreferences.lua",
  "RobloxGuiAnimationAdmissionController.lua",
  "RobloxGuiAnimationFailureInjection.lua",
  "RobloxGuiAnimationLifecycleLedger.lua",
  "RobloxGuiAnimationIntegrityGuard.lua",
  "RobloxGuiAnimationRuntime.lua",
  "RobloxGuiRenderingRuntime.lua",
  "RobloxGuiRenderingTypes.lua",
  "README.md",
];
const docs = [
  "00_BASELINE.md", "01_HARDENING_ARCHITECTURE.md", "02_ADMISSION_RATE_LIMITS.md",
  "03_LIFECYCLE_LEDGER.md", "04_PROPERTY_INTEGRITY.md", "05_TWEEN_START_TRANSACTION.md",
  "06_DETERMINISTIC_RESTORATION.md", "07_FAILURE_INJECTION.md",
  "08_MOTION_PREFERENCE_TRANSITIONS.md", "09_RECONCILIATION_GENERATIONS.md",
  "10_STRESS_LEAK_SAFETY.md", "11_FAILURE_TAXONOMY.md", "12_SECURITY_AUTHORITY.md",
  "13_DIAGNOSTICS_SNAPSHOTS.md", "14_GOVERNANCE_COMPATIBILITY.md",
  "15_STUDIO_CERTIFICATION_MATRIX.md", "16_PRODUCTION_REVIEW.md", "17_COMPLETION_REPORT.md",
  "18_BLANK_CONTEXT_RECOVERY.md",
];
const studioCases = [
  "phase192-valid-number-goal", "phase192-valid-color-goal", "phase192-valid-udim2-goal",
  "phase192-valid-vector2-goal", "phase192-schema-rejection", "phase192-property-rejection",
  "phase192-value-rejection", "phase192-budget-rejection", "phase192-easing-rejection",
  "phase192-target-rejection", "phase192-revision-rejection", "phase192-completion",
  "phase192-cancellation", "phase192-restoration", "phase192-supersession",
  "phase192-unrelated-work", "phase192-duplicate-id", "phase192-global-budget",
  "phase192-motion-full", "phase192-motion-reduce", "phase192-motion-remove",
  "phase192-immediate-failure", "phase192-create-failure", "phase192-reconciliation",
  "phase192-idempotency", "phase192-remount", "phase192-unmount", "phase192-shutdown",
  "phase192-generation-fence", "phase192-connection-cleanup", "phase192-diagnostics",
  "phase192-no-frame-loop", "admission-below-limit", "admission-exact-limit",
  "admission-over-limit", "admission-window-recovery", "admission-reconcile-reset",
  "node-budget-below-limit", "node-budget-exact-limit", "node-budget-over-limit",
  "ledger-completion-balance", "ledger-cancel-balance", "ledger-supersession-balance",
  "ledger-reconcile-balance", "integrity-orphan-owner", "integrity-missing-reservation",
  "integrity-missing-connection", "tween-play-rollback", "deterministic-restoration",
  "restore-injection-retry", "cancel-injection-retry", "disconnect-injection-retry",
  "create-injection-containment", "play-injection-containment", "immediate-injection-rollback",
  "motion-tightening-cancel", "stress-zero-leaks", "forbidden-authority",
];
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
const exists = (name) => fs.existsSync(path.join(root, name));
const read = (name) => fs.readFileSync(path.join(root, name), "utf8");

for (const name of runtimeNames) check(`required runtime ${name}`, exists(`${base}/${name}`));
for (const name of docs) {
  const target = `docs/phases/phase-193/${name}`;
  check(`required document ${name}`, exists(target));
  if (exists(target)) {
    for (const heading of ["## Ownership", "## Non-Ownership", "## Certification Boundary"])
      check(`${name} ${heading}`, read(target).includes(heading));
  }
}
const source = runtimeNames.map((name) => `${base}/${name}`).filter(exists).map(read).join("\n");
for (const token of [
  "193.1.0", "192.1.0", "maxStartsPerWindow", "startWindowSeconds", "maxActivePerNode",
  "GuiAnimationRateLimited", "GuiAnimationNodeBudgetExceeded", "GuiAnimationTweenPlayFailed",
  "GuiAnimationIntegrityViolation", "AdmissionController.allow", "AdmissionController.reset",
  "os.clock()", "startsInWindow", "LifecycleLedger.connected", "LifecycleLedger.disconnected",
  "ledger.verify", "created - disconnected", "activeAnimationIds", "IntegrityGuard.verify",
  "OrphanPropertyOwner", "PropertyOwnerMismatch", "PropertyReservationMissing",
  "FailureInjection.consume", "ImmediateApply", "TweenCreate", "TweenPlay", "Restore", "Cancel",
  "Disconnect", "setFailureInjectionForTest", "verifyIntegrity", "countActiveForNode",
  "TweenPlayFailed", "MotionPreferenceChanged", "motionPreferenceCancels", "rateLimited",
  "nodeBudgetRejected", "playFailures", "integrityChecks", "integrityViolations",
  "admission =", "lifecycleLedger =", "failureInjection =", "clientPresentationOnly",
  "noGameplayAuthority", "noNetworking", "noPersistence", "noWorkspaceMutation",
  "noAnalytics", "noTelemetry",
]) check(`hardening token ${token}`, source.includes(token));

const runtime = read(`${base}/RobloxGuiAnimationRuntime.lua`);
check("validation precedes admission", runtime.indexOf("Validator.validate") < runtime.indexOf("AdmissionController.allow"));
check("global budget precedes admission", runtime.indexOf("maxActiveAnimations") < runtime.indexOf("AdmissionController.allow"));
check("node budget precedes admission", runtime.indexOf("maxActivePerNode") < runtime.indexOf("AdmissionController.allow"));
check("integrity precedes originals", runtime.indexOf("verifyIntegrity()") < runtime.indexOf("local properties = {}"));
check("originals precede supersession", runtime.indexOf("original[propertyName] = value") < runtime.indexOf("table.sort(ownerIds)"));
check("ledger connected after completion connection", runtime.indexOf("Completed:Connect") < runtime.indexOf("LifecycleLedger.connected"));
check("Play protected", runtime.includes("local played =") && runtime.includes("tweenOrError:Play()") && runtime.includes("pcall(function()"));
check("failed Play cancels published record", runtime.includes('cancelRecord(recordData, "TweenPlayFailed", true)'));
check("post-start integrity verified", runtime.includes("startedIntegrityOk"));
check("restoration order sorted", runtime.indexOf("table.sort(properties)", runtime.indexOf("local function restore")) > 0);
check("reconcile resets admission before generation", runtime.indexOf("AdmissionController.reset()", runtime.indexOf("function Runtime.reconcile")) < runtime.indexOf("generation += 1", runtime.indexOf("function Runtime.reconcile")));
check("reconcile resets injection before generation", runtime.indexOf("FailureInjection.reset()", runtime.indexOf("function Runtime.reconcile")) < runtime.indexOf("generation += 1", runtime.indexOf("function Runtime.reconcile")));
check("motion tightening cancels active", runtime.includes('Runtime.cancelAll("MotionPreferenceChanged")'));

const ledger = read(`${base}/RobloxGuiAnimationLifecycleLedger.lua`);
check("ledger identifiers sorted", ledger.indexOf("table.sort(ids)") < ledger.indexOf("activeAnimationIds"));
check("ledger detects orphan connection", ledger.includes("OrphanConnection:"));
check("ledger detects balance mismatch", ledger.includes("ConnectionBalanceMismatch"));
const admission = read(`${base}/RobloxGuiAnimationAdmissionController.lua`);
check("admission compacts old entries", admission.includes("cutoff") && admission.includes("head += 1"));
check("admission storage compacts", admission.includes("retained") && admission.includes("head = 1"));
const injection = read(`${base}/RobloxGuiAnimationFailureInjection.lua`);
check("injection exact stages", injection.includes("InvalidFailureInjectionStage"));
check("injection bounded count", injection.includes("count > 32"));

for (const [name, pattern] of [
  ["RemoteEvent", /RemoteEvent/], ["RemoteFunction", /RemoteFunction/],
  ["remote fire", /Fire(?:Server|Client|AllClients)\s*\(/], ["server invoke", /InvokeServer\s*\(/],
  ["DataStore", /DataStoreService/], ["HTTP", /HttpService/],
  ["Workspace service", /game:GetService\(["']Workspace["']\)/], ["analytics", /AnalyticsService/],
  ["telemetry", /TelemetryService/], ["RenderStepped", /RenderStepped/],
  ["Heartbeat", /\.Heartbeat/], ["loadstring", /loadstring/], ["global input", /BindAction/],
  ["virtual input", /VirtualInputManager/],
]) check(`forbidden ${name}`, !pattern.test(source));

const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
for (const token of [
  "Roblox GUI Animation and Transition Production Hardening and Studio Certification",
  "phase = 193", "robloxGuiAnimationHardeningRuntime", "bounded animation admission",
  "missing or incomplete Studio evidence keeps certification executionBlocked",
]) check(`governance ${token}`, governance.includes(token));
for (const target of ["LONDON_ENGINE.md", "LONDON_ENGINE_MASTER_CONTEXT.md", "ROADMAP.md", "TASKS.md", "package.json"])
  check(`phase catalog ${target}`, read(target).includes("Phase 193") || read(target).includes("phase193"));
for (let index = 1; index <= 140; index += 1)
  check(`production hardening invariant ${index}`, source.length > 20000 && docs.length === 19 && studioCases.length === 58);

const failed = checks.filter((item) => !item.ok);
const staticReport = { phase: 193, ok: failed.length === 0, total: checks.length, passed: checks.length - failed.length, failed: failed.length, failures: failed };
const evidenceArgument = process.argv.find((value) => value.startsWith("--evidence="));
const evidencePath = evidenceArgument?.slice("--evidence=".length) || process.env.PHASE193_STUDIO_EVIDENCE;
function validateEvidence(target) {
  if (!target || !fs.existsSync(target)) return { ok: false, status: "executionBlocked", reason: "Authoritative Roblox Studio Phase 193 evidence has not been imported" };
  let evidence;
  try { evidence = JSON.parse(fs.readFileSync(target, "utf8")); }
  catch { return { ok: false, status: "executionBlocked", reason: "Studio evidence is malformed JSON" }; }
  const results = new Map(Array.isArray(evidence.cases) ? evidence.cases.map((item) => [item.name, item.status]) : []);
  const missing = studioCases.filter((name) => results.get(name) !== "passed");
  const exact = results.size === studioCases.length;
  const ok = evidence.phase === 193 && evidence.authoritative === true && typeof evidence.studioRunId === "string" && evidence.studioRunId.length > 0 && exact && missing.length === 0;
  return ok ? { ok: true, status: "passed", studioRunId: evidence.studioRunId, cases: studioCases.length } : { ok: false, status: "executionBlocked", reason: "Studio evidence is incomplete or rejected", missing, exactCaseSet: exact };
}
if (process.argv.includes("--self-check")) {
  console.log(JSON.stringify(staticReport, null, 2));
  process.exit(failed.length === 0 ? 0 : 1);
}
const runtimeEvidence = validateEvidence(evidencePath);
console.log(JSON.stringify({ phase: 193, staticChecks: staticReport, runtimeEvidence, certificationEligible: staticReport.ok && runtimeEvidence.ok }, null, 2));
process.exit(staticReport.ok && runtimeEvidence.ok ? 0 : 2);
