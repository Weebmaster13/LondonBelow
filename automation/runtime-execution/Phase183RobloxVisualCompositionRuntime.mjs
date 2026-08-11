import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 183;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-183");
const reportPath = path.join(evidenceDir, "phase-183-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Presentation/Core/RuntimeRobloxVisualComposition.lua",
  "src/ServerScriptService/Presentation/Core/RobloxVisualCompositionCoordinator.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionRegistry.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionPlanRegistry.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionNodeRegistry.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionGraph.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionHierarchy.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionCompiler.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionResolver.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionNormalizer.lua",
  "src/ServerScriptService/Presentation/Core/VisualLayoutModel.lua",
  "src/ServerScriptService/Presentation/Core/VisualLayoutConstraints.lua",
  "src/ServerScriptService/Presentation/Core/VisualResponsiveModel.lua",
  "src/ServerScriptService/Presentation/Core/VisualSafeAreaModel.lua",
  "src/ServerScriptService/Presentation/Core/VisualLayerRegistry.lua",
  "src/ServerScriptService/Presentation/Core/VisualRegionRegistry.lua",
  "src/ServerScriptService/Presentation/Core/VisualStyleReferences.lua",
  "src/ServerScriptService/Presentation/Core/VisualThemeReferences.lua",
  "src/ServerScriptService/Presentation/Core/VisualTypographyReferences.lua",
  "src/ServerScriptService/Presentation/Core/VisualAssetReferences.lua",
  "src/ServerScriptService/Presentation/Core/VisualStateVariants.lua",
  "src/ServerScriptService/Presentation/Core/VisualVisibilityModel.lua",
  "src/ServerScriptService/Presentation/Core/VisualLocalizationSlots.lua",
  "src/ServerScriptService/Presentation/Core/VisualAccessibilitySemantics.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionBindings.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionOwnership.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionRevisions.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionDiagnostics.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionSnapshots.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionEvidence.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionMetrics.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionProfiler.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionBudgets.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionValidation.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionGovernance.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionCertification.lua",
  "src/ServerScriptService/Presentation/Core/VisualCompositionSelfChecks.lua",
];

const phaseDocs = [
  "00_BASELINE.md",
  "01_ARCHITECTURE.md",
  "02_COMPOSITION_MODEL.md",
  "03_COMPOSITION_GRAPH.md",
  "04_NODE_AND_SEMANTIC_MODEL.md",
  "05_LAYER_AND_REGION_MODEL.md",
  "06_LAYOUT_MODEL.md",
  "07_RESPONSIVE_MODEL.md",
  "08_STYLE_THEME_TYPOGRAPHY_REFERENCES.md",
  "09_LOCALIZATION_AND_ACCESSIBILITY.md",
  "10_STATE_VARIANTS.md",
  "11_BINDING_AND_OWNERSHIP.md",
  "12_COMPOSITION_COMPILER.md",
  "13_REVISION_AND_SUPERSESSION.md",
  "14_LIFECYCLE.md",
  "15_VALIDATION.md",
  "16_FAILURE_INJECTION.md",
  "17_DIAGNOSTICS_AND_SNAPSHOTS.md",
  "18_EVIDENCE_METRICS_PROFILER.md",
  "19_SECURITY_REVIEW.md",
  "20_PERFORMANCE_AND_BUDGETS.md",
  "21_GOVERNANCE.md",
  "22_SELF_CHECKS.md",
  "23_RUNTIME_SMOKE_TEST.md",
  "24_PRODUCTION_REVIEW.md",
  "25_COMPLETION_REPORT.md",
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

function executableBannedApiClean(files) {
  const patterns = [
    /Instance\.new\(\s*['"](?:ScreenGui|PlayerGui|CoreGui|Frame|TextLabel|TextButton|ImageLabel|ImageButton|ScrollingFrame|ViewportFrame|BillboardGui|SurfaceGui|CanvasGroup)['"]/i,
    /game\s*:\s*GetService\(\s*['"](?:TweenService|ContentProvider|Workspace|DataStoreService|MessagingService|HttpService|AnalyticsService|SoundService)['"]/i,
    /\bgame\.Workspace\b/i,
    /\bworkspace\s*[\.:[]/i,
    /Instance\.new\(\s*['"](?:RemoteEvent|RemoteFunction)['"]/i,
    /FireClient\s*\(/i,
    /FireAllClients\s*\(/i,
    /InvokeClient\s*\(/i,
    /LoadAnimation\s*\(/i,
    /PreloadAsync\s*\(/i,
    /\.Parent\s*=\s*(?:workspace|Workspace)\b/i,
  ];
  const hits = [];
  for (const file of files) {
    const lines = read(file).split(/\r?\n/);
    lines.forEach((line, index) => {
      for (const pattern of patterns) {
        if (pattern.test(line)) hits.push(`${file}:${index + 1}:${line.trim()}`);
      }
    });
  }
  return { ok: hits.length === 0, hits };
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
  const types = read("src/ServerScriptService/Presentation/Core/PresentationTypes.lua");

  const requiredTokens = [
    "robloxVisualCompositionRuntime",
    "robloxVisualCompositionCapability",
    "robloxVisualCompositionPosture",
    "RobloxVisualCompositionCoordinator",
    "RuntimeRobloxVisualComposition",
    "VisualCompositionRegistry",
    "VisualCompositionPlanRegistry",
    "VisualCompositionNodeRegistry",
    "VisualCompositionGraph",
    "VisualCompositionHierarchy",
    "VisualCompositionCompiler",
    "VisualCompositionResolver",
    "VisualCompositionNormalizer",
    "VisualLayoutModel",
    "VisualLayoutConstraints",
    "VisualResponsiveModel",
    "VisualSafeAreaModel",
    "VisualLayerRegistry",
    "VisualRegionRegistry",
    "VisualStyleReferences",
    "VisualThemeReferences",
    "VisualTypographyReferences",
    "VisualAssetReferences",
    "VisualStateVariants",
    "VisualVisibilityModel",
    "VisualLocalizationSlots",
    "VisualAccessibilitySemantics",
    "VisualCompositionBindings",
    "VisualCompositionOwnership",
    "VisualCompositionRevisions",
    "VisualCompositionDiagnostics",
    "VisualCompositionSnapshots",
    "VisualCompositionEvidence",
    "VisualCompositionMetrics",
    "VisualCompositionProfiler",
    "VisualCompositionBudgets",
    "VisualCompositionValidation",
    "VisualCompositionGovernance",
    "VisualCompositionCertification",
    "VisualCompositionSelfChecks",
    "VisualCompositionKind",
    "VisualCompositionState",
    "VisualNodeKind",
    "VisualSemanticRole",
    "VisualLayerKind",
    "VisualLayoutMode",
    "VisualSizingMode",
    "VisualVisibilityState",
    "VisualNodeState",
    "VisualResponsiveClass",
    "VisualCompositionFailureType",
    "VisualCompositionLimits",
    "ProductionCandidate",
    "RuntimeShutdown",
    "DuplicateDefinition",
    "MissingRoot",
    "MultipleRoots",
    "CircularHierarchy",
    "MissingParent",
    "InvalidLayout",
    "InvalidReference",
    "InvalidAccessibilityMetadata",
    "StaleRevision",
    "CompilationFailure",
    "noGuiCreation",
    "noRendering",
    "noInstanceMutation",
    "noAssetLoading",
    "noNetworking",
    "noWorkspaceMutation",
    "noClientAuthority",
  ];
  for (const token of requiredTokens) checks.push(check(`source contains ${token}`, joined.includes(token) || types.includes(token)));

  checks.push(check("bootstrap requires coordinator", bootstrap.includes("RobloxVisualCompositionCoordinator")));
  checks.push(check("bootstrap registers after rendering session", bootstrap.indexOf('"RobloxRenderingSessionCoordinator"') < bootstrap.indexOf('"RobloxVisualCompositionCoordinator"')));
  checks.push(check("bootstrap registers before lobby", bootstrap.indexOf('"RobloxVisualCompositionCoordinator"') < bootstrap.indexOf('"LobbyService"')));
  checks.push(check("bootstrap depends on rendering session coordinator", bootstrap.includes('"RobloxRenderingSessionCoordinator"')));
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase183:selfcheck")));
  checks.push(check("package runtime script exists", packageJson.includes("london:roblox-visual-composition")));
  checks.push(check("package validate script exists", packageJson.includes("london:roblox-visual-composition:validate")));
  checks.push(check("roadmap records phase 183", roadmap.includes("Phase 183: Roblox Visual Composition Runtime Foundation")));
  checks.push(check("tasks records phase 183", tasks.includes("Phase 183: Roblox Visual Composition Runtime Foundation")));
  checks.push(check("engine records phase 183", engine.includes("Phase 183: Roblox Visual Composition Runtime Foundation")));
  checks.push(check("master context records phase 183", context.includes("Phase 183: Roblox Visual Composition Runtime Foundation")));
  checks.push(check("governance contract exists", governance.includes("Roblox Visual Composition Runtime Foundation")));
  checks.push(check("governance provider exists", governance.includes('"robloxVisualCompositionRuntime"')));
  checks.push(check("governance non ownership documents GUI", governance.includes("GUI instantiation")));
  checks.push(check("governance non ownership documents client authority", governance.includes("client authority")));

  const docsDir = path.join(repoRoot, "docs", "phases", "phase-183");
  for (const doc of phaseDocs) {
    checks.push(check(`phase doc ${doc}`, fs.existsSync(path.join(docsDir, doc))));
  }

  const scan = executableBannedApiClean(requiredFiles.filter((file) => file.endsWith(".lua")));
  checks.push(check("forbidden executable API scan clean", scan.ok, scan.hits.join("\n")));
  return checks;
}

function summarize(checks) {
  const failures = checks.filter((item) => !item.ok);
  return { phase, ok: failures.length === 0, total: checks.length, passed: checks.length - failures.length, failed: failures.length, failures };
}

function writeRuntimeReport(summary, runtime) {
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(reportPath, [
    "# Phase 183 Runtime Evidence",
    "",
    "## Static Self Checks",
    "",
    `Total: ${summary.total}`,
    `Passed: ${summary.passed}`,
    `Failed: ${summary.failed}`,
    "",
    "## Runtime Smoke Test",
    "",
    runtime.status,
    `Framework used: ${runtime.frameworkUsed}`,
    `Execution blocked: ${runtime.executionBlocked}`,
    `Blocked reason: ${runtime.blockedReason}`,
    "",
    "## Certification",
    "",
    "Phase 183 is Production Candidate. Authoritative Roblox Studio runtime evidence has not been imported.",
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
  executionBlocked: true,
  status: "executionBlocked",
  ok: false,
  blockedReason: "Authoritative Roblox Studio runtime evidence was not imported through the Runtime Execution Framework.",
};
writeRuntimeReport(summary, runtime);
console.log(JSON.stringify({ ok: false, selfCheck: summary, runtime }, null, 2));
process.exit(summary.ok ? 2 : 1);
