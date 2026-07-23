import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 179;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-179");
const reportPath = path.join(evidenceDir, "phase-179-runtime-report.md");
const requiredFiles = [
  "src/ServerScriptService/Presentation/Core/RuntimePresentationRenderingCapability.lua",
  "src/ServerScriptService/Presentation/Core/PresentationRenderingRuntimeCoordinator.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRuntimeCapabilityRegistry.lua",
  "src/ServerScriptService/Presentation/Core/RendererRuntimeRegistry.lua",
  "src/ServerScriptService/Presentation/Core/RenderingSessionRegistry.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRequestIntake.lua",
  "src/ServerScriptService/Presentation/Core/RendererAssignmentManager.lua",
  "src/ServerScriptService/Presentation/Core/RenderingLifecycleManager.lua",
  "src/ServerScriptService/Presentation/Core/RenderingAcknowledgementProducer.lua",
  "src/ServerScriptService/Presentation/Core/RenderingSynchronizationRuntime.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRuntimeDiagnostics.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRuntimeSnapshots.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRuntimeEvidence.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRuntimeMetrics.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRuntimeProfiler.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRuntimeBudgets.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRuntimeValidation.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRuntimeGovernance.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRuntimeCertification.lua",
  "src/ServerScriptService/Presentation/Core/RenderingRuntimeSelfChecks.lua",
];
function read(relativePath) { return fs.readFileSync(path.join(repoRoot, relativePath), "utf8"); }
function exists(relativePath) { return fs.existsSync(path.join(repoRoot, relativePath)); }
function check(name, ok, detail = "") { return { name, ok: Boolean(ok), detail }; }
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
  for (const token of ["presentationRenderingRuntime","presentationRenderingRuntimeCapability","PresentationRenderingRuntimeCoordinator","RuntimePresentationRenderingCapability","RenderingRuntimeCapabilityRegistry","RendererRuntimeRegistry","RenderingSessionRegistry","RendererAssignmentManager","RenderingLifecycleManager","RenderingAcknowledgementProducer","RenderingSynchronizationRuntime","renderingRuntimePosture","noRendering","noGui","noNetworking","noWorkspaceMutation","noClientAuthority","ProductionCandidate"]) {
    checks.push(check(`source contains ${token}`, joined.includes(token) || types.includes(token)));
  }
  checks.push(check("runtime coordinator registers after rendering contract", bootstrap.indexOf('"PresentationRenderingCoordinator"') < bootstrap.indexOf('"PresentationRenderingRuntimeCoordinator"')));
  checks.push(check("runtime coordinator registers before lobby", bootstrap.indexOf('"PresentationRenderingRuntimeCoordinator"') < bootstrap.indexOf('"LobbyService"')));
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase179:selfcheck")));
  checks.push(check("package rendering runtime script exists", packageJson.includes("london:presentation-rendering-runtime")));
  checks.push(check("roadmap records phase 179", roadmap.includes("Phase 179: Presentation Rendering Runtime Capability Foundation")));
  checks.push(check("tasks records phase 179", tasks.includes("Phase 179: Presentation Rendering Runtime Capability Foundation")));
  checks.push(check("engine records phase 179", engine.includes("Phase 179: Presentation Rendering Runtime Capability Foundation")));
  checks.push(check("master context records phase 179", context.includes("Phase 179: Presentation Rendering Runtime Capability Foundation")));
  checks.push(check("governance contract exists", governance.includes("Presentation Rendering Runtime Capability Foundation")));
  checks.push(check("governance provider exists", governance.includes('"presentationRenderingRuntime"')));
  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-179");
    checks.push(check(`phase doc ${prefix}`, fs.existsSync(docsDir) && fs.readdirSync(docsDir).some((name) => name.startsWith(prefix))));
  }
  for (const banned of ['GetService("Data'+'StoreService")','GetService("Messaging'+'Service")','GetService("Http'+'Service")','GetService("Content'+'Provider")','Instance.new("Remote'+'Event")','Instance.new("Remote'+'Function")','Instance.new("Screen'+'Gui")','Instance.new("Text'+'Label")','Instance.new("Image'+'Label")',":Set"+"Async(",":Update"+"Async(",":Get"+"Async(",":Fire"+"Client(",":FireAll"+"Clients(","game."+"Workspace",'GetService("Workspace")']) {
    checks.push(check(`forbidden surface absent ${banned}`, !joined.includes(banned)));
  }
  return checks;
}
function summarize(checks) {
  const failures = checks.filter((item) => !item.ok);
  return { phase, ok: failures.length === 0, total: checks.length, passed: checks.length - failures.length, failed: failures.length, failures };
}
function writeRuntimeReport(summary, runtime) {
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(reportPath, ["# Phase 179 Runtime Evidence","","## Self Checks","",`Total: ${summary.total}`,`Passed: ${summary.passed}`,`Failed: ${summary.failed}`,"","## Runtime Smoke Test","",runtime.status,`Framework used: ${runtime.frameworkUsed}`,`Blocked reason: ${runtime.blockedReason}`,"","## Certification","","Phase 179 is Production Candidate. Authoritative Roblox Studio runtime evidence has not been imported.",""].join("\n"));
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
