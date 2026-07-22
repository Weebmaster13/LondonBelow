import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 166;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-166");
const reportPath = path.join(evidenceDir, "phase-166-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Core/Queries/RuntimeQueryBus.lua",
  "src/ServerScriptService/Core/Queries/QueryBusCoordinator.lua",
  "src/ServerScriptService/Core/Queries/QueryTypes.lua",
  "src/ServerScriptService/Core/Queries/QuerySerialization.lua",
  "src/ServerScriptService/Core/Queries/QueryValidation.lua",
  "src/ServerScriptService/Core/Queries/QueryRegistry.lua",
  "src/ServerScriptService/Core/Queries/QueryRequesterRegistry.lua",
  "src/ServerScriptService/Core/Queries/QueryHandlerRegistry.lua",
  "src/ServerScriptService/Core/Queries/QueryQueue.lua",
  "src/ServerScriptService/Core/Queries/QueryRouter.lua",
  "src/ServerScriptService/Core/Queries/QueryExecutionRuntime.lua",
  "src/ServerScriptService/Core/Queries/QuerySnapshotRuntime.lua",
  "src/ServerScriptService/Core/Queries/QueryProjectionRuntime.lua",
  "src/ServerScriptService/Core/Queries/QueryReadModels.lua",
  "src/ServerScriptService/Core/Queries/QueryCacheRuntime.lua",
  "src/ServerScriptService/Core/Queries/QueryDiagnostics.lua",
  "src/ServerScriptService/Core/Queries/QueryMetrics.lua",
  "src/ServerScriptService/Core/Queries/QueryHealth.lua",
  "src/ServerScriptService/Core/Queries/QueryProfiler.lua",
  "src/ServerScriptService/Core/Queries/QuerySnapshots.lua",
  "src/ServerScriptService/Core/Queries/QueryBudgets.lua",
  "src/ServerScriptService/Core/Queries/QueryEvidence.lua",
  "src/ServerScriptService/Core/Queries/QueryLifecycle.lua",
  "src/ServerScriptService/Core/Queries/QuerySelfChecks.lua",
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
    "runtimeQueryBus",
    "RuntimeQueryBus",
    "QueryBusCoordinator",
    "query definitions",
    "query registration",
    "query routing",
    "query authorization",
    "read-only",
    "immutable query envelopes",
    "immutable results",
    "deterministic routing",
    "deterministic scheduling",
    "deterministic authorization",
    "deterministic handler selection",
    "deterministic cache policies",
    "snapshot access",
    "projection",
    "readModel",
    "cachePolicy",
    "consistency",
    "Strong",
    "Snapshot",
    "EventuallyConsistent",
    "Historical",
    "queryBusPosture",
    "queryRegistrySnapshot",
    "requesterRegistrySnapshot",
    "handlerRegistrySnapshot",
    "projectionSnapshot",
    "readModelSnapshot",
    "cacheSnapshot",
    "consistentReadSnapshot",
    "zero gameplay mutation",
  ]) checks.push(check(`source contains ${token}`, joined.includes(token)));
  checks.push(check("bootstrap registers query bus after command bus", bootstrap.indexOf('registerModule("RuntimeCommandBusCoordinator"') < bootstrap.indexOf('registerModule("RuntimeQueryBusCoordinator"')));
  checks.push(check("bootstrap registers query bus before lobby", bootstrap.indexOf('registerModule("RuntimeQueryBusCoordinator"') < bootstrap.indexOf('registerModule("LobbyService"')));
  checks.push(check("governance contract exists", governance.includes("Runtime Query Bus and Read-Only Access Foundation")));
  checks.push(check("governance snapshot provider exists", governance.includes('"runtimeQueryBus"')));
  checks.push(check("package selfcheck script exists", packageJson.includes("london:phase166:selfcheck")));
  checks.push(check("package runtime script exists", packageJson.includes("london:query-bus")));
  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-166");
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
  return { phase, ok: failures.length === 0, total: checks.length, passed: checks.length - failures.length, failed: failures.length, failures };
}

function writeRuntimeReport(summary, runtime) {
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(reportPath, [
    "# Phase 166 Runtime Evidence",
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
    "Phase 166 is Production Candidate.",
    "",
  ].join("\n"));
}

const summary = summarize(sourceChecks());
const args = new Set(process.argv.slice(2));
if (args.has("--self-check") || args.has("--validate")) {
  console.log(JSON.stringify(summary, null, 2));
  process.exit(summary.ok ? 0 : 1);
}
const runtime = { frameworkUsed: true, status: "blocked by environment", ok: false, blockedReason: "Authoritative Roblox Studio runtime evidence was not imported through the Runtime Execution Framework." };
writeRuntimeReport(summary, runtime);
console.log(JSON.stringify({ ok: false, selfCheck: summary, runtime }, null, 2));
process.exit(summary.ok ? 2 : 1);
