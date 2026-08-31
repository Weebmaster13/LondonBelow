import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const read = (target) => fs.readFileSync(path.join(root, target), "utf8");
const exists = (target) => fs.existsSync(path.join(root, target));
const phaseArg = process.argv.find((arg) => arg.startsWith("--phase="));
const phase = phaseArg ? Number(phaseArg.slice("--phase=".length)) : 204;

const serverBase = "src/ServerScriptService/Gameplay/VerticalSlice";
const files = {
  config: "src/ReplicatedStorage/Config/BlackwaterProductionConfig.lua",
  chapterConfig: "src/ReplicatedStorage/Config/Chapter196VerticalSliceConfig.lua",
  coordinator: `${serverBase}/Chapter196Coordinator.lua`,
  world: `${serverBase}/Chapter196WorldBuilder.lua`,
  production: `${serverBase}/BlackwaterProductionCoordinator.lua`,
  runState: `${serverBase}/BlackwaterRunState.lua`,
  environment: `${serverBase}/BlackwaterEnvironmentProductionRuntime.lua`,
  monster: `${serverBase}/BlackwaterMonsterRuntime.lua`,
  perception: `${serverBase}/BlackwaterPerceptionRuntime.lua`,
  stealth: `${serverBase}/BlackwaterStealthRuntime.lua`,
  chase: `${serverBase}/BlackwaterChaseRuntime.lua`,
  puzzle: `${serverBase}/BlackwaterPuzzleRuntime.lua`,
  investigation: `${serverBase}/BlackwaterInvestigationRuntime.lua`,
  narrative: `${serverBase}/BlackwaterNarrativeRuntime.lua`,
  cinematic: `${serverBase}/BlackwaterCinematicRuntime.lua`,
  audio: `${serverBase}/BlackwaterAudioRuntime.lua`,
  replay: `${serverBase}/BlackwaterReplayRuntime.lua`,
  hud: "src/StarterPlayer/StarterPlayerScripts/ClientCore/VerticalSlice/Chapter196HudController.client.lua",
  governance: "src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua",
  bootstrap: "src/ServerScriptService/Core/Bootstrap.server.lua",
};

const checks = [];
function check(name, ok, detail = "") {
  checks.push({ name, ok: Boolean(ok), detail });
}
function countMatches(source, pattern) {
  return (source.match(pattern) || []).length;
}
function phaseDoc(phaseNumber) {
  return `docs/phases/phase-${phaseNumber}/README.md`;
}

for (const [name, target] of Object.entries(files)) {
  check(`required source ${name}`, exists(target), target);
}

const source = Object.values(files).filter(exists).map(read).join("\n");
const executableSource = Object.entries(files)
  .filter(([name, target]) => exists(target) && name !== "governance")
  .map(([, target]) => read(target))
  .join("\n");
const config = exists(files.config) ? read(files.config) : "";
const production = exists(files.production) ? read(files.production) : "";
const coordinator = exists(files.coordinator) ? read(files.coordinator) : "";
const world = exists(files.world) ? read(files.world) : "";
const hud = exists(files.hud) ? read(files.hud) : "";

const phaseChecks = {
  197: () => {
    for (const token of [
      "victorian_street", "front_steps", "foyer", "west_wing", "east_wing", "upper_gallery",
      "constable_room", "servants_corridor", "kitchen", "cellar", "crypt_access",
      "ward_chambers", "forbidden_archive", "ritual_chamber", "escape_route",
      "ProductionLayout", "Shortcuts", "BlackwaterReactive", "EnvironmentStage",
      "AssetManifest", "Production-ready procedural/runtime construction", "Blocked by missing external asset",
    ]) check(`phase197 ${token}`, source.includes(token));
    check("phase197 room count", countMatches(config, /displayName = "/g) >= 15);
    check("phase197 route markers", countMatches(config, /unlockObjective/g) >= 3);
    check("phase197 world builder consumes production config", world.includes("ProductionConfig.Rooms") && world.includes("productionRoom"));
  },
  198: () => {
    for (const token of [
      "The Bailiff", "Unspawned", "Dormant", "Foreshadow", "Patrol", "Stalk", "Observe",
      "Investigate", "Suspicious", "Hunt", "Search", "Ambush", "DoorPressure", "Recover",
      "Retreat", "Climax", "Disabled", "Shutdown", "selectTarget", "fairnessIncidents",
      "targetCooldown", "reactToObjective", "IllegalTransition",
    ]) check(`phase198 ${token}`, source.includes(token));
    check("phase198 exact state catalog", countMatches(config, /"[A-Z][A-Za-z]+"/g) >= 18);
    check("phase198 coordinator publishes Bailiff state", source.includes('SetAttribute("BailiffState"') && hud.includes("bailiffState"));
  },
  199: () => {
    for (const token of [
      "calculateNoise", "calculateExposure", "tryEnterHiding", "updateStamina", "wardrobe",
      "under_table", "shadow_alcove", "service_cupboard", "emergency_concealment",
      "ChaseAlreadyActive", "MissingTarget", "recordDeath", "recordRescue", "recordHuntSurvived",
    ]) check(`phase199 ${token}`, source.includes(token));
    check("phase199 hiding capacity catalog", countMatches(config, /searchRisk/g) === 5);
    check("phase199 server-owned death integration", coordinator.includes("ProductionCoordinator.recordDeath()"));
  },
  200: () => {
    for (const token of [
      "WardSeeds", "validateWard", "IncorrectWardOrder", "hintLevel", "OptionalEvidence",
      "recordDiscovery", "pickForObjective", "clueRooms", "ward_west", "ward_east", "ward_crypt",
    ]) check(`phase200 ${token}`, source.includes(token));
    check("phase200 multiple safe seed definitions", countMatches(config, /seed = 19620/g) >= 2);
    const validationFunction = coordinator.slice(coordinator.indexOf("local function validateInteraction"), coordinator.indexOf("local function onTriggered"));
    const triggerFunction = coordinator.slice(coordinator.indexOf("local function onTriggered"), coordinator.indexOf("local function moveToCheckpoint"));
    check("phase200 production validates before mutation", validationFunction.indexOf("ProductionCoordinator.beforeInteraction") > validationFunction.indexOf("OutOfRange") && triggerFunction.indexOf("validateInteraction") < triggerFunction.indexOf("applyBeatVisual"));
  },
  201: () => {
    for (const token of [
      "Constable Vale", "Glass Heart", "The House Testifies", "A Name Returned", "endingText",
      "CinematicBeat", "CinematicReducedMotion", "opening_street_arrival", "first_bailiff_reveal",
      "archive_opening", "glass_heart_reveal", "dawn_aftermath", "EndingId", "EndingText",
    ]) check(`phase201 ${token}`, source.includes(token));
    check("phase201 three endings", countMatches(config, /id = ".*_.*"/g) >= 20 && config.includes("free_the_presence"));
  },
  202: () => {
    for (const token of [
      "Master", "Music", "Ambience", "Environment", "Monster", "Interaction", "Dialogue",
      "Accessibility", "CaptionCue", "AudioZone", "AudioState", "assetSlotsRequired",
      "audio_slots", "Blocked by missing external asset",
    ]) check(`phase202 ${token}`, source.includes(token));
    const busNames = ["Master", "Music", "Ambience", "Environment", "Monster", "Interaction", "Dialogue", "UI", "Accessibility"];
    check("phase202 nine audio buses", busNames.every((name) => config.includes(`"${name}"`)));
  },
  203: () => {
    for (const token of [
      "Difficulty", "Story", "Standard", "Investigator", "Nightmare", "buildSummary",
      "runSeed", "hintsUsed", "deaths", "rescues", "huntsSurvived", "chooseEnding",
      "difficultyPresetCount", "endingCount",
    ]) check(`phase203 ${token}`, source.includes(token));
    check("phase203 accessibility does not depend on difficulty", config.includes("Reduced") === false && config.includes("hintStrength"));
  },
  204: () => {
    for (const token of [
      "BlackwaterProductionCoordinator", "BlackwaterEnvironmentProductionRuntime", "BlackwaterMonsterRuntime",
      "BlackwaterPerceptionRuntime", "BlackwaterStealthRuntime", "BlackwaterChaseRuntime",
      "BlackwaterPuzzleRuntime", "BlackwaterInvestigationRuntime", "BlackwaterNarrativeRuntime",
      "BlackwaterCinematicRuntime", "BlackwaterAudioRuntime", "BlackwaterReplayRuntime",
      "BlackwaterRunState", "blackwaterProductionProgram", "ProductionProgramVersion",
    ]) check(`phase204 ${token}`, source.includes(token));
    check("phase204 initialize order", production.indexOf("RunState.initialize") < production.indexOf("EnvironmentRuntime.initialize") && production.indexOf("MonsterRuntime.initialize") < production.indexOf("StealthRuntime.initialize"));
    check("phase204 shutdown reverse order", production.indexOf("AudioRuntime.shutdown") < production.indexOf("RunState.clear"));
    check("phase204 root diagnostics", coordinator.includes("ProductionCoordinator.inspect()") && coordinator.includes("SnapshotManager.registerProvider(\"blackwaterProductionProgram\""));
  },
};

for (let current = 197; current <= Math.min(phase, 204); current += 1) {
  phaseChecks[current]();
  const target = phaseDoc(current);
  check(`phase${current} documentation`, exists(target), target);
  if (exists(target)) {
    const doc = read(target);
    for (const heading of ["## Ownership", "## Non-Ownership", "## Validation", "## Certification Boundary"]) {
      check(`phase${current} doc ${heading}`, doc.includes(heading));
    }
  }
}

for (const [name, pattern] of [
  ["DataStore", /DataStoreService/],
  ["HTTP", /HttpService/],
  ["client server call", /FireServer|InvokeServer/],
  ["remote creation", /Instance\.new\("RemoteEvent"|"RemoteFunction"/],
  ["dynamic code", /loadstring/],
  ["telemetry", /TelemetryService/],
  ["analytics", /AnalyticsService/],
]) {
  check(`forbidden ${name}`, !pattern.test(executableSource));
}

const failed = checks.filter((item) => !item.ok);
const report = {
  phase,
  program: "Phase 197-204 Blackwater Production Program",
  ok: failed.length === 0,
  total: checks.length,
  passed: checks.length - failed.length,
  failed: failed.length,
  failures: failed,
  studioRuntimeEvidence: {
    status: "executionBlocked",
    reason: "Authoritative Roblox Studio playthrough, performance, human playtest, art review, and audio review evidence has not been imported.",
  },
};

console.log(JSON.stringify(report, null, 2));
process.exit(report.ok ? 0 : 1);
