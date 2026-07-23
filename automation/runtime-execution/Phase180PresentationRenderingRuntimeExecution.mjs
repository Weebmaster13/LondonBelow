import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const phase = 180;
const evidenceDir = path.join(repoRoot, "automation", "runtime-evidence", "phase-180");
const reportPath = path.join(evidenceDir, "phase-180-runtime-report.md");
const requiredFiles = [
  "src/ServerScriptService/Presentation/Core/RuntimePresentationRenderingExecution.lua",
  "src/ServerScriptService/Presentation/Core/PresentationRenderingExecutionCoordinator.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionScheduler.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionQueue.lua",
  "src/ServerScriptService/Presentation/Core/RendererExecutionRegistry.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionSessionRegistry.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionLifecycle.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionRecovery.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionAcknowledgements.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionSynchronization.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionDiagnostics.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionSnapshots.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionEvidence.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionMetrics.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionProfiler.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionBudgets.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionValidation.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionGovernance.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionCertification.lua",
  "src/ServerScriptService/Presentation/Core/RenderingExecutionSelfChecks.lua",
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
  for (const token of ["presentationRenderingExecution","presentationRenderingExecutionRuntime","PresentationRenderingExecutionCoordinator","RuntimePresentationRenderingExecution","RenderingExecutionScheduler","RenderingExecutionQueue","RendererExecutionRegistry","RenderingExecutionSessionRegistry","RenderingExecutionLifecycle","RenderingExecutionRecovery","RenderingExecutionAcknowledgements","RenderingExecutionSynchronization","RenderingExecutionAcknowledgementKind","renderingExecutionPosture","noRendering","noGui","noNetworking","noWorkspaceMutation","noClientAuthority","ProductionCandidate"]) {
    checks.push(check(`source contains ${token}`, joined.includes(token) || types.includes(token)));
  }
  checks.push(check("execution coordinator registers after rendering runtime", bootstrap.indexOf('"PresentationRenderingRuntimeCoordinator"') < bootstrap.indexOf('"PresentationRenderingExecutionCoordinator"')));
  checks.push(check("execution coordinator registers before lobby", bootstrap.indexOf('"PresentationRenderingExecutionCoordinator"') < bootstrap.indexOf('"LobbyService"')));
  checks.push(check("package phase selfcheck script exists", packageJson.includes("london:phase180:selfcheck")));
  checks.push(check("package rendering execution script exists", packageJson.includes("london:presentation-rendering-execution")));
  checks.push(check("roadmap records phase 180", roadmap.includes("Phase 180: Presentation Rendering Runtime Execution and Renderer Session Management")));
  checks.push(check("tasks records phase 180", tasks.includes("Phase 180: Presentation Rendering Runtime Execution and Renderer Session Management")));
  checks.push(check("engine records phase 180", engine.includes("Phase 180: Presentation Rendering Runtime Execution and Renderer Session Management")));
  checks.push(check("master context records phase 180", context.includes("Phase 180: Presentation Rendering Runtime Execution and Renderer Session Management")));
  checks.push(check("governance contract exists", governance.includes("Presentation Rendering Runtime Execution and Renderer Session Management")));
  checks.push(check("governance provider exists", governance.includes('"presentationRenderingExecution"')));
  for (let index = 0; index <= 10; index += 1) {
    const prefix = String(index).padStart(2, "0");
    const docsDir = path.join(repoRoot, "docs", "phases", "phase-180");
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
  fs.writeFileSync(reportPath, ["# Phase 180 Runtime Evidence","","## Self Checks","",`Total: ${summary.total}`,`Passed: ${summary.passed}`,`Failed: ${summary.failed}`,"","## Runtime Smoke Test","",runtime.status,`Framework used: ${runtime.frameworkUsed}`,`Blocked reason: ${runtime.blockedReason}`,"","## Certification","","Phase 180 is Production Candidate. Authoritative Roblox Studio runtime evidence has not been imported.",""].join("\n"));
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
