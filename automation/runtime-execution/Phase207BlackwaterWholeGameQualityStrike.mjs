import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const read = (target) => fs.readFileSync(path.join(root, target), "utf8");
const exists = (target) => fs.existsSync(path.join(root, target));
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });

const sourceFiles = [
  "src/ReplicatedStorage/Config/BlackwaterQualityStrikeConfig.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterQualityStrikeRuntime.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterProductionCoordinator.lua",
  "src/StarterPlayer/StarterPlayerScripts/ClientCore/VerticalSlice/Chapter196HudController.client.lua",
  "src/ReplicatedStorage/Config/BlackwaterAudioExecutionConfig.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterAudioExecutionRuntime.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterBailiffPhysicalRuntime.lua",
];

const evidenceFiles = [
  "automation/runtime-evidence/phase-207/baseline-audit.md",
  "automation/runtime-evidence/phase-207/quality-scorecard.json",
  "automation/runtime-evidence/phase-207/improvement-evidence-table.md",
  "automation/runtime-evidence/phase-207/validation-summary.json",
  "automation/runtime-evidence/phase-207/validation-report.md",
  "automation/runtime-evidence/phase-207/defect-log.json",
  "automation/runtime-evidence/phase-207/studio/studio-evidence.json",
  "automation/runtime-evidence/phase-207/playtest/human-playtest-evidence.json",
  "automation/runtime-evidence/phase-207/performance/performance-evidence.json",
  "automation/runtime-evidence/phase-207/audio/audio-audition-status.json",
];

for (const file of [...sourceFiles, ...evidenceFiles]) {
  check(`required file ${file}`, exists(file));
}

const source = sourceFiles.filter(exists).map(read).join("\n");
const docsDir = path.join(root, "docs", "phases", "phase-207");
const docs = fs.existsSync(docsDir) ? fs.readdirSync(docsDir).filter((name) => name.endsWith(".md")) : [];

for (const token of [
  "OpeningBudgets",
  "controlSeconds = 10",
  "firstGoalSeconds = 30",
  "EnvironmentArrangements",
  "spawn_street_newsstand",
  "blackwater_gate_chain",
  "heart_chamber_reflection_basin",
  "OptionalDiscoveries",
  "microstory_constable_vale",
  "microstory_bailiff_watch",
  "secret_archive_order",
  "SideBranches",
  "dangerous fast route",
  "alternate safe route",
  "ShortcutRules",
  "ReactiveProps",
  "SignatureMoments",
  "ResourceLoop",
  "lanternStability",
]) {
  check(`quality config ${token}`, source.includes(token));
}

for (const token of [
  "Phase207QualityStrike",
  "createInspectable",
  "ProximityPrompt",
  "appendDiscovery",
  "spendLantern",
  "restoreLantern",
  "createShortcut",
  "Phase207ShortcutOpened",
  "Phase207ShortcutBlocked",
  "Phase207QualityState",
  "implementedUnverified",
  "studioBlocked",
]) {
  check(`quality runtime ${token}`, source.includes(token));
}

for (const token of [
  "QualityStrikeRuntime.initialize",
  "QualityStrikeRuntime.applyObjective",
  "qualityStrike",
  "QualityStrikeRuntime.shutdown",
  "LanternStability",
]) {
  check(`coordinator/HUD binding ${token}`, source.includes(token));
}

check("phase207 documentation count", docs.length >= 18, `${docs.length} markdown files`);
for (const name of [
  "00_BASELINE.md",
  "01_OPENING_TEN_MINUTES.md",
  "02_ENVIRONMENTAL_STORYTELLING.md",
  "03_EXPLORATION_AND_SECRETS.md",
  "04_BAILIFF_PRESENCE.md",
  "05_STEALTH_CHASE_READABILITY.md",
  "06_PUZZLE_COMPREHENSION.md",
  "07_NARRATIVE_SPINE.md",
  "08_CINEMATIC_EXECUTION.md",
  "09_OBJECTIVE_HUD_QUALITY.md",
  "10_INTERACTION_GRAMMAR.md",
  "11_RESOURCE_RISK_LOOP.md",
  "12_REPLAYABILITY_MULTIPLAYER.md",
  "13_ACCESSIBILITY_EXPANSION.md",
  "14_PERFORMANCE_STABILITY.md",
  "15_SIGNATURE_MOMENTS.md",
  "16_FUN_FEAR_PLAYTEST_PROTOCOL.md",
  "17_COMPLETION_REPORT.md",
  "18_PHASE_208_RECOMMENDATION.md",
]) {
  check(`phase207 doc ${name}`, docs.includes(name));
}

const scorecard = exists("automation/runtime-evidence/phase-207/quality-scorecard.json")
  ? JSON.parse(read("automation/runtime-evidence/phase-207/quality-scorecard.json"))
  : { categories: [] };
check("scorecard category count", Array.isArray(scorecard.categories) && scorecard.categories.length >= 27);
check("scorecard production candidate", scorecard.status === "productionCandidate");
check("scorecard preserves performance unknown", JSON.stringify(scorecard).includes("performanceUnknown"));

const studio = exists("automation/runtime-evidence/phase-207/studio/studio-evidence.json")
  ? JSON.parse(read("automation/runtime-evidence/phase-207/studio/studio-evidence.json"))
  : {};
check("studio remains blocked without evidence", studio.status === "studioBlocked" && studio.executed === false);

const playtest = exists("automation/runtime-evidence/phase-207/playtest/human-playtest-evidence.json")
  ? JSON.parse(read("automation/runtime-evidence/phase-207/playtest/human-playtest-evidence.json"))
  : {};
check("human playtest remains required", playtest.status === "humanPlaytestRequired" && playtest.executed === false);

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
  check(`forbidden ${name}`, !pattern.test(source));
}

const failed = checks.filter((item) => !item.ok);
const report = {
  phase: 207,
  status: failed.length === 0 ? "passed" : "failed",
  total: checks.length,
  passed: checks.length - failed.length,
  failed: failed.length,
  failures: failed,
  runtimeEvidence: {
    studio: "studioBlocked",
    audioAssets: "assetUploadBlocked",
    humanPlaytest: "humanPlaytestRequired",
    performance: "performanceUnknown",
  },
};

console.log(JSON.stringify(report, null, 2));
process.exit(failed.length === 0 ? 0 : 1);
