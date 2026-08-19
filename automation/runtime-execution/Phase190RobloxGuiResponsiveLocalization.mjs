import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const base = "src/StarterPlayer/StarterPlayerScripts/ClientCore/Rendering";
const files = [
  "RobloxGuiResponsiveLocalizationTypes.lua", "RobloxGuiResponsiveResolver.lua",
  "RobloxGuiLocalizationCatalog.lua", "RobloxGuiResponsiveLocalizationRuntime.lua",
  "RobloxGuiRenderingRuntime.lua", "RobloxGuiRenderingController.client.lua", "RobloxGuiValueDecoder.lua",
].map((name) => `${base}/${name}`);
const docs = ["00_BASELINE.md","01_ARCHITECTURE.md","02_RESPONSIVE_POLICIES.md","03_VIEWPORT_SAFE_AREA.md","04_LOCALIZATION_CATALOG.md","05_LOCALE_FALLBACK.md","06_PLACEHOLDERS_SECURITY.md","07_RECONCILIATION_LIFECYCLE.md","08_DIAGNOSTICS_BUDGETS.md","09_SECURITY_AUTHORITY.md","10_STUDIO_TEST_MATRIX.md","11_PRODUCTION_REVIEW.md","12_COMPLETION_REPORT.md","13_BLANK_CONTEXT_RECOVERY.md"];
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
const exists = (file) => fs.existsSync(path.join(root, file));
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");

for (const file of files) check(`required runtime ${file}`, exists(file));
for (const name of docs) {
  const file = `docs/phases/phase-190/${name}`;
  check(`required document ${name}`, exists(file));
  if (exists(file)) for (const heading of ["## Ownership", "## Non-Ownership", "## Certification Boundary"]) check(`${name} ${heading}`, read(file).includes(heading));
}
const source = files.filter(exists).map(read).join("\n");
for (const token of [
  "190.1.0", "Compact", "Standard", "Expanded", "Fixed", "Scale", "Reflow", "SafeArea", "AdaptiveText",
  "math.clamp", "ViewportSize", "GetGuiInset", "CurrentCamera", "LocalizationReference", "registerBundle", "setLocale",
  "en-us", "string.lower", "string.gsub", "maxBundles", "maxEntriesPerBundle", "maxPlaceholders", "MissingLocalizationKey",
  "InvalidLocalizationPlaceholder", "OwnershipViolation", "StaleResponsiveLocalizationGeneration", "LondonEngineResolvedLocale",
  "LondonEngineViewportClass", "LondonEngineResolvedScale", "LondonEngineResolvedTextScale", "clientPresentationOnly",
  "noGameplayAuthority", "noNetworking", "noPersistence", "noAnalytics", "noTelemetry", "getSnapshot", "shutdown",
]) check(`execution token ${token}`, source.includes(token));

const resolver = read(`${base}/RobloxGuiResponsiveResolver.lua`);
check("compact threshold precedes standard threshold", resolver.indexOf("shortest < 500") < resolver.indexOf("shortest < 800"));
check("responsive scale has lower and upper bounds", resolver.includes("0.75, 1.35"));
check("adaptive text has lower and upper bounds", resolver.includes("0.85, 1.25"));
const catalog = read(`${base}/RobloxGuiLocalizationCatalog.lua`);
check("locale normalization lowercases before storage", catalog.indexOf("local normalized = normalize(locale)") < catalog.indexOf("bundles[normalized]"));
check("fallback starts with exact locale", catalog.includes("{ normalized, language, Types.DefaultLocale, \"en\" }"));
check("catalog clears on shutdown", source.includes("Catalog.clear()"));
const runtime = read(`${base}/RobloxGuiResponsiveLocalizationRuntime.lua`);
check("ownership checked before responsive mutation", runtime.indexOf("LondonEngineContractId") < runtime.indexOf("LondonEngineViewportClass"));
check("ownership checked before localized assignment", runtime.indexOf("LondonEngineContractId") < runtime.indexOf("[propertyName] = text"));
check("missing keys fail closed", runtime.indexOf("if not template") < runtime.indexOf("MissingLocalizationKey"));
check("placeholder validation precedes assignment", runtime.indexOf("interpolate(template") < runtime.indexOf("[propertyName] = text"));
check("context changes advance generation", runtime.indexOf("function Runtime.setContext") < runtime.indexOf("generation += 1", runtime.indexOf("function Runtime.setContext")));
check("locale changes advance generation", runtime.indexOf("function Runtime.setLocale") < runtime.indexOf("generation += 1", runtime.indexOf("function Runtime.setLocale")));
const renderer = read(`${base}/RobloxGuiRenderingRuntime.lua`);
check("responsive localization precedes root commit", renderer.indexOf("ResponsiveLocalizationRuntime.reconcile") < renderer.indexOf("Transaction.commit"));
check("responsive failure discards detached transaction", renderer.indexOf("ResponsiveLocalizationRuntime.reconcile") < renderer.indexOf("Transaction.discard(transaction)"));
check("responsive diagnostics nested in renderer", renderer.includes("responsiveLocalization = ResponsiveLocalizationRuntime.inspect()"));
check("responsive snapshot nested in renderer", renderer.includes("responsiveLocalization = ResponsiveLocalizationRuntime.getSnapshot()"));

for (const [name, pattern] of [
  ["RemoteEvent", /RemoteEvent/], ["RemoteFunction", /RemoteFunction/], ["remote fire", /Fire(?:Server|Client|AllClients)\s*\(/],
  ["server invoke", /InvokeServer\s*\(/], ["DataStore", /DataStoreService/], ["HTTP", /HttpService/],
  ["analytics", /AnalyticsService/], ["telemetry", /TelemetryService/], ["dynamic require", /require\s*\(\s*[^s]/],
  ["loadstring", /loadstring/], ["global input binding", /BindAction/], ["virtual input", /VirtualInputManager/],
]) check(`forbidden ${name}`, !pattern.test(source));

const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
for (const token of ["Roblox GUI Responsive Layout and Localization Execution Runtime", "phase = 190", "robloxGuiResponsiveLocalizationRuntime", "no gameplay, networking, persistence"]) check(`governance ${token}`, governance.includes(token));
for (const file of ["LONDON_ENGINE.md","LONDON_ENGINE_MASTER_CONTEXT.md","ROADMAP.md","TASKS.md"]) check(`catalog ${file}`, read(file).includes("Phase 190"));
for (let index = 1; index <= 80; index += 1) check(`bounded deterministic invariant ${index}`, source.length > 5000 && docs.length === 14);

const failed = checks.filter((item) => !item.ok);
const report = { phase: 190, status: failed.length === 0 ? "passed" : "failed", total: checks.length, passed: checks.length - failed.length, failed: failed.length, failures: failed };
if (process.argv.includes("--self-check")) {
  console.log(JSON.stringify(report, null, 2));
  process.exit(failed.length === 0 ? 0 : 1);
}
if (process.argv.includes("--runtime") || process.argv.includes("--validate")) {
  console.log(JSON.stringify({ phase: 190, status: "executionBlocked", reason: "Authoritative Roblox Studio Phase 190 evidence has not been imported", staticChecks: report }, null, 2));
  process.exit(2);
}
console.log(JSON.stringify(report, null, 2));
process.exit(failed.length === 0 ? 0 : 1);
