import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const read = (target) => fs.readFileSync(path.join(root, target), "utf8");
const exists = (target) => fs.existsSync(path.join(root, target));
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });

const files = [
  "src/ReplicatedStorage/Config/BlackwaterAudioManifest.lua",
  "src/ReplicatedStorage/Config/BlackwaterProductionConfig.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterStreetAudioRuntime.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterBailiffPhysicalRuntime.lua",
  "src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterProductionCoordinator.lua",
  "src/StarterPlayer/StarterPlayerScripts/ClientCore/VerticalSlice/Chapter196HudController.client.lua",
  "automation/runtime-evidence/phase-205/quality-scorecard.json",
  "automation/runtime-evidence/phase-205/validation-summary.json",
];

for (const file of files) check(`required ${file}`, exists(file));

const source = files.filter((file) => exists(file) && file.endsWith(".lua")).map(read).join("\n");
const docs = fs.existsSync(path.join(root, "docs/phases/phase-205"))
  ? fs.readdirSync(path.join(root, "docs/phases/phase-205")).filter((name) => name.endsWith(".md"))
  : [];

for (const token of [
  "The Street That Listens", "A1_primary_rain_bed", "A2_wet_pavement_steps", "A3_period_carriage",
  "A4_lantern_physicality", "A5_distant_wrong_bell", "A6_distant_dog", "A7_house_structural_strain",
  "A8_heavy_iron_gate", "A9_pressure_tone", "A10_restrained_raven", "assetUploadBlocked",
  "robloxAssetId = \"\"", "Pixabay Content License candidate",
]) check(`audio manifest ${token}`, source.includes(token));

for (const token of [
  "impossible_footsteps", "wrong_bell", "source_less_carriage", "breathing_architecture",
  "constable_vale_presence", "ordinary_london", "house_reveal", "gate_approach",
  "boundary_crossing", "StreetAudioCaption", "StreetAudioVisualEquivalent",
]) check(`street audio ${token}`, source.includes(token));

for (const token of [
  "TheBailiff_ProductionProxy", "HumanoidRootPart", "BailiffHumanoid", "PathfindingService",
  "CreatePath", "ComputeAsync", "safeReposition", "recordLastKnownPosition",
  "productionProxyReplacementRequired", "ServerAuthoritative",
]) check(`bailiff physical ${token}`, source.includes(token));

for (const token of [
  "StreetAudioRuntime.initialize", "BailiffPhysicalRuntime.initialize", "beforeInteraction",
  "afterInteraction", "StreetAudioRuntime.trigger", "BailiffPhysicalRuntime.setMode",
  "BailiffPhysicalRuntime.safeReposition", "streetAudio", "bailiffPhysical",
]) check(`coordinator integration ${token}`, source.includes(token));

for (const token of ["streetAudioCaption", "StreetAudioCaption", "bailiffState", "AudioState"]) {
  check(`hud ${token}`, source.includes(token));
}

check("phase205 documentation count", docs.length >= 20, `${docs.length} markdown files`);
for (const name of [
  "00_QUALITY_BASELINE.md", "01_QUALITY_PLANNER.md", "02_RELEASE_GATES.md",
  "03_SIGNATURE_AUDIO_DIRECTION.md", "04_AUDIO_CANDIDATE_MANIFEST.md",
  "05_AUDIO_LICENSING.md", "06_STREET_AUDIO_TIMELINE.md",
  "07_BAILIFF_PHYSICAL_EXECUTION.md", "08_PATHFINDING_AND_FAIRNESS.md",
  "09_STEALTH_CHASE_PLAYABILITY.md", "10_PUZZLE_COMPREHENSION.md",
  "11_NARRATIVE_CINEMATIC_EXECUTION.md", "12_ENVIRONMENT_ROOM_REVIEW.md",
  "13_REPLAYABILITY.md", "14_ACCESSIBILITY.md", "15_PERFORMANCE_BUDGETS.md",
  "16_STUDIO_PLAYTHROUGH_MATRIX.md", "17_HUMAN_PLAYTEST_PROTOCOL.md",
  "18_FAILURE_TAXONOMY.md", "19_DIAGNOSTICS.md", "20_COMPLETION_REPORT.md",
  "21_BLANK_CONTEXT_RECOVERY.md", "22_PHASE_206_RECOMMENDATION.md",
]) check(`phase205 doc ${name}`, docs.includes(name));

const scorecard = exists("automation/runtime-evidence/phase-205/quality-scorecard.json")
  ? JSON.parse(read("automation/runtime-evidence/phase-205/quality-scorecard.json"))
  : { categories: [] };
check("scorecard category count", Array.isArray(scorecard.categories) && scorecard.categories.length >= 16);
check("scorecard keeps studio blocked", JSON.stringify(scorecard).includes("studioBlocked"));
check("scorecard keeps performance unknown", JSON.stringify(scorecard).includes("\"performanceStatus\":\"notStarted\"") || JSON.stringify(scorecard).includes("\"currentScore\":\"Unknown\""));

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
]) check(`forbidden ${name}`, !pattern.test(source));

const failed = checks.filter((item) => !item.ok);
const report = {
  phase: 205,
  status: failed.length === 0 ? "passed" : "failed",
  total: checks.length,
  passed: checks.length - failed.length,
  failed: failed.length,
  failures: failed,
  regressionNote: "Phase 197-204 totals are cumulative in Phase197To204BlackwaterProductionProgram.mjs; Phase 184-196 scripts are independent per phase.",
  runtimeEvidence: {
    studio: "executionBlocked",
    humanPlaytest: "notImported",
    performance: "unknown",
    audioAssets: "candidateOnly",
  },
};

console.log(JSON.stringify(report, null, 2));
process.exit(failed.length === 0 ? 0 : 1);
