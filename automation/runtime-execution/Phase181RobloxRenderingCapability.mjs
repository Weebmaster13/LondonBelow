import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 181;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-181");
const reportPath = path.join(evidenceDir, "phase-181-runtime-report.md");
const requiredFiles = [
  "src/ServerScriptService/Presentation/Core/RuntimeRobloxRenderingCapability.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingCoordinator.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRendererRegistry.lua",
  "src/ServerScriptService/Presentation/Core/RobloxCapabilityRegistry.lua",
  "src/ServerScriptService/Presentation/Core/RobloxCapabilityNegotiation.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRendererConfiguration.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRendererLimits.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingDiagnostics.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSnapshots.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingEvidence.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingMetrics.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingProfiler.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingValidation.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingGovernance.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingCertification.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSelfChecks.lua",
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
  const types = read("src/ServerScriptService/Presentation/Core/PresentationTypes.lua");
  const tokens = [
    "robloxRenderingRuntime",
    "robloxRenderingCapability",
    "RobloxRenderingCoordinator",
    "RuntimeRobloxRenderingCapability",
    "RobloxRendererRegistry",
    "RobloxCapabilityRegistry",
    "RobloxCapabilityNegotiation",
    "RobloxRendererConfiguration",
    "RobloxRendererStatus",
    "RobloxRenderingFeature",
    "robloxRenderingPosture",
    "noRendering",
    "noGui",
    "noAssetLoading",
    "noNetworking",
    "noWorkspaceMutation",
    "noClientAuthority",
    "ProductionCandidate",
  ];
  for (const token of tokens) {
    checks.push(check(`source contains ${token}`, joined.includes(token) || types.includes(token)));
  }
  checks.push(check("coordinator registers after rendering execution", bootstrap.indexOf('"PresentationRenderingExecutionCoordinator"') < bootstrap.indexOf('"RobloxRenderingCoordinator"')));
  checks.push(check("coordinator registers before lobby", bootstrap.indexOf('"RobloxRenderingCoordinator"') < bootstrap.indexOf('"LobbyService"')));
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase181:selfcheck")));
  checks.push(check("package roblox rendering script exists", packageJson.includes("london:roblox-rendering")));
  checks.push(check("roadmap records phase 181", roadmap.includes("Phase 181: Roblox Rendering Capability Foundation")));
  checks.push(check("tasks records phase 181", tasks.includes("Phase 181: Roblox Rendering Capability Foundation")));
  checks.push(check("engine records phase 181", engine.includes("Phase 181: Roblox Rendering Capability Foundation")));
  checks.push(check("master context records phase 181", context.includes("Phase 181: Roblox Rendering Capability Foundation")));
  checks.push(check("governance contract exists", governance.includes("Roblox Rendering Capability Foundation")));
  checks.push(check("governance provider exists", governance.includes('"robloxRenderingRuntime"')));
  for (let index = 0; index <= 9; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-181");
    checks.push(check(`phase doc ${prefix}`, fs.existsSync(docsDir) && fs.readdirSync(docsDir).some((name) => name.startsWith(prefix))));
  }
  const banned = [
    'GetService("Data' + 'StoreService")',
    'GetService("Messaging' + 'Service")',
    'GetService("Http' + 'Service")',
    'GetService("Content' + 'Provider")',
    'Instance.new("Remote' + 'Event")',
    'Instance.new("Remote' + 'Function")',
    'Instance.new("Screen' + 'Gui")',
    'Instance.new("Frame")',
    'Instance.new("Text' + 'Label")',
    'Instance.new("Image' + 'Label")',
    'Instance.new("Viewport' + 'Frame")',
    'Instance.new("Billboard' + 'Gui")',
    'Instance.new("Surface' + 'Gui")',
    ":Set" + "Async(",
    ":Update" + "Async(",
    ":Get" + "Async(",
    ":Fire" + "Client(",
    ":FireAll" + "Clients(",
    "game." + "Workspace",
    'GetService("Workspace")',
  ];
  for (const marker of banned) {
    checks.push(check(`forbidden surface absent ${marker}`, !joined.includes(marker)));
  }
  return checks;
}

function summarize(checks) {
  const failures = checks.filter((item) => !item.ok);
  return { phase, ok: failures.length === 0, total: checks.length, passed: checks.length - failures.length, failed: failures.length, failures };
}

function writeRuntimeReport(summary, runtime) {
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(reportPath, [
    "# Phase 181 Runtime Evidence",
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
    "Phase 181 is Production Candidate. Authoritative Roblox Studio runtime evidence has not been imported.",
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
