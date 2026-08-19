import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const base = "src/StarterPlayer/StarterPlayerScripts/ClientCore/Rendering";
const required = [
  "RobloxGuiRenderingTypes.lua", "RobloxGuiRenderingCatalog.lua", "RobloxGuiValueDecoder.lua",
  "RobloxGuiRenderingValidator.lua", "RobloxGuiIntegrityGuard.lua", "RobloxGuiInstanceRegistry.lua",
  "RobloxGuiRenderTransaction.lua", "RobloxGuiRenderingRuntime.lua", "RobloxGuiRenderingController.client.lua", "README.md",
].map((name) => `${base}/${name}`);
const docs = ["00_BASELINE.md", "01_THREAT_MODEL.md", "02_CONTRACT_HARDENING.md", "03_REVISION_AND_IDEMPOTENCY.md", "04_OWNERSHIP_AND_INTEGRITY.md", "05_FAILURE_INJECTION.md", "06_BUDGETS_AND_PERFORMANCE.md", "07_STUDIO_TEST_MATRIX.md", "08_EVIDENCE_IMPORT.md", "09_GOVERNANCE.md", "10_PRODUCTION_REVIEW.md", "11_COMPLETION_REPORT.md"];
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
const exists = (file) => fs.existsSync(path.join(root, file));
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");

for (const file of required) check(`required file ${file}`, exists(file));
for (const doc of docs) {
  const file = `docs/phases/phase-187/${doc}`;
  check(`required doc ${doc}`, exists(file));
  if (exists(file)) for (const heading of ["## Ownership", "## Non-Ownership", "## Certification Boundary"]) check(`${doc} ${heading}`, read(file).includes(heading));
}
const source = required.filter((file) => file.endsWith(".lua") && exists(file)).map(read).join("\n");
for (const token of ["187.1.0", "StaleRevision", "IntegrityViolation", "OwnershipViolation", "maxContractBytes", "maxTagsPerNode", "exactFields", "verifyIntegrity", "owned-tree-cardinality-changed", "IntegrityVerified"]) check(`hardening token ${token}`, source.includes(token));
for (const [name, pattern] of [["RemoteEvent", /RemoteEvent/], ["RemoteFunction", /RemoteFunction/], ["remote fire", /Fire(?:Server|Client|AllClients)\s*\(/], ["DataStore", /DataStoreService/], ["HTTP", /HttpService/], ["Workspace", /game:GetService\(["']Workspace["']\)/], ["analytics", /AnalyticsService/], ["telemetry", /TelemetryService/]]) check(`forbidden ${name}`, !pattern.test(source));
const validator = read(`${base}/RobloxGuiRenderingValidator.lua`);
check("exact contract fields precede node processing", validator.indexOf("exactFields(contract") < validator.indexOf("for _, node"));
check("single PlayerGui root enforced", validator.includes("node.parentNodeId == \"PlayerGui\""));
const runtimeSource = read(`${base}/RobloxGuiRenderingRuntime.lua`);
check("stale check precedes staging", runtimeSource.indexOf("StaleRevision") < runtimeSource.indexOf("Transaction.stage"));
check("integrity check precedes staging", runtimeSource.indexOf("IntegrityGuard.verify") < runtimeSource.indexOf("Transaction.stage"));
const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
check("governance contract", governance.includes("Roblox GUI Rendering Runtime Production Hardening and Studio Certification"));
check("governance provider", governance.includes("robloxGuiRenderingHardeningRuntime"));
for (const file of ["ROADMAP.md", "TASKS.md", "LONDON_ENGINE.md", "LONDON_ENGINE_MASTER_CONTEXT.md"]) check(`${file} phase`, read(file).includes("Phase 187: Roblox GUI Rendering Runtime Production Hardening and Studio Certification"));

const evidencePath = path.join(root, "automation/runtime-evidence/phase-187/studio-result.json");
let runtime = { status: "executionBlocked", executionBlocked: true, authoritative: false };
if (fs.existsSync(evidencePath)) {
  try {
    const evidence = JSON.parse(fs.readFileSync(evidencePath, "utf8"));
    const valid = evidence.schemaVersion === 1 && evidence.phase === 187 && evidence.environment === "RobloxStudio" && evidence.authoritative === true && evidence.passed === true && typeof evidence.runId === "string" && evidence.runId.length > 0 && Array.isArray(evidence.tests) && evidence.tests.length >= 12 && evidence.tests.every((test) => test && test.passed === true);
    runtime = valid ? { status: "passed", executionBlocked: false, authoritative: true, runId: evidence.runId, testCount: evidence.tests.length } : { status: "evidenceRejected", executionBlocked: true, authoritative: false };
  } catch { runtime = { status: "evidenceRejected", executionBlocked: true, authoritative: false }; }
}
const failed = checks.filter((item) => !item.ok);
const summary = { phase: 187, ok: failed.length === 0, total: checks.length, passed: checks.length - failed.length, failed: failed.length, failures: failed };
if (process.argv.includes("--runtime")) {
  const directory = path.join(root, "automation/runtime-evidence/phase-187");
  fs.mkdirSync(directory, { recursive: true });
  fs.writeFileSync(path.join(directory, "phase-187-runtime-report.md"), `# Phase 187 Runtime Evidence\n\nStatic checks: ${summary.passed}/${summary.total}\n\nRuntime: ${runtime.status}\n\nAuthoritative Roblox Studio evidence: ${runtime.authoritative ? "accepted" : "not imported"}\n`);
  console.log(JSON.stringify({ ok: summary.ok && runtime.status === "passed", selfCheck: summary, runtime }, null, 2));
  process.exit(summary.ok && runtime.status === "passed" ? 0 : summary.ok ? 2 : 1);
}
console.log(JSON.stringify(summary, null, 2));
process.exit(summary.ok ? 0 : 1);
