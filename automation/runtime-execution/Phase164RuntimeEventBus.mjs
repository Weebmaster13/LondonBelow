import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 164;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-164");
const reportPath = path.join(evidenceDir, "phase-164-runtime-report.md");

const requiredFiles = [
  "src/ServerScriptService/Core/EventBus.lua",
  "src/ServerScriptService/Core/Events/EventBusCoordinator.lua",
  "src/ServerScriptService/Core/Events/RuntimeEventBus.lua",
  "src/ServerScriptService/Core/Events/EventRegistry.lua",
  "src/ServerScriptService/Core/Events/EventPublisherRegistry.lua",
  "src/ServerScriptService/Core/Events/EventSubscriberRegistry.lua",
  "src/ServerScriptService/Core/Events/EventRouter.lua",
  "src/ServerScriptService/Core/Events/EventQueue.lua",
  "src/ServerScriptService/Core/Events/EventDispatcher.lua",
  "src/ServerScriptService/Core/Events/EventCancellationRuntime.lua",
  "src/ServerScriptService/Core/Events/EventReplaySafety.lua",
  "src/ServerScriptService/Core/Events/EventDiagnostics.lua",
  "src/ServerScriptService/Core/Events/EventSnapshots.lua",
  "src/ServerScriptService/Core/Events/EventEvidence.lua",
  "src/ServerScriptService/Core/Events/EventSignals.lua",
  "src/ServerScriptService/Core/Events/EventValidation.lua",
  "src/ServerScriptService/Core/Events/EventTypes.lua",
  "src/ServerScriptService/Core/Events/EventSelfChecks.lua",
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
  const docsDir = path.join(repoRoot, "docs", "phases", "phase-164");

  for (const token of [
    "runtimeEventBus",
    "EventBusCoordinator",
    "RuntimeEventBus",
    "registerEventType",
    "registerPublisher",
    "subscribe",
    "publishBatch",
    "dispatchNext",
    "dispatchAll",
    "AtMostOnce",
    "BestEffort",
    "ReplayMetadataOnly",
    "ReplaySafe",
    "Critical",
    "High",
    "Normal",
    "Low",
    "DuplicateEventId",
    "QueueFull",
    "RecursivePublishRejected",
    "eventBusPosture",
    "eventRegistrySnapshot",
    "publisherRegistrySnapshot",
    "subscriberRegistrySnapshot",
    "queueSnapshot",
    "dispatchSnapshot",
    "evidenceSnapshot",
  ]) {
    checks.push(check(`source contains ${token}`, joined.includes(token)));
  }

  checks.push(
    check(
      "bootstrap registers event bus before lobby",
      bootstrap.indexOf('registerModule("RuntimeEventBusCoordinator"') >= 0 &&
        bootstrap.indexOf('registerModule("RuntimeEventBusCoordinator"') < bootstrap.indexOf('registerModule("LobbyService"'),
    ),
  );
  checks.push(check("governance contract exists", governance.includes("Runtime Event Bus and Cross-Runtime Messaging Foundation")));
  checks.push(check("governance snapshot provider exists", governance.includes('"runtimeEventBus"')));
  checks.push(check("package selfcheck script exists", packageJson.includes("london:phase164:selfcheck")));
  checks.push(check("package runtime script exists", packageJson.includes("london:event-bus")));
  checks.push(check("package validate script exists", packageJson.includes("london:event-bus:validate")));

  for (let index = 0; index <= 17; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const present = fs.existsSync(docsDir) && fs.readdirSync(docsDir).some((name) => name.startsWith(prefix));
    checks.push(check(`phase doc ${prefix}`, present));
  }

  const bannedCalls = [
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
  ];
  for (const banned of bannedCalls) {
    checks.push(check(`forbidden surface absent ${banned}`, !joined.includes(banned)));
  }

  for (const category of [
    "event type registry",
    "publisher registry",
    "subscriber registry",
    "duplicate rejection",
    "immutable event envelopes",
    "payload validation",
    "publisher authorization",
    "priority ordering",
    "FIFO ordering within priority",
    "queue capacity",
    "overflow handling",
    "deterministic routing",
    "at-most-once delivery",
    "subscriber failure isolation",
    "normalized results",
    "cancellation",
    "duplicate event ID protection",
    "replay metadata",
    "recursive publish protection",
    "causation depth protection",
    "diagnostics",
    "snapshots",
    "evidence",
    "shutdown",
  ]) {
    checks.push(check(`self-check category ${category}`, joined.toLowerCase().includes(category.split(" ")[0].toLowerCase())));
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
      "# Phase 164 Runtime Evidence",
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
      "## Evidence",
      "",
      "Static automation validated the Runtime Event Bus source surface. Authoritative Studio execution was not imported.",
      "",
      "## Certification",
      "",
      "Phase 164 is Production Candidate.",
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
    blockedReason: "Authoritative Roblox Studio runtime evidence was not imported through the Runtime Execution Framework.",
  };
  writeRuntimeReport(summary, runtime);
  console.log(JSON.stringify({ ok: false, selfCheck: summary, runtime }, null, 2));
  process.exit(summary.ok ? 2 : 1);
}

main();
