import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const read = (target) => fs.readFileSync(path.join(root, target), "utf8");
const exists = (target) => fs.existsSync(path.join(root, target));
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });

const sourceFiles = [
  "src/ReplicatedStorage/Config/BlackwaterAudioExecutionConfig.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterAudioExecutionRuntime.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterBailiffPhysicalRuntime.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterProductionCoordinator.lua",
  "src/StarterPlayer/StarterPlayerScripts/ClientCore/VerticalSlice/Chapter196HudController.client.lua",
];

const evidenceFiles = [
  "automation/runtime-evidence/phase-206/baseline-audit.md",
  "automation/runtime-evidence/phase-206/quality-scorecard.json",
  "automation/runtime-evidence/phase-206/validation-summary.json",
  "automation/runtime-evidence/phase-206/audio/license-evidence.json",
  "automation/runtime-evidence/phase-206/audio/checksums.json",
  "automation/runtime-evidence/phase-206/audio/edit-log.md",
  "automation/runtime-evidence/phase-206/audio/user-approval-log.json",
  "automation/runtime-evidence/phase-206/audio/roblox-asset-mapping.json",
  "automation/runtime-evidence/phase-206/studio/studio-evidence.json",
  "automation/runtime-evidence/phase-206/playtest/human-playtest-evidence.json",
  "automation/runtime-evidence/phase-206/performance/performance-evidence.json",
  "automation/runtime-evidence/phase-206/defect-log.json",
];

for (const file of [...sourceFiles, ...evidenceFiles]) {
  check(`required file ${file}`, exists(file));
}

const source = sourceFiles.filter(exists).map(read).join("\n");
const docsDir = path.join(root, "docs/phases/phase-206");
const docs = fs.existsSync(docsDir) ? fs.readdirSync(docsDir).filter((name) => name.endsWith(".md")) : [];

for (const token of [
  "SurfaceLibrary",
  "wet_cobblestone",
  "damaged_wood",
  "shallow_puddle",
  "MovementStates",
  "ObjectFoley",
  "AcousticZones",
  "MixSnapshots",
  "VoiceLimits",
  "MusicStems",
  "SilenceStates",
  "BailiffAudioStates",
  "WardAudioLanguage",
  "assetUploadBlocked",
]) {
  check(`audio execution config ${token}`, source.includes(token));
}

for (const token of [
  "selectFootstep",
  "requestVoice",
  "setAcousticZone",
  "setMixSnapshot",
  "enterSilence",
  "applyBailiffState",
  "applyObjective",
  "captionForWard",
  "VoiceLimitReached",
  "AudioExecutionAssetsReady",
]) {
  check(`audio execution runtime ${token}`, source.includes(token));
}

for (const token of [
  "telegraphAttack",
  "resolveAttack",
  "misses",
  "recoveries",
  "fairTiming",
  "AttackTelegraph",
  "EncounterState",
]) {
  check(`bailiff encounter ${token}`, source.includes(token));
}

for (const token of [
  "AudioExecutionRuntime.initialize",
  "AudioExecutionRuntime.applyObjective",
  "AudioExecutionRuntime.applyBailiffState",
  "AudioExecutionRuntime.selectFootstep",
  "audioExecution",
  "AudioExecutionRuntime.shutdown",
]) {
  check(`coordinator binding ${token}`, source.includes(token));
}

for (const token of [
  "BailiffAudioCaption",
  "AudioExecutionSnapshot",
  "AudioExecutionZone",
  "AudioExecutionSilence",
]) {
  check(`hud binding ${token}`, source.includes(token));
}

check("phase206 documentation count", docs.length >= 18, `${docs.length} markdown files`);
for (const name of [
  "00_BASELINE_AUDIT.md",
  "01_AUDIO_SPECIFICATION.md",
  "02_AUDIO_LICENSING_AND_AUDITION.md",
  "03_SURFACE_FOLEY.md",
  "04_ACOUSTIC_PROPAGATION.md",
  "05_DYNAMIC_MIXING.md",
  "06_MUSIC_AND_SILENCE.md",
  "07_STREET_THAT_LISTENS_EXECUTION.md",
  "08_BAILIFF_SIGNATURE_ENCOUNTER.md",
  "09_STEALTH_CHASE_REMEDIATION.md",
  "10_PUZZLE_AUDIOVISUAL_LANGUAGE.md",
  "11_NARRATIVE_CINEMATIC_EXECUTION.md",
  "12_ACCESSIBILITY_TRANSLATION.md",
  "13_STUDIO_PLAYTHROUGH.md",
  "14_HUMAN_PLAYTEST.md",
  "15_PERFORMANCE_RELIABILITY.md",
  "16_DEFECT_LOG.md",
  "17_COMPLETION_REPORT.md",
  "18_PHASE_207_RECOMMENDATION.md",
]) {
  check(`phase206 doc ${name}`, docs.includes(name));
}

const scorecard = exists("automation/runtime-evidence/phase-206/quality-scorecard.json")
  ? JSON.parse(read("automation/runtime-evidence/phase-206/quality-scorecard.json"))
  : { categories: [] };
check("scorecard category count", Array.isArray(scorecard.categories) && scorecard.categories.length >= 27);
check("scorecard preserves performance unknown", JSON.stringify(scorecard).includes("performanceUnknown"));
check("scorecard preserves studio blocked", JSON.stringify(scorecard).includes("studioBlocked"));
check("scorecard does not claim certified", scorecard.status === "productionCandidate");

const studio = exists("automation/runtime-evidence/phase-206/studio/studio-evidence.json")
  ? JSON.parse(read("automation/runtime-evidence/phase-206/studio/studio-evidence.json"))
  : {};
check("studio evidence remains blocked", studio.status === "studioBlocked" && studio.executed === false);

const approvals = exists("automation/runtime-evidence/phase-206/audio/user-approval-log.json")
  ? JSON.parse(read("automation/runtime-evidence/phase-206/audio/user-approval-log.json"))
  : {};
check("no user approval fabricated", approvals.allCandidatesRequireUserDecision === true);

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
  phase: 206,
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
