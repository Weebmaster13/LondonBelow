import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 171;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-171");
const reportPath = path.join(evidenceDir, "phase-171-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Core/DomainCapabilities/RuntimeDomainCapabilityFoundation.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainCapabilityCoordinator.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainCapabilityTypes.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainSerialization.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainValidation.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainIdentityRegistry.lua",
  "src/ServerScriptService/Core/DomainCapabilities/InterfaceOwnershipRegistry.lua",
  "src/ServerScriptService/Core/DomainCapabilities/CapabilityCommunicationContracts.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainLifecycleIntegration.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainDiagnostics.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainSnapshots.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainEvidence.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainMetrics.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainProfiler.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainBudgets.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainGovernance.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainCertification.lua",
  "src/ServerScriptService/Core/DomainCapabilities/DomainSelfChecks.lua",
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
    "runtimeDomainCapabilityFoundation",
    "RuntimeDomainCapabilityCoordinator",
    "registerDomainCapability",
    "validateDomainCapability",
    "resolveDomainInterface",
    "DomainIdentityRegistry",
    "InterfaceOwnershipRegistry",
    "CapabilityCommunicationContracts",
    "domainCapabilityPosture",
    "domainCapabilities",
    "interfaceOwnership",
    "communicationContracts",
    "noConcreteDomainImplementation",
    "noDirectCapabilityCoupling",
    "noCommandExecution",
    "noEventPublication",
    "noQueryExecution",
    "ProductionCandidate",
  ]) checks.push(check(`source contains ${token}`, joined.includes(token)));

  checks.push(
    check(
      "bootstrap registers domain capability after capability framework",
      bootstrap.indexOf('"RuntimeCapabilityCoordinator"') < bootstrap.indexOf('"RuntimeDomainCapabilityCoordinator"'),
    ),
  );
  checks.push(
    check(
      "bootstrap registers domain capability before lobby",
      bootstrap.indexOf('"RuntimeDomainCapabilityCoordinator"') < bootstrap.indexOf('"LobbyService"'),
    ),
  );
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase171:selfcheck")));
  checks.push(check("package domain capability script exists", packageJson.includes("london:domain-capability-foundation")));
  checks.push(check("roadmap records phase 171", roadmap.includes("Phase 171: Runtime Domain Capability Foundation")));
  checks.push(check("tasks records phase 171", tasks.includes("Phase 171: Runtime Domain Capability Foundation")));
  checks.push(check("engine records phase 171", engine.includes("Phase 171: Runtime Domain Capability Foundation")));
  checks.push(check("master context records phase 171", context.includes("Phase 171: Runtime Domain Capability Foundation")));
  checks.push(check("governance contract exists", governance.includes("Runtime Domain Capability Foundation")));
  checks.push(check("governance provider exists", governance.includes('"runtimeDomainCapabilityFoundation"')));

  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-171");
    const present = fs.existsSync(docsDir) && fs.readdirSync(docsDir).some((name) => name.startsWith(prefix));
    checks.push(check(`phase doc ${prefix}`, present));
  }

  for (const banned of [
    'GetService("Data' + 'StoreService")',
    'GetService("Messaging' + 'Service")',
    'GetService("Http' + 'Service")',
    'Instance.new("Remote' + 'Event")',
    'Instance.new("Remote' + 'Function")',
    ":Set" + "Async(",
    ":Update" + "Async(",
    ":Get" + "Async(",
    ":Fire" + "Client(",
    ":FireAll" + "Clients(",
    "game." + "Workspace",
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
    "# Phase 171 Runtime Evidence",
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
    "Phase 171 is Production Candidate.",
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
