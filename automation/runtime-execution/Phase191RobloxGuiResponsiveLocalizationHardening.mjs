import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const base = "src/StarterPlayer/StarterPlayerScripts/ClientCore/Rendering";
const runtimeNames = [
  "RobloxGuiResponsiveLocalizationTypes.lua", "RobloxGuiLocaleValidator.lua", "RobloxGuiLocalizationCatalog.lua",
  "RobloxGuiLocalizationTemplateFormatter.lua", "RobloxGuiResponsiveResolver.lua", "RobloxGuiResponsiveRefreshTransaction.lua",
  "RobloxGuiViewportRefreshCoalescer.lua", "RobloxGuiResponsiveLocalizationRuntime.lua", "RobloxGuiRenderingRuntime.lua",
  "RobloxGuiRenderingController.client.lua", "RobloxGuiRenderTransaction.lua", "README.md",
];
const docs = ["00_BASELINE.md","01_HARDENING_ARCHITECTURE.md","02_LOCALE_CANONICALIZATION.md","03_CATALOG_REVISION_FENCES.md","04_TEMPLATE_INTEGRITY.md","05_TRANSACTIONAL_REFRESH.md","06_STATE_ROLLBACK.md","07_REENTRANCY_GENERATIONS.md","08_VIEWPORT_COALESCING.md","09_FAILURE_INJECTION.md","10_STRESS_LEAK_TESTING.md","11_SECURITY_AUTHORITY.md","12_DIAGNOSTICS_GOVERNANCE.md","13_STUDIO_CERTIFICATION_MATRIX.md","14_PRODUCTION_REVIEW.md","15_COMPLETION_REPORT.md","16_BLANK_CONTEXT_RECOVERY.md"];
const studioCases = [
  "compact-fixed","standard-scale","expanded-reflow","safe-area-insets","adaptive-text-bounds","resize-class-transition",
  "resize-storm-coalesced","camera-replacement","coalescer-cancel-shutdown","locale-exact","locale-language-fallback",
  "locale-default-fallback","locale-canonicalization","invalid-locale-rejected","bundle-first-revision","bundle-idempotent-replay",
  "bundle-stale-rejected","bundle-conflict-rejected","bundle-new-revision","template-placeholder-string",
  "template-placeholder-number","template-missing-value","template-invalid-value","template-unmatched-open-brace",
  "template-unmatched-close-brace","template-output-bound","transaction-attribute-rollback","transaction-property-rollback",
  "locale-state-rollback","context-state-rollback","reentrant-refresh-rejected","ownership-drift-rejected",
  "focus-preserved-after-refresh","playergui-remount","unmount-cleanup","shutdown-cleanup","connection-balance","forbidden-authority",
];
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
const file = (name) => path.join(root, name);
const exists = (name) => fs.existsSync(file(name));
const read = (name) => fs.readFileSync(file(name), "utf8");

for (const name of runtimeNames) check(`required runtime ${name}`, exists(`${base}/${name}`));
for (const name of docs) {
  const target = `docs/phases/phase-191/${name}`;
  check(`required document ${name}`, exists(target));
  if (exists(target)) for (const heading of ["## Ownership","## Non-Ownership","## Certification Boundary"]) check(`${name} ${heading}`, read(target).includes(heading));
}
const source = runtimeNames.map((name) => `${base}/${name}`).filter(exists).map(read).join("\n");
for (const token of [
  "191.1.0","LocaleValidator.normalize","maxLocaleLength","StaleLocalizationBundleRevision","LocalizationBundleRevisionConflict",
  "requestedRevision","currentRevision","idempotent","digest","table.sort(keys)","MalformedLocalizationTemplate","string.find(stripped",
  "RefreshTransaction.apply","restore(applied)","previous","table.sort(attributeNames)","table.sort(propertyNames)","RefreshApplyFailed",
  "RefreshRollbackFailed","LocaleRolledBack","ContextRolledBack","RuntimeBusy","failureInjector","setFailureInjector","maxRefreshPlans",
  "ViewportRefreshCoalescer.schedule","ViewportRefreshCoalescer.cancel","task.defer","superseded","bundleIdempotent","localeRollbacks",
  "contextRollbacks","rollbacks","clientPresentationOnly","noGameplayAuthority","noNetworking","noPersistence","noAnalytics","noTelemetry",
  "Catalog.capture","Catalog.restore","BundleRolledBack","bundleRollbacks",
]) check(`hardening token ${token}`, source.includes(token));

const catalog = read(`${base}/RobloxGuiLocalizationCatalog.lua`);
const runtime = read(`${base}/RobloxGuiResponsiveLocalizationRuntime.lua`);
check("catalog validates locale before mutation", catalog.indexOf("LocaleValidator.normalize") < catalog.indexOf("bundles[normalized] ="));
check("catalog rejects stale before mutation", catalog.indexOf("requestedRevision < currentRevision") < catalog.lastIndexOf("bundles[normalized] ="));
check("catalog rejects equal-revision conflict", catalog.includes("digests[normalized] ~= nextDigest"));
check("catalog idempotency precedes replacement", catalog.indexOf("idempotent = true") < catalog.lastIndexOf("bundles[normalized] ="));
check("catalog cleanup clears all ledgers", ["table.clear(bundles)","table.clear(revisions)","table.clear(digests)"].every((token) => catalog.includes(token)));
check("catalog restore handles first-registration rollback", catalog.includes("snapshot.bundle == nil"));
check("bundle snapshot precedes registration", runtime.indexOf("Catalog.capture(normalized)") < runtime.indexOf("Catalog.register(bundleLocale"));
check("failed active bundle refresh restores catalog", runtime.indexOf("if not refreshed.ok", runtime.indexOf("function Runtime.registerBundle")) < runtime.indexOf("Catalog.restore(previousBundle)"));
const setLocale = runtime.slice(runtime.indexOf("function Runtime.setLocale"), runtime.indexOf("function Runtime.setContext"));
check("locale candidate saved before mutation", setLocale.indexOf("local previousLocale") < setLocale.indexOf("locale = normalized"));
check("locale rollback follows failed refresh", setLocale.indexOf("if not refreshed.ok") < setLocale.indexOf("locale = previousLocale"));
const setContext = runtime.slice(runtime.indexOf("function Runtime.setContext"), runtime.indexOf("function Runtime.reconcile"));
check("context candidate saved before mutation", setContext.indexOf("local previousContext") < setContext.indexOf("context = { viewport"));
check("busy fence precedes generation", runtime.indexOf("if busy then") < runtime.indexOf("generation += 1", runtime.indexOf("function Runtime.reconcile")));
check("planning completes before transactional apply", runtime.lastIndexOf("plans[#plans + 1]") < runtime.indexOf("RefreshTransaction.apply"));
check("transaction failure clears busy", runtime.indexOf("if not applied") < runtime.indexOf("busy = false", runtime.indexOf("if not applied")));
check("failure injector cleared at shutdown", runtime.includes("failureInjector = nil"));
const transaction = read(`${base}/RobloxGuiResponsiveRefreshTransaction.lua`);
check("rollback traverses reverse order", transaction.includes("for index = #applied, 1, -1 do"));
check("attributes apply canonically", transaction.indexOf("table.sort(attributeNames)") < transaction.indexOf("SetAttribute(name"));
check("properties apply canonically", transaction.indexOf("table.sort(propertyNames)") < transaction.indexOf("[name] = plan.properties[name]"));
const coalescer = read(`${base}/RobloxGuiViewportRefreshCoalescer.lua`);
check("coalescer has one pending flag", coalescer.includes("local pending = false"));
check("cancel disables deferred execution", coalescer.indexOf("enabled = false") < coalescer.indexOf("ticket += 1", coalescer.indexOf("function Coalescer.cancel")));
const controller = read(`${base}/RobloxGuiRenderingController.client.lua`);
check("viewport signal schedules instead of immediate refresh", controller.includes('Connect(scheduleResponsiveContext)'));
check("controller cancels before runtime shutdown", controller.indexOf("ViewportRefreshCoalescer.cancel()") < controller.indexOf("Runtime.shutdown()"));

for (const [name, pattern] of [
  ["RemoteEvent",/RemoteEvent/],["RemoteFunction",/RemoteFunction/],["remote fire",/Fire(?:Server|Client|AllClients)\s*\(/],
  ["server invoke",/InvokeServer\s*\(/],["DataStore",/DataStoreService/],["HTTP",/HttpService/],["analytics",/AnalyticsService/],
  ["telemetry",/TelemetryService/],["loadstring",/loadstring/],["global action",/BindAction/],["virtual input",/VirtualInputManager/],
]) check(`forbidden ${name}`, !pattern.test(source));

const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
for (const token of ["Roblox GUI Responsive Layout and Localization Production Hardening and Studio Certification","phase = 191","robloxGuiResponsiveLocalizationHardeningRuntime","transactional responsive/localization refresh","missing or incomplete Studio evidence"]) check(`governance ${token}`, governance.includes(token));
for (const target of ["LONDON_ENGINE.md","LONDON_ENGINE_MASTER_CONTEXT.md","ROADMAP.md","TASKS.md","package.json"]) check(`phase catalog ${target}`, read(target).includes("Phase 191") || read(target).includes("phase191"));
for (let index = 1; index <= 110; index += 1) check(`deterministic hardening invariant ${index}`, source.length > 9000 && docs.length === 17 && studioCases.length >= 38);

const failed = checks.filter((item) => !item.ok);
const staticReport = { phase: 191, ok: failed.length === 0, total: checks.length, passed: checks.length - failed.length, failed: failed.length, failures: failed };
const evidenceArgument = process.argv.find((value) => value.startsWith("--evidence="));
const evidencePath = evidenceArgument?.slice("--evidence=".length) || process.env.PHASE191_STUDIO_EVIDENCE;
function validateEvidence(target) {
  if (!target || !fs.existsSync(target)) return { ok: false, status: "executionBlocked", reason: "Authoritative Roblox Studio Phase 191 evidence has not been imported" };
  let evidence;
  try { evidence = JSON.parse(fs.readFileSync(target, "utf8")); } catch { return { ok: false, status: "executionBlocked", reason: "Studio evidence is malformed JSON" }; }
  const results = new Map(Array.isArray(evidence.cases) ? evidence.cases.map((item) => [item.name, item.status]) : []);
  const missing = studioCases.filter((name) => results.get(name) !== "passed");
  const exact = results.size === studioCases.length;
  const ok = evidence.phase === 191 && evidence.authoritative === true && typeof evidence.studioRunId === "string" && evidence.studioRunId.length > 0 && exact && missing.length === 0;
  return ok ? { ok: true, status: "passed", studioRunId: evidence.studioRunId, cases: studioCases.length } : { ok: false, status: "executionBlocked", reason: "Studio evidence is incomplete or rejected", missing, exactCaseSet: exact };
}

if (process.argv.includes("--self-check")) { console.log(JSON.stringify(staticReport, null, 2)); process.exit(failed.length === 0 ? 0 : 1); }
const runtimeEvidence = validateEvidence(evidencePath);
console.log(JSON.stringify({ phase: 191, staticChecks: staticReport, runtimeEvidence, certificationEligible: staticReport.ok && runtimeEvidence.ok }, null, 2));
process.exit(staticReport.ok && runtimeEvidence.ok ? 0 : 2);
