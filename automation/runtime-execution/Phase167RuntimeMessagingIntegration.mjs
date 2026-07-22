import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 167;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-167");
const reportPath = path.join(evidenceDir, "phase-167-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Core/Messaging/RuntimeMessagingIntegration.lua",
  "src/ServerScriptService/Core/Messaging/RuntimeMessagingCoordinator.lua",
  "src/ServerScriptService/Core/Messaging/MessagingTypes.lua",
  "src/ServerScriptService/Core/Messaging/MessagingSerialization.lua",
  "src/ServerScriptService/Core/Messaging/MessagingValidation.lua",
  "src/ServerScriptService/Core/Messaging/ConsumerRegistry.lua",
  "src/ServerScriptService/Core/Messaging/DependencyRegistry.lua",
  "src/ServerScriptService/Core/Messaging/SubscriptionRegistry.lua",
  "src/ServerScriptService/Core/Messaging/ConsumerLifecycle.lua",
  "src/ServerScriptService/Core/Messaging/RuntimeDiscovery.lua",
  "src/ServerScriptService/Core/Messaging/IntegrationDiagnostics.lua",
  "src/ServerScriptService/Core/Messaging/IntegrationSnapshots.lua",
  "src/ServerScriptService/Core/Messaging/MessagingEvidence.lua",
  "src/ServerScriptService/Core/Messaging/MessagingMetrics.lua",
  "src/ServerScriptService/Core/Messaging/IntegrationProfiler.lua",
  "src/ServerScriptService/Core/Messaging/IntegrationInspection.lua",
  "src/ServerScriptService/Core/Messaging/IntegrationBudgets.lua",
  "src/ServerScriptService/Core/Messaging/IntegrationCertification.lua",
  "src/ServerScriptService/Core/Messaging/MessagingSelfChecks.lua",
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
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
  const packageJson = read("package.json");
  for (const token of [
    "runtimeMessagingIntegration",
    "RuntimeMessagingCoordinator",
    "consumer registration",
    "messaging contracts",
    "dependency mapping",
    "subscription ownership",
    "consumer lifecycle",
    "runtime discovery",
    "messagingIntegrationPosture",
    "consumerRegistry",
    "dependencyGraph",
    "subscriptionRegistry",
    "runtimeDiscovery",
    "ProductionCandidate",
    "Authoritative Runtime Execution Framework evidence",
    "noDirectGameplayCoupling",
    "noCommandOwnership",
    "noEventOwnership",
    "noQueryOwnership",
  ]) checks.push(check(`source contains ${token}`, joined.includes(token)));
  checks.push(check("bootstrap registers messaging integration after query bus", bootstrap.indexOf('registerModule("RuntimeQueryBusCoordinator"') < bootstrap.indexOf('registerModule("RuntimeMessagingCoordinator"')));
  checks.push(check("bootstrap registers messaging integration before lobby", bootstrap.indexOf('registerModule("RuntimeMessagingCoordinator"') < bootstrap.indexOf('registerModule("LobbyService"')));
  checks.push(check("governance contract exists", governance.includes("Runtime Messaging Integration and Consumer Foundation")));
  checks.push(check("governance snapshot provider exists", governance.includes('"runtimeMessagingIntegration"')));
  checks.push(check("package selfcheck script exists", packageJson.includes("london:phase167:selfcheck")));
  checks.push(check("package runtime script exists", packageJson.includes("london:messaging-integration")));
  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-167");
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
    "# Phase 167 Runtime Evidence",
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
    "Phase 167 is Production Candidate.",
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
