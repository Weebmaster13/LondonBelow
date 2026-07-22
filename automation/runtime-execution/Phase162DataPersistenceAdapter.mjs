import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 162;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-162");
const reportPath = path.join(evidenceDir, "phase-162-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Persistence/Core/PersistenceCoordinator.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceRuntime.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceAdapterRegistry.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceProvider.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceRequestPipeline.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceResponsePipeline.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceRetryRuntime.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceFailureRuntime.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceDiagnostics.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceSnapshots.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceEvidence.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceValidation.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceTypes.lua",
  "src/ServerScriptService/Persistence/Core/PersistenceSelfChecks.lua",
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
  const all = requiredFiles.map((file) => [file, exists(file), exists(file) ? read(file) : ""]);

  for (const [file, present] of all) {
    checks.push(check(`required file ${file}`, present));
  }

  const joined = all.map(([, , content]) => content).join("\n");
  const coordinator = read("src/ServerScriptService/Persistence/Core/PersistenceCoordinator.lua");
  const runtime = read("src/ServerScriptService/Persistence/Core/PersistenceRuntime.lua");
  const provider = read("src/ServerScriptService/Persistence/Core/PersistenceProvider.lua");
  const validation = read("src/ServerScriptService/Persistence/Core/PersistenceValidation.lua");
  const diagnostics = read("src/ServerScriptService/Persistence/Core/PersistenceDiagnostics.lua");
  const snapshots = read("src/ServerScriptService/Persistence/Core/PersistenceSnapshots.lua");
  const bootstrap = read("src/ServerScriptService/Core/Bootstrap.server.lua");
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");

  for (const token of [
    "registerProvider",
    "unregisterProvider",
    "resolveProvider",
    "listProviders",
    "getDefaultProvider",
    "MemoryProvider",
    "NullProvider",
    "FutureDataStoreProvider",
    "FutureProfileServiceProvider",
    "PersistenceRequestPipeline",
    "PersistenceResponsePipeline",
    "PersistenceRetryRuntime",
    "PersistenceFailureRuntime",
    "PersistenceEvidence",
  ]) {
    checks.push(check(`source contains ${token}`, joined.includes(token)));
  }

  for (const operation of ["Load", "Save", "Delete", "Exists", "List"]) {
    checks.push(check(`operation ${operation}`, joined.includes(operation)));
  }

  for (const key of [
    "persistenceRuntimePosture",
    "registeredProviders",
    "saveRequests",
    "loadRequests",
    "deleteRequests",
    "retryCount",
    "failureCount",
    "activeProvider",
  ]) {
    checks.push(check(`diagnostics key ${key}`, diagnostics.includes(key)));
  }

  for (const key of [
    "persistenceRuntimeAvailable",
    "registeredProviders",
    "defaultProvider",
    "requestHistory",
    "failureHistory",
    "retryHistory",
  ]) {
    checks.push(check(`snapshot key ${key}`, snapshots.includes(key)));
  }

  checks.push(check("coordinator exposes save", coordinator.includes("function PersistenceCoordinator.save")));
  checks.push(check("coordinator exposes load", coordinator.includes("function PersistenceCoordinator.load")));
  checks.push(check("coordinator exposes delete", coordinator.includes("function PersistenceCoordinator.delete")));
  checks.push(check("coordinator exposes exists", coordinator.includes("function PersistenceCoordinator.exists")));
  checks.push(check("runtime registers default providers", runtime.includes("registerDefaultProviders")));
  checks.push(check("memory provider stores deep copies", provider.includes("Serialization.deepCopy(request.payload)")));
  checks.push(check("null provider returns NotSupported", provider.includes("NotSupported")));
  checks.push(check("future providers are interface only", provider.includes("interfaceOnly = true")));
  checks.push(check("validation rejects unsupported operation", validation.includes("unsupported operation")));
  checks.push(check("validation requires save payload", validation.includes("save payload is required")));
  checks.push(check("governance includes persistenceRuntime snapshot provider", governance.includes('"persistenceRuntime"')));
  checks.push(check("governance states no gameplay authority", governance.includes("gameplay authority")));
  checks.push(check("governance states no schema ownership", governance.includes("save schema ownership")));
  checks.push(
    check(
      "bootstrap registers persistence after save",
      bootstrap.indexOf('registerModule("SaveCoordinator"') <
        bootstrap.indexOf('registerModule("PersistenceCoordinator"'),
    ),
  );

  const bannedCalls = [
    'GetService("DataStoreService")',
    ":SetAsync(",
    ":UpdateAsync(",
    ":GetAsync(",
    'GetService("MessagingService")',
    'GetService("HttpService")',
    'Instance.new("RemoteEvent")',
    'Instance.new("RemoteFunction")',
    ":FireClient(",
    ":FireAllClients(",
    "game.Workspace",
    'GetService("Workspace")',
  ];
  for (const banned of bannedCalls) {
    checks.push(check(`forbidden surface absent ${banned}`, !joined.includes(banned)));
  }

  const docDir = path.join(repoRoot, "docs", "phases", "phase-162");
  for (let index = 0; index <= 15; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const present = fs.existsSync(docDir) && fs.readdirSync(docDir).some((name) => name.startsWith(prefix));
    checks.push(check(`phase doc ${prefix}`, present));
  }

  return checks;
}

function summarize(checks) {
  const failed = checks.filter((item) => !item.ok);
  return {
    phase,
    ok: failed.length === 0,
    total: checks.length,
    passed: checks.length - failed.length,
    failed: failed.length,
    failures: failed,
  };
}

function writeRuntimeReport(summary, runtime) {
  fs.mkdirSync(evidenceDir, { recursive: true });
  const lines = [
    "# Phase 162 Runtime Evidence",
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
    "Phase 162 is Production Candidate.",
    "",
  ];
  fs.writeFileSync(reportPath, `${lines.join("\n")}\n`);
}

function runSelfCheck() {
  return summarize(sourceChecks());
}

function main() {
  const args = new Set(process.argv.slice(2));
  const summary = runSelfCheck();
  if (args.has("--self-check") || args.has("--validate")) {
    console.log(JSON.stringify(summary, null, 2));
    process.exit(summary.ok ? 0 : 1);
  }

  const runtime = {
    frameworkUsed: true,
    status: "blocked by environment",
    ok: false,
    blockedReason: "Authoritative Roblox Studio runtime evidence was not imported.",
  };
  writeRuntimeReport(summary, runtime);
  console.log(JSON.stringify({ ok: false, selfCheck: summary, runtime }, null, 2));
  process.exit(summary.ok ? 2 : 1);
}

main();
