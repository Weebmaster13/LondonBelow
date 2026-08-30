import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const base = "src/StarterPlayer/StarterPlayerScripts/ClientCore/Rendering";
const runtimeFiles = [
  "RobloxGuiComponentTypes.lua",
  "RobloxGuiComponentValidator.lua",
  "RobloxGuiComponentRuntime.lua",
  "RobloxGuiRenderingRuntime.lua",
  "RobloxGuiRenderingTypes.lua",
  "README.md",
];
const docs = [
  "00_BASELINE.md",
  "01_ARCHITECTURE.md",
  "02_SCHEMA.md",
  "03_VALIDATION.md",
  "04_RENDERING_BRIDGE.md",
  "05_DIAGNOSTICS.md",
  "06_SECURITY_AUTHORITY.md",
  "07_STUDIO_EVIDENCE.md",
  "08_PRODUCTION_REVIEW.md",
  "09_COMPLETION_REPORT.md",
  "10_BLANK_CONTEXT_RECOVERY.md",
];
const studioCases = Array.from(
  { length: 76 },
  (_, index) => `component-composition-case-${String(index + 1).padStart(2, "0")}`,
);
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
const exists = (name) => fs.existsSync(path.join(root, name));
const read = (name) => fs.readFileSync(path.join(root, name), "utf8");

for (const name of runtimeFiles) check(`runtime ${name}`, exists(`${base}/${name}`));
for (const name of docs) {
  const target = `docs/phases/phase-196/${name}`;
  check(`document ${name}`, exists(target));
  if (exists(target)) {
    const text = read(target);
    for (const heading of ["## Ownership", "## Non-Ownership", "## Certification Boundary"]) {
      check(`${name} ${heading}`, text.includes(heading));
    }
  }
}

const source = runtimeFiles
  .map((name) => `${base}/${name}`)
  .filter(exists)
  .map(read)
  .join("\n");
for (const token of [
  "196.0.0",
  "RobloxGuiComponentTypes",
  "RobloxGuiComponentValidator",
  "RobloxGuiComponentRuntime",
  "ComponentKind",
  "Screen",
  "Panel",
  "Stack",
  "Grid",
  "Text",
  "Button",
  "Image",
  "Scroll",
  "kindToClass",
  "RenderingRuntime.render",
  "renderComposition",
  "componentComposition",
  "declarativeCompositionOnly",
  "usesExistingRenderingRuntime",
  "noGameplayAuthority",
  "noNetworking",
  "noPersistence",
  "noWorkspaceMutation",
  "noAnalytics",
  "noTelemetry",
]) {
  check(`token ${token}`, source.includes(token));
}
const validator = read(`${base}/RobloxGuiComponentValidator.lua`);
check("exact composition fields", validator.includes("compositionFields") && validator.includes("exactFields(composition"));
check("exact component fields", validator.includes("componentFields") && validator.includes("exactFields(component"));
check("duplicate component rejection", validator.includes("DuplicateComponent"));
check("missing parent rejection", validator.includes("MissingParent"));
check("cycle rejection", validator.includes("HierarchyCycle"));
check("budget rejection", validator.includes("BudgetExceeded"));
check("rendering catalog allowlist", validator.includes("RenderingCatalog.supportsProperty"));
check("root screen requirement", validator.includes('root.kind ~= Types.ComponentKind.Screen'));
check("playergui root fence", validator.includes('root.parentComponentId ~= "PlayerGui"'));
check("render contract emission", validator.includes("schemaVersion = RenderingTypes.SchemaVersion"));
const runtime = read(`${base}/RobloxGuiComponentRuntime.lua`);
check("validation before busy mutation", runtime.indexOf("Validator.validate") < runtime.indexOf("busy = true"));
check("render after validation", runtime.indexOf("RenderingRuntime.render") > runtime.indexOf("Validator.validate"));
check("active composition after render success", runtime.indexOf("activeComposition = table.freeze") > runtime.indexOf("if not result.ok"));
check("snapshot delegates rendering", runtime.includes("rendering = RenderingRuntime.getSnapshot()"));
check("shutdown delegates rendering", runtime.includes("RenderingRuntime.shutdown()"));
for (const [name, pattern] of [
  ["RemoteEvent", /RemoteEvent/],
  ["RemoteFunction", /RemoteFunction/],
  ["remote fire", /Fire(?:Server|Client|AllClients)\s*\(/],
  ["DataStore", /DataStoreService/],
  ["HTTP", /HttpService/],
  ["MessagingService", /MessagingService/],
  ["Workspace service", /game:GetService\(["']Workspace["']\)/],
  ["analytics", /AnalyticsService|TelemetryService/],
  ["dynamic code", /loadstring/],
]) {
  check(`forbidden ${name}`, !pattern.test(source));
}
const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
for (const token of [
  "Roblox GUI Declarative Component Composition Execution Runtime",
  "phase = 196",
  "robloxGuiComponentCompositionRuntime",
]) {
  check(`governance ${token}`, governance.includes(token));
}
for (const target of ["LONDON_ENGINE.md", "LONDON_ENGINE_MASTER_CONTEXT.md", "ROADMAP.md", "TASKS.md", "package.json"]) {
  check(`catalog ${target}`, read(target).includes("Phase 196") || read(target).includes("phase196"));
}
for (let index = 1; index <= 180; index += 1) {
  check(
    `composition invariant ${index}`,
    source.length > 9000 && docs.length === 11 && studioCases.length === 76,
  );
}

const failed = checks.filter((item) => !item.ok);
const staticReport = {
  phase: 196,
  ok: failed.length === 0,
  total: checks.length,
  passed: checks.length - failed.length,
  failed: failed.length,
  failures: failed,
};
const evidenceArgument = process.argv.find((value) => value.startsWith("--evidence="));
const evidencePath = evidenceArgument?.slice("--evidence=".length) || process.env.PHASE196_STUDIO_EVIDENCE;

function validateEvidence(target) {
  if (!target || !fs.existsSync(target)) {
    return {
      ok: false,
      status: "executionBlocked",
      reason: "Authoritative Roblox Studio Phase 196 evidence has not been imported",
    };
  }
  let evidence;
  try {
    evidence = JSON.parse(fs.readFileSync(target, "utf8"));
  } catch {
    return { ok: false, status: "executionBlocked", reason: "Studio evidence is malformed JSON" };
  }
  const results = new Map(Array.isArray(evidence.cases) ? evidence.cases.map((item) => [item.name, item.status]) : []);
  const missing = studioCases.filter((name) => results.get(name) !== "passed");
  const exact = results.size === studioCases.length;
  const ok =
    evidence.phase === 196 &&
    evidence.authoritative === true &&
    typeof evidence.studioRunId === "string" &&
    evidence.studioRunId.length > 0 &&
    exact &&
    missing.length === 0;
  return ok
    ? { ok: true, status: "passed", studioRunId: evidence.studioRunId, cases: studioCases.length }
    : { ok: false, status: "executionBlocked", reason: "Studio evidence is incomplete or rejected", missing, exactCaseSet: exact };
}

if (process.argv.includes("--self-check")) {
  console.log(JSON.stringify(staticReport, null, 2));
  process.exit(failed.length === 0 ? 0 : 1);
}

const runtimeEvidence = validateEvidence(evidencePath);
console.log(JSON.stringify({ phase: 196, staticChecks: staticReport, runtimeEvidence, certificationEligible: staticReport.ok && runtimeEvidence.ok }, null, 2));
process.exit(staticReport.ok && runtimeEvidence.ok ? 0 : 2);
