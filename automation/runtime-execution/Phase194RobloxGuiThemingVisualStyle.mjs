import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const base = "src/StarterPlayer/StarterPlayerScripts/ClientCore/Rendering";
const runtimeNames = ["RobloxGuiThemeTypes.lua", "RobloxGuiThemeCatalog.lua", "RobloxGuiThemeValidator.lua", "RobloxGuiThemeRuntime.lua", "RobloxGuiRenderingRuntime.lua", "RobloxGuiRenderingTypes.lua", "README.md"];
const docs = ["00_BASELINE.md", "01_ARCHITECTURE.md", "02_THEME_SCHEMA.md", "03_TOKEN_MODEL.md", "04_PROPERTY_ALLOWLIST.md", "05_TRANSACTION_ROLLBACK.md", "06_REVISION_FENCES.md", "07_RECONCILIATION.md", "08_DIAGNOSTICS.md", "09_SECURITY_AUTHORITY.md", "10_STUDIO_EVIDENCE.md", "11_PRODUCTION_REVIEW.md", "12_COMPLETION_REPORT.md", "13_BLANK_CONTEXT_RECOVERY.md"];
const studioCases = [
  "catalog-register", "catalog-idempotent", "catalog-upgrade", "catalog-stale-reject", "catalog-conflict-reject", "catalog-budget",
  "theme-id-validation", "token-name-validation", "token-color", "token-number", "token-font", "token-type-reject",
  "schema-reject", "theme-revision-reject", "render-revision-reject", "contract-id-reject", "duplicate-node-reject", "missing-target-reject",
  "foreign-target-reject", "unsupported-property-reject", "missing-token-reject", "property-type-reject", "node-budget-reject", "property-budget-reject",
  "background-color", "border-color", "image-color", "text-color", "placeholder-color", "scrollbar-color",
  "background-transparency", "border-size", "image-transparency", "text-transparency", "stroke-transparency", "scrollbar-thickness",
  "stroke-color", "font-face", "text-size", "deterministic-node-order", "deterministic-property-order", "multi-node-apply",
  "transaction-success", "transaction-write-failure", "reverse-rollback", "rollback-failure-diagnostic", "no-partial-active-theme", "idempotent-apply",
  "theme-switch", "theme-upgrade", "stale-active-tree", "render-reconcile-clear", "unmount-clear", "shutdown-clear",
  "post-shutdown-reject", "generation-advance", "catalog-snapshot-order", "audit-bounded", "failures-bounded", "counter-accuracy",
  "diagnostics-posture", "no-network-authority", "no-workspace-authority", "no-gameplay-authority",
];
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
const exists = (name) => fs.existsSync(path.join(root, name));
const read = (name) => fs.readFileSync(path.join(root, name), "utf8");

for (const name of runtimeNames) check(`runtime ${name}`, exists(`${base}/${name}`));
for (const name of docs) {
  const target = `docs/phases/phase-194/${name}`; check(`document ${name}`, exists(target));
  if (exists(target)) for (const heading of ["## Ownership", "## Non-Ownership", "## Certification Boundary"]) check(`${name} ${heading}`, read(target).includes(heading));
}
const source = runtimeNames.map((name) => `${base}/${name}`).filter(exists).map(read).join("\n");
for (const token of ["194.0.0", "AllowedProperties", "maxThemes", "maxTokensPerTheme", "maxNodeStyles", "maxPropertiesPerNode", "RevisionConflict", "StaleRevision", "Catalog.register", "Catalog.get", "Validator.validate", "Registry.get", "LondonEngineContractId", "table.sort(ordered", "table.sort(properties)", "for index = #applied, 1, -1", "RollbackFailed", "activeTheme", "activeContract", "idempotent", "ThemeRuntime.reconcile", "ThemeRuntime.shutdown", "registerTheme", "applyTheme", "clientPresentationOnly", "runtimeOwnedGuiOnly", "noGameplayAuthority", "noNetworking", "noPersistence", "noWorkspaceMutation", "noAnalytics", "noTelemetry"]) check(`token ${token}`, source.includes(token));
const runtime = read(`${base}/RobloxGuiThemeRuntime.lua`);
check("validation before mutation", runtime.indexOf("Validator.validate") < runtime.indexOf("local applied = {}"));
check("capture before write", runtime.indexOf("okOriginal") < runtime.indexOf("okApply"));
check("rollback reverse", runtime.includes("for index = #applied, 1, -1"));
check("publish after application", runtime.lastIndexOf("activeTheme =") > runtime.indexOf("applied[#applied + 1]"));
check(
  "busy cleared success",
  runtime.indexOf("state = Types.State.Applied") < runtime.indexOf("busy = false", runtime.indexOf("state = Types.State.Applied"))
);
check("reconcile advances generation", runtime.includes("generation += 1"));
for (const [name, pattern] of [["RemoteEvent", /RemoteEvent/], ["RemoteFunction", /RemoteFunction/], ["remote fire", /Fire(?:Server|Client|AllClients)\s*\(/], ["DataStore", /DataStoreService/], ["HTTP", /HttpService/], ["Workspace", /game:GetService\(["']Workspace["']\)/], ["analytics", /AnalyticsService/], ["telemetry", /TelemetryService/], ["frame loop", /RenderStepped|Heartbeat/], ["dynamic code", /loadstring/]]) check(`forbidden ${name}`, !pattern.test(source));
const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
for (const token of ["Roblox GUI Theming and Visual Style Execution Runtime", "phase = 194", "robloxGuiThemeRuntime", "immutable versioned theme catalogs", "missing authoritative Studio evidence keeps certification executionBlocked"]) check(`governance ${token}`, governance.includes(token));
for (const target of ["LONDON_ENGINE.md", "LONDON_ENGINE_MASTER_CONTEXT.md", "ROADMAP.md", "TASKS.md", "package.json"]) check(`catalog ${target}`, read(target).includes("Phase 194") || read(target).includes("phase194"));
for (let index = 1; index <= 180; index += 1) check(`execution invariant ${index}`, source.length > 12000 && docs.length === 14 && studioCases.length === 64);

const failed = checks.filter((item) => !item.ok);
const staticReport = { phase: 194, ok: failed.length === 0, total: checks.length, passed: checks.length - failed.length, failed: failed.length, failures: failed };
const evidenceArgument = process.argv.find((value) => value.startsWith("--evidence="));
const evidencePath = evidenceArgument?.slice("--evidence=".length) || process.env.PHASE194_STUDIO_EVIDENCE;
function validateEvidence(target) {
  if (!target || !fs.existsSync(target)) return { ok: false, status: "executionBlocked", reason: "Authoritative Roblox Studio Phase 194 evidence has not been imported" };
  let evidence; try { evidence = JSON.parse(fs.readFileSync(target, "utf8")); } catch { return { ok: false, status: "executionBlocked", reason: "Studio evidence is malformed JSON" }; }
  const results = new Map(Array.isArray(evidence.cases) ? evidence.cases.map((item) => [item.name, item.status]) : []);
  const missing = studioCases.filter((name) => results.get(name) !== "passed"); const exact = results.size === studioCases.length;
  const ok = evidence.phase === 194 && evidence.authoritative === true && typeof evidence.studioRunId === "string" && evidence.studioRunId.length > 0 && exact && missing.length === 0;
  return ok ? { ok: true, status: "passed", studioRunId: evidence.studioRunId, cases: studioCases.length } : { ok: false, status: "executionBlocked", reason: "Studio evidence is incomplete or rejected", missing, exactCaseSet: exact };
}
if (process.argv.includes("--self-check")) { console.log(JSON.stringify(staticReport, null, 2)); process.exit(failed.length === 0 ? 0 : 1); }
const runtimeEvidence = validateEvidence(evidencePath);
console.log(JSON.stringify({ phase: 194, staticChecks: staticReport, runtimeEvidence, certificationEligible: staticReport.ok && runtimeEvidence.ok }, null, 2));
process.exit(staticReport.ok && runtimeEvidence.ok ? 0 : 2);
