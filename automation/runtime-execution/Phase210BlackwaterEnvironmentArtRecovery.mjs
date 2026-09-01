import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const exists = (target) => fs.existsSync(path.join(root, target));
const read = (target) => fs.readFileSync(path.join(root, target), "utf8");
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });

const evidenceRoot = "automation/runtime-evidence/phase-210-recovery";
const docsRoot = "docs/phases/phase-210-recovery";

const requiredFiles = [
  "src/ReplicatedStorage/Config/BlackwaterEnvironmentArtConfig.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/Chapter196WorldBuilder.lua",
  `${evidenceRoot}/baseline-audit.json`,
  `${evidenceRoot}/environment-art-inventory.json`,
  `${evidenceRoot}/proxy-removal-register.md`,
  `${evidenceRoot}/visual-defect-log.json`,
  `${evidenceRoot}/studio-evidence.json`,
  `${evidenceRoot}/performance-evidence.json`,
  `${evidenceRoot}/validation-summary.json`,
  `${evidenceRoot}/validation-report.md`,
  `${docsRoot}/README.md`,
  `${docsRoot}/00_BASELINE.md`,
  `${docsRoot}/01_ENVIRONMENT_ART_IMPLEMENTATION.md`,
  `${docsRoot}/02_LIGHTING_AND_ATMOSPHERE.md`,
  `${docsRoot}/03_EVIDENCE_AND_BLOCKERS.md`,
  `${docsRoot}/04_COMPLETION_REPORT.md`,
];

for (const file of requiredFiles) check(`required file ${file}`, exists(file));

const config = exists(requiredFiles[0]) ? read(requiredFiles[0]) : "";
const builder = exists(requiredFiles[1]) ? read(requiredFiles[1]) : "";

for (const space of [
  "Arrival street",
  "Blackwater approach",
  "Alley",
  "Gate",
  "House facade",
  "Front steps",
  "Threshold",
  "Entry hall",
  "First investigation spaces",
  "Main corridor",
  "Archive",
  "Ward chamber",
  "Basement",
  "Glass Heart chamber",
  "Blackout route",
  "Dawn exterior",
]) {
  check(`finished space ${space}`, config.includes(`"${space}"`));
}

check("route dressing count >= 28", (config.match(/id = "/g) || []).length >= 28);
check("light anchor count >= 4", (config.match(/Phase210AuthoredLight|LightAnchors|brightness/g) || []).length >= 4);
check("evidence keeps screenshots blocked", config.includes("beforeAfterScreenshots = false"));
check("evidence keeps Studio blocked", config.includes("studioRouteExecuted = false"));
check("evidence keeps performance blocked", config.includes("performanceCaptured = false"));
check("evidence keeps final asset review blocked", config.includes("finalAssetReviewComplete = false"));

for (const token of [
  "BlackwaterEnvironmentArtConfig",
  "buildPhase210EnvironmentArt",
  "Phase210EnvironmentArt",
  "authoredProceduralProductionCandidate",
  "Phase210LightAnchors",
  "Phase210AuthoredLight",
  "FinishedSpaceCount",
  "RouteDressingCount",
]) {
  check(`world builder token ${token}`, builder.includes(token));
}

const inventory = exists(`${evidenceRoot}/environment-art-inventory.json`)
  ? JSON.parse(read(`${evidenceRoot}/environment-art-inventory.json`))
  : {};
check("inventory completion tier static candidate", inventory.completionTier === "Static Production Candidate");
check("inventory records 16 spaces", Array.isArray(inventory.finishedSpaces) && inventory.finishedSpaces.length === 16);
check("inventory records 28+ dressings", Array.isArray(inventory.routeDressings) && inventory.routeDressings.length >= 28);
check("inventory records no final screenshots", inventory.evidence?.beforeAfterScreenshots === false);

const defects = exists(`${evidenceRoot}/visual-defect-log.json`)
  ? JSON.parse(read(`${evidenceRoot}/visual-defect-log.json`))
  : { defects: [] };
check("defects record Studio screenshot blocker", defects.defects?.some((defect) => defect.id === "P210-STUDIO-SCREENSHOTS-BLOCKED"));
check("defects record performance blocker", defects.defects?.some((defect) => defect.id === "P210-PERFORMANCE-CAPTURE-BLOCKED"));

const studio = exists(`${evidenceRoot}/studio-evidence.json`)
  ? JSON.parse(read(`${evidenceRoot}/studio-evidence.json`))
  : {};
check("studio remains blocked truthfully", studio.status === "studioBlocked" && studio.executed === false);

const performance = exists(`${evidenceRoot}/performance-evidence.json`)
  ? JSON.parse(read(`${evidenceRoot}/performance-evidence.json`))
  : {};
check("performance remains unknown truthfully", performance.status === "performanceUnknown" && performance.measured === false);

const docs = requiredFiles.filter((file) => file.endsWith(".md") && exists(file)).map(read).join("\n");
for (const token of [
  "Phase 210 Individual Production Completion Pass",
  "Static Production Candidate",
  "authored procedural environment art",
  "Studio screenshots were not captured",
  "performance capture was not executed",
  "Phase 211 is not authorized",
]) {
  check(`docs mention ${token}`, docs.includes(token));
}

const sourceDelta = [
  "src/ReplicatedStorage/Config/BlackwaterEnvironmentArtConfig.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/Chapter196WorldBuilder.lua",
].filter(exists).map(read).join("\n");

for (const [name, pattern] of [
  ["DataStore", /DataStoreService/],
  ["HTTP service", /HttpService/],
  ["Messaging", /MessagingService/],
  ["RemoteEvent creation", /Instance\.new\("RemoteEvent"\)/],
  ["RemoteFunction creation", /Instance\.new\("RemoteFunction"\)/],
  ["client server call", /FireServer|InvokeServer/],
  ["dynamic code", /loadstring/],
  ["analytics", /AnalyticsService/],
  ["telemetry", /TelemetryService/],
]) {
  check(`forbidden ${name}`, !pattern.test(sourceDelta));
}

const failed = checks.filter((item) => !item.ok);
const report = {
  phase: 210,
  correctivePhase: "Phase 210 Individual Production Completion Pass",
  status: failed.length === 0 ? "passed" : "failed",
  completionTier: "Static Production Candidate",
  total: checks.length,
  passed: checks.length - failed.length,
  failed: failed.length,
  failures: failed,
  blocker: "Roblox Studio screenshots, route walkthrough, low-quality comparison, final-art review, and performance capture are not available in this task.",
  nextPhaseAuthorized: false,
};

console.log(JSON.stringify(report, null, 2));
process.exit(failed.length === 0 ? 0 : 1);
