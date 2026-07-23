import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 182;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-182");
const reportPath = path.join(evidenceDir, "phase-182-runtime-report.md");
const requiredFiles = [
  "src/ServerScriptService/Presentation/Core/RuntimeRobloxRenderingSession.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionCoordinator.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionRegistry.lua",
  "src/ServerScriptService/Presentation/Core/RobloxExecutionSessionMapper.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRendererOwnership.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRendererReservation.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRendererLifecycle.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRendererScheduling.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionDiagnostics.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionSnapshots.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionEvidence.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionMetrics.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionProfiler.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionBudgets.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionValidation.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionGovernance.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionCertification.lua",
  "src/ServerScriptService/Presentation/Core/RobloxRenderingSessionSelfChecks.lua",
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
    "robloxRenderingSessionRuntime",
    "robloxRenderingSessionRuntimeCapability",
    "RobloxRenderingSessionCoordinator",
    "RuntimeRobloxRenderingSession",
    "RobloxRenderingSessionRegistry",
    "RobloxExecutionSessionMapper",
    "RobloxRendererOwnership",
    "RobloxRendererReservation",
    "RobloxRendererLifecycle",
    "RobloxRendererScheduling",
    "robloxRenderingSessionPosture",
    "noRendering",
    "noGuiCreation",
    "noNetworking",
    "noWorkspaceMutation",
    "noClientAuthority",
    "ProductionCandidate",
  ];
  for (const token of tokens) checks.push(check(`source contains ${token}`, joined.includes(token) || types.includes(token)));
  checks.push(check("session coordinator registers after Roblox capability", bootstrap.indexOf('"RobloxRenderingCoordinator"') < bootstrap.indexOf('"RobloxRenderingSessionCoordinator"')));
  checks.push(check("session coordinator registers before lobby", bootstrap.indexOf('"RobloxRenderingSessionCoordinator"') < bootstrap.indexOf('"LobbyService"')));
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase182:selfcheck")));
  checks.push(check("package session runtime script exists", packageJson.includes("london:roblox-rendering-session")));
  checks.push(check("roadmap records phase 182", roadmap.includes("Phase 182: Roblox Rendering Session Runtime")));
  checks.push(check("tasks records phase 182", tasks.includes("Phase 182: Roblox Rendering Session Runtime")));
  checks.push(check("engine records phase 182", engine.includes("Phase 182: Roblox Rendering Session Runtime")));
  checks.push(check("master context records phase 182", context.includes("Phase 182: Roblox Rendering Session Runtime")));
  checks.push(check("governance contract exists", governance.includes("Roblox Rendering Session Runtime")));
  checks.push(check("governance provider exists", governance.includes('"robloxRenderingSessionRuntime"')));
  for (let index = 0; index <= 9; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-182");
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
    ":Set" + "Async(",
    ":Update" + "Async(",
    ":Get" + "Async(",
    ":Fire" + "Client(",
    ":FireAll" + "Clients(",
    "game." + "Workspace",
    'GetService("Workspace")',
  ];
  for (const marker of banned) checks.push(check(`forbidden surface absent ${marker}`, !joined.includes(marker)));
  return checks;
}

function summarize(checks) {
  const failures = checks.filter((item) => !item.ok);
  return { phase, ok: failures.length === 0, total: checks.length, passed: checks.length - failures.length, failed: failures.length, failures };
}

function writeRuntimeReport(summary, runtime) {
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(reportPath, [
    "# Phase 182 Runtime Evidence",
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
    "Phase 182 is Production Candidate. Authoritative Roblox Studio runtime evidence has not been imported.",
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
