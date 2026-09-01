import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const read = (target) => fs.readFileSync(path.join(root, target), "utf8");
const exists = (target) => fs.existsSync(path.join(root, target));
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });

const sourceFiles = [
  "src/ReplicatedStorage/Config/BlackwaterFinalQualityProgramConfig.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterFinalQualityProgramRuntime.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterProductionCoordinator.lua",
  "src/StarterPlayer/StarterPlayerScripts/ClientCore/VerticalSlice/Chapter196HudController.client.lua",
];

const evidenceFiles = [
  "automation/runtime-evidence/phase-220/final-quality-scorecard.json",
  "automation/runtime-evidence/phase-220/quality-gate-report.md",
  "automation/runtime-evidence/phase-220/defect-log.json",
  "automation/runtime-evidence/phase-220/studio-evidence.json",
  "automation/runtime-evidence/phase-220/human-playtest-evidence.json",
  "automation/runtime-evidence/phase-220/performance-evidence.json",
  "automation/runtime-evidence/phase-220/validation-summary.json",
  "automation/runtime-evidence/phase-220/validation-report.md",
];

for (const file of [...sourceFiles, ...evidenceFiles]) {
  check(`required file ${file}`, exists(file));
}

const source = sourceFiles.filter(exists).map(read).join("\n");

for (const token of [
  "BlackwaterFinalQualityProgramConfig",
  "BlackwaterFinalQualityProgramRuntime",
  "QualityPillars",
  "AudibleWorld",
  "EnvironmentLayers",
  "ExplorationSecrets",
  "PuzzleProduction",
  "NarrativeBeats",
  "HorrorPacing",
  "MultiplayerRules",
  "AccessibilityEquivalents",
  "ReplayVariations",
  "PerformanceBudgets",
  "PlaytestProtocol",
  "ReleaseCandidateGates",
  "Phase220QualityGate",
  "sourceIntegratedRuntimeBlocked",
]) {
  check(`program token ${token}`, source.includes(token));
}

const config = exists(sourceFiles[0]) ? read(sourceFiles[0]) : "";
check("phases 209-220 present", (config.match(/phase = 2(09|1[0-9]|20)/g) || []).length >= 12);
check("five quality pillars present", (config.match(/The World Remembers|The Street Listens|Authority Has Become Monstrous|Knowledge Has a Cost|Dawn Is Not Safety/g) || []).length >= 5);
check("audible world cues present", (config.match(/family = "/g) || []).length >= 16);
check("environment layers present", (config.match(/layer = "/g) || []).length >= 7);
check("exploration secrets present", (config.match(/method = "/g) || []).length >= 4);
check("puzzle production entries present", (config.match(/hintLevels/g) || []).length >= 3);
check("narrative beats present", (config.match(/essential = true/g) || []).length >= 5);
check("horror pacing segments present", (config.match(/segment = "/g) || []).length >= 5);
check("multiplayer rules present", (config.match(/scope = "/g) || []).length >= 5);
check("accessibility equivalents present", (config.match(/reducedMotion = "/g) || []).length >= 5);
check("playtest protocol present", (config.match(/\?"/g) || []).length >= 7);
check("release candidate remains blocked honestly", config.includes("studioRoute = false") && config.includes("performanceMeasured = false"));

for (let phase = 209; phase <= 220; phase += 1) {
  const dir = path.join(root, "docs", "phases", `phase-${phase}`);
  check(`phase ${phase} docs exist`, fs.existsSync(dir));
  check(`phase ${phase} README exists`, fs.existsSync(path.join(dir, "README.md")));
}

const scorecard = exists(evidenceFiles[0]) ? JSON.parse(read(evidenceFiles[0])) : { phases: [] };
check("scorecard phase count", Array.isArray(scorecard.phases) && scorecard.phases.length === 12);
check("scorecard candidate status", scorecard.status === "productionCandidate");
check("scorecard preserves blocked Studio", JSON.stringify(scorecard).includes("studioBlocked"));
check("scorecard preserves human required", JSON.stringify(scorecard).includes("humanPlaytestRequired"));
check("scorecard preserves performance unknown", JSON.stringify(scorecard).includes("performanceUnknown"));

const sourceOnly = sourceFiles.filter((file) => file.endsWith(".lua")).filter(exists).map(read).join("\n");
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
  check(`forbidden ${name}`, !pattern.test(sourceOnly));
}

const failed = checks.filter((item) => !item.ok);
const report = {
  phaseRange: "209-220",
  status: failed.length === 0 ? "passed" : "failed",
  total: checks.length,
  passed: checks.length - failed.length,
  failed: failed.length,
  failures: failed,
  runtimeEvidence: {
    studio: "studioBlocked",
    finalAssets: "finalAssetBlocked",
    humanPlaytest: "humanPlaytestRequired",
    performance: "performanceUnknown",
    certification: "productionCandidate",
  },
};

console.log(JSON.stringify(report, null, 2));
process.exit(failed.length === 0 ? 0 : 1);
