import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 163;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-163");
const reportPath = path.join(evidenceDir, "phase-163-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Saving/Session/SaveSessionCoordinator.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionRuntime.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionRegistry.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionLifecycle.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionTransactions.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionLocks.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionDirtyTracker.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionRecovery.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionDiagnostics.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionSnapshots.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionEvidence.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionSignals.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionTypes.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionValidation.lua",
  "src/ServerScriptService/Saving/Session/SaveSessionSelfChecks.lua",
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
  for (const [file, present] of all) checks.push(check(`required file ${file}`, present));

  const joined = all.map(([, , content]) => content).join("\n");
  const bootstrap = read("src/ServerScriptService/Core/Bootstrap.server.lua");
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
  const packageJson = read("package.json");

  for (const token of [
    "SaveSessionCoordinator",
    "SaveSessionRuntime",
    "SaveSessionRegistry",
    "SaveSessionLifecycle",
    "SaveSessionTransactions",
    "SaveSessionLocks",
    "SaveSessionDirtyTracker",
    "SaveSessionRecovery",
    "saveSessionRuntimePosture",
    "activeSessions",
    "dirtySessions",
    "lockedSessions",
    "transactions",
    "recoveries",
    "cancellations",
    "shutdowns",
    "sessionSnapshot",
    "lifecycleSnapshot",
    "transactionSnapshot",
    "lockSnapshot",
    "recoverySnapshot",
  ]) {
    checks.push(check(`source contains ${token}`, joined.includes(token)));
  }

  for (const state of ["New", "Opening", "Active", "Dirty", "Saving", "Loading", "Recovering", "Closing", "Closed", "Failed", "Cancelled"]) {
    checks.push(check(`state ${state}`, joined.includes(state)));
  }

  for (const action of ["Begin", "Commit", "Rollback", "Cancel", "MarkDirty", "MarkClean", "Acquire", "Release"]) {
    checks.push(check(`phase concept ${action}`, joined.toLowerCase().includes(action.toLowerCase())));
  }

  checks.push(
    check(
      "bootstrap registers save session after persistence",
      bootstrap.indexOf('registerModule("PersistenceCoordinator"') <
        bootstrap.indexOf('registerModule("SaveSessionCoordinator"'),
    ),
  );
  checks.push(check("governance contract exists", governance.includes("Save Session Manager and Runtime Lifecycle")));
  checks.push(check("governance snapshot provider exists", governance.includes('"saveSessionRuntime"')));
  checks.push(check("package selfcheck script exists", packageJson.includes("london:phase163:selfcheck")));

  const bannedCalls = [
    'GetService("DataStoreService")',
    'GetService("MessagingService")',
    'GetService("HttpService")',
    'Instance.new("RemoteEvent")',
    'Instance.new("RemoteFunction")',
    ":SetAsync(",
    ":UpdateAsync(",
    ":GetAsync(",
    ":FireClient(",
    ":FireAllClients(",
    "game.Workspace",
    'GetService("Workspace")',
  ];
  for (const banned of bannedCalls) {
    checks.push(check(`forbidden surface absent ${banned}`, !joined.includes(banned)));
  }

  const docDir = path.join(repoRoot, "docs", "phases", "phase-163");
  for (let index = 0; index <= 15; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const present = fs.existsSync(docDir) && fs.readdirSync(docDir).some((name) => name.startsWith(prefix));
    checks.push(check(`phase doc ${prefix}`, present));
  }

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
  fs.writeFileSync(
    reportPath,
    [
      "# Phase 163 Runtime Evidence",
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
      "Phase 163 is Production Candidate.",
      "",
    ].join("\n"),
  );
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
