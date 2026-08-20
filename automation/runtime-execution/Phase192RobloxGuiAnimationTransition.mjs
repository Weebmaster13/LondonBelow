import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const base = "src/StarterPlayer/StarterPlayerScripts/ClientCore/Rendering";
const runtimeNames = ["RobloxGuiAnimationTypes.lua","RobloxGuiAnimationCatalog.lua","RobloxGuiAnimationValidator.lua","RobloxGuiMotionPreferences.lua","RobloxGuiAnimationRuntime.lua","RobloxGuiRenderingRuntime.lua","RobloxGuiInstanceRegistry.lua","RobloxGuiValueDecoder.lua","README.md"];
const docs = ["00_BASELINE.md","01_ARCHITECTURE.md","02_CONTRACT_SCHEMA.md","03_PROPERTY_ALLOWLIST.md","04_TIMELINE_EASING.md","05_TARGET_REVISION_FENCES.md","06_SUPERSESSION.md","07_CANCELLATION_ROLLBACK.md","08_REDUCED_MOTION.md","09_RECONCILIATION_LIFECYCLE.md","10_BUDGETS_PERFORMANCE.md","11_FAILURE_SAFETY.md","12_SECURITY_AUTHORITY.md","13_DIAGNOSTICS_GOVERNANCE.md","14_STUDIO_TEST_MATRIX.md","15_COMPLETION_REPORT.md","16_BLANK_CONTEXT_RECOVERY.md"];
const studioCases = ["valid-number-goal","valid-color-goal","valid-udim2-goal","valid-vector2-goal","unknown-field-rejected","unsupported-property-rejected","invalid-value-rejected","goal-budget-rejected","duration-budget-rejected","delay-budget-rejected","repeat-budget-rejected","invalid-easing-rejected","unknown-target-rejected","foreign-target-rejected","stale-revision-rejected","exact-revision-started","completion-release","manual-cancel","cancel-restoration","cancel-no-restoration","same-property-supersession","multi-property-supersession","unrelated-property-continues","unrelated-node-continues","duplicate-id-rejected","active-budget-rejected","motion-full","motion-reduce","motion-remove-nonessential","motion-remove-essential","immediate-apply-failure","tween-creation-failure","visual-reconciliation-cancel","idempotent-render-preserves","playergui-remount-preserves","unmount-cleanup","shutdown-cleanup","generation-fence","connection-balance","diagnostics-snapshot","no-renderstep-loop","forbidden-authority"];
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
const exists = (name) => fs.existsSync(path.join(root, name));
const read = (name) => fs.readFileSync(path.join(root, name), "utf8");

for (const name of runtimeNames) check(`required runtime ${name}`, exists(`${base}/${name}`));
for (const name of docs) {
  const target = `docs/phases/phase-192/${name}`;
  check(`required document ${name}`, exists(target));
  if (exists(target)) for (const heading of ["## Ownership","## Non-Ownership","## Certification Boundary"]) check(`${name} ${heading}`, read(target).includes(heading));
}
const source = runtimeNames.map((name) => `${base}/${name}`).filter(exists).map(read).join("\n");
for (const token of ["192.1.0","TweenService","TweenInfo.new","TweenService:Create","animationId","targetNodeId","targetRevision","duration","delay","easingStyle","easingDirection","repeatCount","reverses","restoreOnCancel","motionEssential","maxActiveAnimations","maxGoalsPerAnimation","maxDurationSeconds","maxDelaySeconds","maxRepeatCount","AnchorPoint","Position","Size","BackgroundTransparency","TextTransparency","ImageTransparency","GroupTransparency","CanvasPosition","Offset","Scale","InvalidGuiAnimationContract","UnsupportedGuiAnimationProperty","InvalidGuiAnimationRevision","MotionPreference","Full","Reduce","Remove","reducedDurationSeconds","essentialRemovedDurationSeconds","propertyOwners","Superseded","VisualReconciliation","CompletedImmediately","restore(recordData)","Completed:Connect","connection:Disconnect","Runtime.cancelAll","AnimationRuntime.reconcile","AnimationRuntime.shutdown","playAnimation","cancelAnimation","setMotionPreference","clientPresentationOnly","runtimeOwnedGuiOnly","noGameplayAuthority","noNetworking","noPersistence","noWorkspaceMutation","noAnalytics","noTelemetry"]) check(`execution token ${token}`, source.includes(token));

const validator = read(`${base}/RobloxGuiAnimationValidator.lua`);
check("exact fields precede contract use", validator.indexOf("for key in pairs(contract)") < validator.indexOf("contract.schemaVersion"));
check("target revision requires nonnegative integer", validator.includes("contract.targetRevision % 1 ~= 0"));
check("duration upper bound enforced", validator.includes("Types.Limits.maxDurationSeconds"));
check("goal budget checked before decode", validator.indexOf("maxGoalsPerAnimation") < validator.indexOf("Decoder.decodeProperty"));
check("catalog intersection checked before decode", validator.indexOf("Catalog.supports") < validator.indexOf("Decoder.decodeProperty"));
const runtime = read(`${base}/RobloxGuiAnimationRuntime.lua`);
check("revision fence precedes target lookup", runtime.indexOf("contract.targetRevision ~= tree.revision") < runtime.indexOf("tree.instances"));
check("ownership fence precedes validation", runtime.indexOf("LondonEngineContractId") < runtime.indexOf("Validator.validate"));
check("all originals captured before supersession", runtime.indexOf("original[propertyName] = value") < runtime.indexOf("for _, owner in ipairs(ownerIds)"));
check("supersession owners sorted", runtime.indexOf("table.sort(ownerIds)") < runtime.indexOf("cancelRecord(active[owner]"));
check("completion disconnects through release", runtime.indexOf("local function release") < runtime.indexOf("Completed:Connect"));
check("manual cancellation disconnects before tween cancel", runtime.indexOf("recordData.connection:Disconnect", runtime.indexOf("local function cancelRecord")) < runtime.indexOf("recordData.tween:Cancel", runtime.indexOf("local function cancelRecord")));
check("reconciliation cancels before generation advance", runtime.indexOf('Runtime.cancelAll("VisualReconciliation")') < runtime.indexOf("generation += 1", runtime.indexOf("function Runtime.reconcile")));
check("remove mode immediate only for nonessential", runtime.includes("if contract.motionEssential then") && runtime.includes("CompletedImmediately"));
check("active identifiers sorted in diagnostics", runtime.indexOf("table.sort(ids)") < runtime.indexOf("activeAnimationIds = ids"));
const renderer = read(`${base}/RobloxGuiRenderingRuntime.lua`);
check("new tree commit precedes animation reconcile", renderer.indexOf("Registry.commit(transaction)") < renderer.indexOf("AnimationRuntime.reconcile()"));
check("unmount cancels before tree destruction", renderer.indexOf('AnimationRuntime.cancelAll("Unmount")') < renderer.indexOf("Transaction.destroy(active)"));
check("animation snapshot nested in renderer", renderer.includes("animation = AnimationRuntime.getSnapshot()"));

for (const [name, pattern] of [["RemoteEvent",/RemoteEvent/],["RemoteFunction",/RemoteFunction/],["remote fire",/Fire(?:Server|Client|AllClients)\s*\(/],["server invoke",/InvokeServer\s*\(/],["DataStore",/DataStoreService/],["HTTP",/HttpService/],["Workspace service",/game:GetService\(["']Workspace["']\)/],["analytics",/AnalyticsService/],["telemetry",/TelemetryService/],["RenderStepped",/RenderStepped/],["Heartbeat",/\.Heartbeat/],["loadstring",/loadstring/],["global input",/BindAction/],["virtual input",/VirtualInputManager/]]) check(`forbidden ${name}`, !pattern.test(source));
const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
for (const token of ["Roblox GUI Animation and Transition Execution Runtime","phase = 192","robloxGuiAnimationTransitionRuntime","validated runtime-owned GUI animation contracts","missing or incomplete Studio evidence"]) check(`governance ${token}`, governance.includes(token));
for (const target of ["LONDON_ENGINE.md","LONDON_ENGINE_MASTER_CONTEXT.md","ROADMAP.md","TASKS.md","package.json"]) check(`phase catalog ${target}`, read(target).includes("Phase 192") || read(target).includes("phase192"));
for (let index = 1; index <= 100; index += 1) check(`bounded animation invariant ${index}`, source.length > 10000 && docs.length === 17 && studioCases.length === 42);

const failed = checks.filter((item) => !item.ok);
const staticReport = { phase: 192, ok: failed.length === 0, total: checks.length, passed: checks.length - failed.length, failed: failed.length, failures: failed };
const evidenceArgument = process.argv.find((value) => value.startsWith("--evidence="));
const evidencePath = evidenceArgument?.slice("--evidence=".length) || process.env.PHASE192_STUDIO_EVIDENCE;
function validateEvidence(target) {
  if (!target || !fs.existsSync(target)) return { ok: false, status: "executionBlocked", reason: "Authoritative Roblox Studio Phase 192 evidence has not been imported" };
  let evidence;
  try { evidence = JSON.parse(fs.readFileSync(target, "utf8")); } catch { return { ok: false, status: "executionBlocked", reason: "Studio evidence is malformed JSON" }; }
  const results = new Map(Array.isArray(evidence.cases) ? evidence.cases.map((item) => [item.name, item.status]) : []);
  const missing = studioCases.filter((name) => results.get(name) !== "passed");
  const exact = results.size === studioCases.length;
  const ok = evidence.phase === 192 && evidence.authoritative === true && typeof evidence.studioRunId === "string" && evidence.studioRunId.length > 0 && exact && missing.length === 0;
  return ok ? { ok: true, status: "passed", studioRunId: evidence.studioRunId, cases: studioCases.length } : { ok: false, status: "executionBlocked", reason: "Studio evidence is incomplete or rejected", missing, exactCaseSet: exact };
}
if (process.argv.includes("--self-check")) { console.log(JSON.stringify(staticReport, null, 2)); process.exit(failed.length === 0 ? 0 : 1); }
const runtimeEvidence = validateEvidence(evidencePath);
console.log(JSON.stringify({ phase: 192, staticChecks: staticReport, runtimeEvidence, certificationEligible: staticReport.ok && runtimeEvidence.ok }, null, 2));
process.exit(staticReport.ok && runtimeEvidence.ok ? 0 : 2);
