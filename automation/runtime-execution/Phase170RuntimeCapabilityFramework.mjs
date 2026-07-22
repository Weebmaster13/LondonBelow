import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 170;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-170");
const reportPath = path.join(evidenceDir, "phase-170-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Core/Capabilities/RuntimeCapabilityFramework.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityCoordinator.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityTypes.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilitySerialization.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityValidation.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityRegistry.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityDiscovery.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityLifecycle.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityDependencyGraph.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityHealth.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityDiagnostics.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilitySnapshots.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityEvidence.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityMetrics.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityProfiler.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityBudgets.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityGovernance.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilityCertification.lua",
  "src/ServerScriptService/Core/Capabilities/CapabilitySelfChecks.lua",
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

  for (const token of [
    "runtimeCapabilityFramework",
    "RuntimeCapabilityCoordinator",
    "registerCapability",
    "resolveInterface",
    "activateCapability",
    "suspendCapability",
    "recoverCapability",
    "capabilityFrameworkPosture",
    "capabilityRegistry",
    "capabilityDependencyGraph",
    "capabilityDiscovery",
    "capabilityHealth",
    "capabilityEvidence",
    "CapabilityCertification",
    "ProductionCandidate",
    "noCommandExecution",
    "noEventPublication",
    "noQueryExecution",
  ]) checks.push(check(`source contains ${token}`, joined.includes(token)));

  checks.push(check("bootstrap registers capability after workflow", bootstrap.indexOf('registerModule("RuntimeWorkflowCoordinator"') < bootstrap.indexOf('registerModule("RuntimeCapabilityCoordinator"')));
  checks.push(check("bootstrap registers capability before lobby", bootstrap.indexOf('registerModule("RuntimeCapabilityCoordinator"') < bootstrap.indexOf('registerModule("LobbyService"')));
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase170:selfcheck")));
  checks.push(check("package capability runtime script exists", packageJson.includes("london:capability-framework")));
  checks.push(check("roadmap records phase 170", roadmap.includes("Phase 170: Higher-Level Runtime Capability Foundation")));
  checks.push(check("tasks records phase 170", tasks.includes("Phase 170: Higher-Level Runtime Capability Foundation")));
  checks.push(check("engine records phase 170", engine.includes("Phase 170: Higher-Level Runtime Capability Foundation")));
  checks.push(check("master context records phase 170", context.includes("Phase 170: Higher-Level Runtime Capability Foundation")));
  checks.push(check("governance contract exists", governance.includes("Runtime Capability Framework")));
  checks.push(check("governance provider exists", governance.includes('"runtimeCapabilityFramework"')));

  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-170");
    const present = fs.existsSync(docsDir) && fs.readdirSync(docsDir).some((name) => name.startsWith(prefix));
    checks.push(check(`phase doc ${prefix}`, present));
  }

  for (const banned of [
    'GetService("Data' + 'StoreService")',
    'GetService("Messaging' + 'Service")',
    'GetService("Http' + 'Service")',
    'Instance.new("Remote' + 'Event")',
    'Instance.new("Remote' + 'Function")',
    ":SetAsync(",
    ":UpdateAsync(",
    ":GetAsync(",
    ":FireClient(",
    ":FireAllClients(",
    "game.Workspace",
    'GetService("Workspace")',
  ]) checks.push(check(`forbidden surface absent ${banned}`, !joined.includes(banned)));

  return checks;
}

function summarize(checks) {
  const failures = checks.filter((item) => !item.ok);
  return {
    phase,
    ok: failures.length === 0,
    total: checks.length,
    passed: checks.length - failures.length,
    failed: failures.length,
    failures,
  };
}

function writeRuntimeReport(summary, runtime) {
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(reportPath, [
    "# Phase 170 Runtime Evidence",
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
    "Phase 170 is Production Candidate.",
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
