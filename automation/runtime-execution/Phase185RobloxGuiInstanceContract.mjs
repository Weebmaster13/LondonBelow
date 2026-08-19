import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const files = [
  "src/ServerScriptService/Presentation/Core/RobloxGuiInstanceContractTypes.lua",
  "src/ServerScriptService/Presentation/Core/RobloxGuiInstanceCatalog.lua",
  "src/ServerScriptService/Presentation/Core/RobloxGuiInstanceContractValidation.lua",
  "src/ServerScriptService/Presentation/Core/RobloxGuiInstanceContractSecurity.lua",
  "src/ServerScriptService/Presentation/Core/RobloxGuiInstanceContractAccessibility.lua",
  "src/ServerScriptService/Presentation/Core/RobloxGuiInstanceContractResponsive.lua",
  "src/ServerScriptService/Presentation/Core/RuntimeRobloxGuiInstanceContract.lua",
  "src/ServerScriptService/Presentation/Core/RobloxGuiInstanceContractSelfChecks.lua",
  "src/ServerScriptService/Presentation/Core/RobloxGuiInstanceContractCoordinator.lua",
];
const docs = ["00_BASELINE.md", "01_ARCHITECTURE.md", "02_SCHEMA_AND_CATALOG.md", "03_SECURITY_ACCESSIBILITY_RESPONSIVE.md", "04_LIFECYCLE_AND_PUBLICATION.md", "05_VALIDATION_AND_FAILURES.md", "06_GOVERNANCE_AND_CERTIFICATION.md", "07_PRODUCTION_REVIEW.md", "08_COMPLETION_REPORT.md"];
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
for (const file of files) check(`required file ${file}`, fs.existsSync(path.join(root, file)));
for (const doc of docs) {
  const file = path.join("docs", "phases", "phase-185", doc);
  check(`required doc ${doc}`, fs.existsSync(path.join(root, file)));
  if (fs.existsSync(path.join(root, file))) {
    const text = read(file);
    check(`${doc} ownership`, text.includes("## Ownership"));
    check(`${doc} non-ownership`, text.includes("## Non-Ownership"));
    check(`${doc} certification`, text.includes("## Certification Boundary"));
  }
}
const source = files.filter((file) => fs.existsSync(path.join(root, file))).map(read).join("\n");
for (const token of ["ScreenGui", "TextButton", "ImageButton", "UIListLayout", "PropertyMutability", "UnsupportedClass", "InvalidHierarchy", "noInstanceCreation", "noGuiMutation", "Published", "Retired"]) check(`source token ${token}`, source.includes(token));
const bootstrap = read("src/ServerScriptService/Core/Bootstrap.server.lua");
check("bootstrap coordinator exists", bootstrap.includes("RobloxGuiInstanceContractCoordinator"));
check("bootstrap order", bootstrap.indexOf('"RobloxVisualCompositionExecutionCoordinator"') < bootstrap.indexOf('"RobloxGuiInstanceContractCoordinator"'));
check("bootstrap before lobby", bootstrap.indexOf('"RobloxGuiInstanceContractCoordinator"') < bootstrap.indexOf('"LobbyService"'));
const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua");
check("governance contract", governance.includes("Roblox GUI Instance Contract Foundation"));
check("governance provider", governance.includes("robloxGuiInstanceContractRuntime"));
const packageJson = read("package.json");
check("selfcheck command", packageJson.includes("london:phase185:selfcheck"));
check("runtime command", packageJson.includes("london:roblox-gui-instance-contract"));
for (const file of ["ROADMAP.md", "TASKS.md", "LONDON_ENGINE.md", "LONDON_ENGINE_MASTER_CONTEXT.md"]) check(`${file} phase`, read(file).includes("Phase 185: Roblox GUI Instance Contract Foundation"));
const executable = files.filter((file) => !file.endsWith("Catalog.lua") && !file.endsWith("Types.lua") && !file.endsWith("SelfChecks.lua")).map(read).join("\n");
for (const [name, pattern] of [["Instance creation", /Instance\.new\s*\(/], ["remote firing", /Fire(?:Client|AllClients|Server)\s*\(/], ["HTTP", /HttpService/], ["DataStore", /DataStoreService/], ["analytics", /AnalyticsService/]]) check(`forbidden ${name}`, !pattern.test(executable));
const failed = checks.filter((item) => !item.ok);
const summary = { phase: 185, ok: failed.length === 0, total: checks.length, passed: checks.length - failed.length, failed: failed.length, failures: failed };
if (process.argv.includes("--runtime")) {
  const dir = path.join(root, "automation", "runtime-evidence", "phase-185");
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, "phase-185-runtime-report.md"), `# Phase 185 Runtime Evidence\n\nStatic checks: ${summary.passed}/${summary.total}\n\nRuntime: executionBlocked\n\nAuthoritative Roblox Studio evidence has not been imported. Phase 185 remains Production Candidate.\n`);
  console.log(JSON.stringify({ ok: false, selfCheck: summary, runtime: { status: "executionBlocked", executionBlocked: true, runnerInvoked: false, structuredResultCaptured: false } }, null, 2));
  process.exit(summary.ok ? 2 : 1);
}
console.log(JSON.stringify(summary, null, 2));
process.exit(summary.ok ? 0 : 1);
