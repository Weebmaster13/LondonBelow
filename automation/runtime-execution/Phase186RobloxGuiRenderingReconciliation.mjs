import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const base = "src/StarterPlayer/StarterPlayerScripts/ClientCore/Rendering";
const files = [
  `${base}/RobloxGuiRenderingTypes.lua`,
  `${base}/RobloxGuiRenderingCatalog.lua`,
  `${base}/RobloxGuiValueDecoder.lua`,
  `${base}/RobloxGuiRenderingValidator.lua`,
  `${base}/RobloxGuiInstanceRegistry.lua`,
  `${base}/RobloxGuiRenderTransaction.lua`,
  `${base}/RobloxGuiRenderingRuntime.lua`,
  `${base}/RobloxGuiRenderingController.client.lua`,
  `${base}/README.md`,
];
const docs = ["00_BASELINE.md", "01_ARCHITECTURE.md", "02_CLIENT_AUTHORITY.md", "03_TYPED_VALUES.md", "04_STAGING_AND_COMMIT.md", "05_RECONCILIATION_AND_IDEMPOTENCY.md", "06_ROLLBACK_AND_FAILURES.md", "07_SECURITY_AND_BUDGETS.md", "08_DIAGNOSTICS_AND_GOVERNANCE.md", "09_RUNTIME_TEST_PLAN.md", "10_PRODUCTION_REVIEW.md", "11_COMPLETION_REPORT.md"];
const exists = (file) => fs.existsSync(path.join(root, file));
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
for (const file of files) check(`required file ${file}`, exists(file));
for (const doc of docs) {
  const file = `docs/phases/phase-186/${doc}`;
  check(`required doc ${doc}`, exists(file));
  if (exists(file)) {
    const text = read(file);
    for (const heading of ["## Ownership", "## Non-Ownership", "## Certification Boundary"]) check(`${doc} ${heading}`, text.includes(heading));
  }
}
const source = files.filter((file) => file.endsWith(".lua") && exists(file)).map(read).join("\n");
for (const token of ["Instance.new", "PlayerGui", "RobloxGuiRenderingRuntime", "Transaction.stage", "Transaction.commit", "Idempotent", "RollingBack", "LondonEngineNodeId", "clientPresentationOnly", "noGameplayAuthority", "noNetworking", "maxNodes", "HierarchyCycle"]) check(`source token ${token}`, source.includes(token));
for (const [name, pattern] of [["RemoteEvent", /RemoteEvent/], ["RemoteFunction", /RemoteFunction/], ["remote fire", /Fire(?:Server|Client|AllClients)\s*\(/], ["DataStore", /DataStoreService/], ["HTTP", /HttpService/], ["Workspace", /game:GetService\(["']Workspace["']\)/], ["analytics", /AnalyticsService/], ["telemetry", /TelemetryService/]]) check(`forbidden ${name}`, !pattern.test(source));
const controller = read(`${base}/RobloxGuiRenderingController.client.lua`);
check("controller uses LocalPlayer", controller.includes("Players.LocalPlayer"));
check("controller mounts PlayerGui", controller.includes('WaitForChild("PlayerGui")'));
const runtime = read(`${base}/RobloxGuiRenderingRuntime.lua`);
check("runtime validates before stage", runtime.indexOf("Validator.validate") < runtime.indexOf("Transaction.stage"));
check("runtime stages before commit", runtime.indexOf("Transaction.stage") < runtime.indexOf("Transaction.commit"));
check("registry commits after transaction", runtime.indexOf("Transaction.commit") < runtime.indexOf("Registry.commit"));
const transaction = read(`${base}/RobloxGuiRenderTransaction.lua`);
check("new root mounts before old destroy", transaction.indexOf("transaction.root.Parent = mountTarget") < transaction.lastIndexOf("safeDestroy(previous.root)"));
check("staged cleanup exists", (transaction.match(/safeDestroy/g) || []).length >= 6);
const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
check("governance contract", governance.includes("Roblox GUI Instance Rendering and Reconciliation Runtime"));
check("governance provider", governance.includes("robloxGuiRenderingRuntime"));
const packageJson = read("package.json");
for (const token of ["london:phase186:selfcheck", "london:roblox-gui-rendering", "london:roblox-gui-rendering:validate"]) check(`package ${token}`, packageJson.includes(token));
for (const file of ["ROADMAP.md", "TASKS.md", "LONDON_ENGINE.md", "LONDON_ENGINE_MASTER_CONTEXT.md"]) check(`${file} phase`, read(file).includes("Phase 186: Roblox GUI Instance Rendering and Reconciliation Runtime"));
const failed = checks.filter((item) => !item.ok);
const summary = { phase: 186, ok: failed.length === 0, total: checks.length, passed: checks.length - failed.length, failed: failed.length, failures: failed };
if (process.argv.includes("--runtime")) {
  const directory = path.join(root, "automation", "runtime-evidence", "phase-186");
  fs.mkdirSync(directory, { recursive: true });
  fs.writeFileSync(path.join(directory, "phase-186-runtime-report.md"), `# Phase 186 Runtime Evidence\n\nStatic checks: ${summary.passed}/${summary.total}\n\nRuntime: executionBlocked\n\nThe concrete renderer requires authoritative Roblox Studio client evidence. No evidence was imported, so Phase 186 remains Production Candidate.\n`);
  console.log(JSON.stringify({ ok: false, selfCheck: summary, runtime: { status: "executionBlocked", executionBlocked: true, runnerInvoked: false, structuredResultCaptured: false } }, null, 2));
  process.exit(summary.ok ? 2 : 1);
}
console.log(JSON.stringify(summary, null, 2));
process.exit(summary.ok ? 0 : 1);
