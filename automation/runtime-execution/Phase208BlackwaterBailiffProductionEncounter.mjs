import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const read = (target) => fs.readFileSync(path.join(root, target), "utf8");
const exists = (target) => fs.existsSync(path.join(root, target));
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });

const sourceFiles = [
  "src/ReplicatedStorage/Config/BlackwaterBailiffProductionConfig.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterBailiffPhysicalRuntime.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterProductionCoordinator.lua",
  "src/StarterPlayer/StarterPlayerScripts/ClientCore/VerticalSlice/Chapter196HudController.client.lua",
];

const evidenceFiles = [
  "automation/runtime-evidence/phase-208/bailiff-production-scorecard.json",
  "automation/runtime-evidence/phase-208/encounter-evidence-table.md",
  "automation/runtime-evidence/phase-208/defect-log.json",
  "automation/runtime-evidence/phase-208/studio/studio-evidence.json",
  "automation/runtime-evidence/phase-208/playtest/human-playtest-evidence.json",
  "automation/runtime-evidence/phase-208/performance/performance-evidence.json",
  "automation/runtime-evidence/phase-208/validation-summary.json",
  "automation/runtime-evidence/phase-208/validation-report.md",
];

for (const file of [...sourceFiles, ...evidenceFiles]) {
  check(`required file ${file}`, exists(file));
}

const source = sourceFiles.filter(exists).map(read).join("\n");

for (const token of [
  "DesignBiography",
  "VisualProductionSheet",
  "AnimationStates",
  "AIStates",
  "PerceptionEvidenceTypes",
  "Encounters",
  "SearchPatterns",
  "HidingSpaceTypes",
  "Distractions",
  "NavigationRecoveryTests",
  "AttackDistanceScenarios",
  "MultiplayerTargetSwitchTests",
]) {
  check(`production config ${token}`, source.includes(token));
}

for (const token of [
  "recordPerceptionEvidence",
  "runEncounterPass",
  "DuplicateEncounterPass",
  "BailiffProductionState",
  "LastEvidenceType",
  "LastEvidenceConfidence",
  "AttackAnticipation",
  "AttackActive",
  "TargetInCooldown",
  "studioBlocked",
]) {
  check(`physical runtime ${token}`, source.includes(token));
}

for (const token of [
  "BailiffPhysicalRuntime.recordPerceptionEvidence",
  "BailiffPhysicalRuntime.runEncounterPass",
  "BailiffProductionState",
  "BailiffEvidenceSource",
]) {
  check(`coordinator/HUD integration ${token}`, source.includes(token));
}

const config = exists(sourceFiles[0]) ? read(sourceFiles[0]) : "";
check("minimum animation states", (config.match(/id = "/g) || []).length >= 60);
check("20 animation states present", (config.match(/mode = "/g) || []).length >= 20);
check("10+ AI states present", (config.match(/perceptionPolicy = "/g) || []).length >= 10);
check("8 encounter definitions present", (config.match(/purpose = "/g) || []).length >= 8);
check("6 navigation recovery tests present", (config.match(/path_to_|recover/g) || []).length >= 6);
check("5 attack-distance scenarios present", (config.match(/expected = "/g) || []).length >= 5);
check("4 multiplayer target switch tests present", (config.match(/late_join_protection|dead_player_excluded|recent_target_cooldown|noise_owner_priority/g) || []).length >= 4);
check("3 hiding-space types present", (config.match(/searchRisk = /g) || []).length >= 3);
check("3 distraction types present", (config.match(/evidenceType = "/g) || []).length >= 3);
check("3 search patterns present", (config.match(/checks = {/g) || []).length >= 3);

const docsDir = path.join(root, "docs", "phases", "phase-208");
const docs = fs.existsSync(docsDir) ? fs.readdirSync(docsDir).filter((name) => name.endsWith(".md")) : [];
check("phase208 documentation count", docs.length >= 12, `${docs.length} markdown files`);
for (const name of [
  "00_PLAYER_FACING_OUTCOME.md",
  "01_BAILIFF_DESIGN_BIOGRAPHY.md",
  "02_VISUAL_PRODUCTION_SHEET.md",
  "03_ANIMATION_STATE_PLAN.md",
  "04_PERCEPTION_EVIDENCE.md",
  "05_ENCOUNTER_CONSTRUCTION.md",
  "06_FAIRNESS_AND_MULTIPLAYER.md",
  "07_CONTENT_INVENTORY.md",
  "08_EVIDENCE_LADDER.md",
  "09_DEFECT_LOOP.md",
  "10_VALIDATION.md",
  "11_PRODUCTION_REVIEW.md",
  "12_COMPLETION_REPORT.md",
]) {
  check(`phase208 doc ${name}`, docs.includes(name));
}

const scorecard = exists(evidenceFiles[0])
  ? JSON.parse(read(evidenceFiles[0]))
  : { categories: [] };
check("scorecard production candidate", scorecard.status === "productionCandidate");
check("scorecard preserves studio block", JSON.stringify(scorecard).includes("studioBlocked"));
check("scorecard category count", Array.isArray(scorecard.categories) && scorecard.categories.length >= 12);

const studio = exists(evidenceFiles[3]) ? JSON.parse(read(evidenceFiles[3])) : {};
check("studio evidence remains blocked", studio.status === "studioBlocked" && studio.executed === false);

const playtest = exists(evidenceFiles[4]) ? JSON.parse(read(evidenceFiles[4])) : {};
check("human playtest remains required", playtest.status === "humanPlaytestRequired" && playtest.executed === false);

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
  phase: 208,
  status: failed.length === 0 ? "passed" : "failed",
  total: checks.length,
  passed: checks.length - failed.length,
  failed: failed.length,
  failures: failed,
  runtimeEvidence: {
    studio: "studioBlocked",
    finalRig: "finalAssetBlocked",
    humanPlaytest: "humanPlaytestRequired",
    performance: "performanceUnknown",
  },
};

console.log(JSON.stringify(report, null, 2));
process.exit(failed.length === 0 ? 0 : 1);
