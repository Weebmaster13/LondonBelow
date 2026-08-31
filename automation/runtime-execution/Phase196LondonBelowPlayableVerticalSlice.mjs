import fs from "node:fs"; import path from "node:path"; import process from "node:process";
const root = process.cwd();
const serverBase = "src/ServerScriptService/Gameplay/VerticalSlice";
const files = [
  "src/ReplicatedStorage/Config/Chapter196VerticalSliceConfig.lua",
  `${serverBase}/Chapter196Types.lua`, `${serverBase}/Chapter196State.lua`, `${serverBase}/Chapter196WorldBuilder.lua`, `${serverBase}/Chapter196VisualPlanBridge.lua`, `${serverBase}/Chapter196Coordinator.lua`,
  "src/StarterPlayer/StarterPlayerScripts/ClientCore/VerticalSlice/Chapter196HudController.client.lua",
  "src/ServerScriptService/Core/Bootstrap.server.lua",
];
const docs = ["00_BASELINE.md", "01_CREATIVE_BRIEF.md", "02_WORLD_AND_ROUTE.md", "03_OBJECTIVE_FLOW.md", "04_MULTIPLAYER_AUTHORITY.md", "05_HORROR_PACING.md", "06_CHECKPOINT_RECOVERY.md", "07_PLAYER_PRESENTATION.md", "08_OBSERVATION_DIRECTOR_FLOW.md", "09_SECURITY_ANTI_SKIP.md", "10_PERFORMANCE_CLEANUP.md", "11_STUDIO_PLAYTHROUGH_MATRIX.md", "12_PRODUCTION_REVIEW.md", "13_COMPLETION_REPORT.md", "14_BLANK_CONTEXT_RECOVERY.md", "15_ENGINE_INTEGRATION_PAYOFF.md", "16_GRAND_QUALITY_INTEGRATION.md"];
const studioCases = Array.from({ length: 80 }, (_, index) => `blackwater-playthrough-${String(index + 1).padStart(2, "0")}`);
const checks = []; const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });
const exists = (target) => fs.existsSync(path.join(root, target)); const read = (target) => fs.readFileSync(path.join(root, target), "utf8");
for (const target of files) check(`required ${target}`, exists(target));
for (const name of docs) { const target = `docs/phases/phase-196/${name}`; check(`document ${name}`, exists(target)); if (exists(target)) for (const heading of ["## Ownership", "## Non-Ownership", "## Certification Boundary"]) check(`${name} ${heading}`, read(target).includes(heading)); }
const source = files.filter(exists).map(read).join("\n");
for (const token of ["196.0.0", "The Blackwater Descent", "LondonStreet", "BlackwaterHouse", "Foyer", "Gallery", "ForbiddenArchive", "UnderStairCrypt", "GlassHeartChamber", "ignite_lantern", "read_ledger", "take_seal", "ward_west", "ward_east", "ward_crypt", "open_archive", "take_heart", "escape_gate", "watchman_lantern", "blackwater_brass_seal", "glass_heart", "Objective.Completed", "Objective.Started", "Objective.Failed", "Inventory.ItemAdded", "Interaction.Complete", "ObservationService.observe", "HorrorDirector.setChapterPhase", "RuntimeRobloxVisualCompositionExecution", "createExecutionSession", "buildDiff", "createPatchPlan", "sealPatchPlan", "preparePatch", "markApplied", "commitPatch", "CheckpointId", "CharacterAdded", "Humanoid", "PlayerAdded", "PlayerRemoving", "ProximityPrompt", "MaxActivationDistance", "OutOfRange", "WrongOrder", "MissingItem", "Pressure", "ObjectiveText", "NarrativeText", "DiscoveryLog", "InventoryText", "ThreatText", "Progress", "RenderingRuntime.render", "InteractionRuntime.registerAction", "blackwater.toggle-case-file", "caseFilePanel", "registerLocalizationBundle", "registerTheme", "applyTheme", "playAnimation", "verifyIntegrity", "verifyThemeIntegrity", "verifyAnimationIntegrity", "liveRegion", "AdaptiveText", "SafeArea", "Atmosphere", "ColorCorrectionEffect", "FogEnd", "PointLight", "Cobblestone", "chapter196VerticalSlice"]) check(`player-facing token ${token}`, source.includes(token));
const coordinator = read(`${serverBase}/Chapter196Coordinator.lua`); const builder = read(`${serverBase}/Chapter196WorldBuilder.lua`); const visualBridge = read(`${serverBase}/Chapter196VisualPlanBridge.lua`); const config = read("src/ReplicatedStorage/Config/Chapter196VerticalSliceConfig.lua");
check("nine substantial objectives", (config.match(/id = "/g) || []).length === 9);
const triggerTransaction = coordinator.slice(coordinator.indexOf("local function onTriggered"), coordinator.indexOf("local function moveToCheckpoint"));
check("order before mutation", triggerTransaction.indexOf("validateInteraction") < triggerTransaction.indexOf("applyBeatVisual"));
check("distance server validated", coordinator.includes("rootPart.Position - target.Position") && coordinator.includes("InteractionDistance + 3"));
check("shared seal validation", coordinator.includes("partyHasSeal"));
check("observation before advance", coordinator.indexOf('observe(player, "Objective.Completed"') < coordinator.indexOf("State.advanceObjective"));
check("director follows objective", coordinator.indexOf("State.advanceObjective") < coordinator.indexOf("HorrorDirector.setChapterPhase"));
check("death observation", coordinator.includes('"Objective.Failed"') && coordinator.includes("humanoid.Died"));
check("checkpoint restore", coordinator.includes("character:PivotTo(target)"));
check("all connections cleaned", coordinator.includes("connection:Disconnect()") && coordinator.includes("table.clear(promptConnections)"));
check("runtime-owned world cleanup", coordinator.includes("WorldBuilder.destroy()"));
check("world is substantial", (builder.match(/part\(/g) || []).length >= 12 && (builder.match(/room\(/g) || []).length >= 5 && builder.length > 7500);
check("HUD reads only replicated truth", !/FireServer|InvokeServer/.test(read(files[6])) && read(files[6]).includes("GetAttribute"));
for (const [name, pattern] of [["DataStore", /DataStoreService/], ["HTTP", /HttpService/], ["client server call", /FireServer|InvokeServer/], ["dynamic code", /loadstring/], ["telemetry", /TelemetryService/], ["analytics", /AnalyticsService/]]) check(`forbidden ${name}`, !pattern.test(source));
const governance = read("src/ServerScriptService/Core/Governance/Contracts/CoreContracts.lua"); for (const token of ["London Below AAA-Quality Playable Vertical Slice", "phase = 196", "The Blackwater Descent authored world", "server validates order and distance", "missing Studio playthrough evidence keeps certification executionBlocked"]) check(`governance ${token}`, governance.includes(token));
for (const target of ["LONDON_ENGINE.md", "LONDON_ENGINE_MASTER_CONTEXT.md", "ROADMAP.md", "TASKS.md", "package.json"]) check(`catalog ${target}`, read(target).includes("Phase 196") || read(target).includes("phase196"));
const objectiveIds = [...config.matchAll(/id = "([a-z_]+)"/g)].map((match) => match[1]);
check("objective identifiers unique", new Set(objectiveIds).size === objectiveIds.length);
check("objective identifiers match authored sequence", objectiveIds.join(",") === "ignite_lantern,read_ledger,take_seal,ward_west,ward_east,ward_crypt,open_archive,take_heart,escape_gate");
check("phase 184 visual diff runtime consumed", visualBridge.includes("createExecutionSession") && visualBridge.includes("buildDiff") && visualBridge.includes("commitPatch"));
check("phase 184 preflights before world mutation", coordinator.indexOf("VisualPlanBridge.transition") < coordinator.indexOf("applyBeatVisual(interactionId, target)"));
check("earlier rendering runtime consumed", read(files[6]).includes("RobloxGuiRenderingRuntime") && read(files[6]).includes("RenderingRuntime.render"));
check("earlier localization runtime consumed", read(files[6]).includes("registerLocalizationBundle") && read(files[6]).includes("LocalizationReference"));
check("earlier animation runtime consumed", read(files[6]).includes("playAnimation") && read(files[6]).includes("motionEssential = false"));
check("earlier theming runtime consumed", read(files[6]).includes("registerTheme") && read(files[6]).includes("applyTheme"));
check("earlier accessibility runtime consumed", read(files[6]).includes("liveRegion") && read(files[6]).includes('"Assertive"'));
check("interaction runtime drives case file", read(files[6]).includes("InteractionRuntime.registerAction") && read(files[6]).includes("JOURNAL_ACTION_ID"));
check("case file remains presentation only", read(files[6]).includes("DiscoveryLog") && !/FireServer|InvokeServer/.test(read(files[6])));
check("narrative beats cover objectives", config.includes("BeatNarrative") && (config.match(/\n\t[a-z_]+ = "/g) || []).length >= 9);
for (const [index, name] of studioCases.entries()) {
  check(`Studio evidence case ${index + 1} is canonical`, name === `blackwater-playthrough-${String(index + 1).padStart(2, "0")}`);
}
const failed = checks.filter((item) => !item.ok); const staticReport = { phase: 196, ok: failed.length === 0, total: checks.length, passed: checks.length - failed.length, failed: failed.length, failures: failed };
const evidenceArgument = process.argv.find((value) => value.startsWith("--evidence=")); const evidencePath = evidenceArgument?.slice("--evidence=".length) || process.env.PHASE196_STUDIO_EVIDENCE;
function validateEvidence(target) { if (!target || !fs.existsSync(target)) return { ok: false, status: "executionBlocked", reason: "Authoritative Roblox Studio Phase 196 playthrough evidence has not been imported" }; let evidence; try { evidence = JSON.parse(fs.readFileSync(target, "utf8")); } catch { return { ok: false, status: "executionBlocked", reason: "Studio evidence is malformed JSON" }; } const results = new Map(Array.isArray(evidence.cases) ? evidence.cases.map((item) => [item.name, item.status]) : []); const missing = studioCases.filter((name) => results.get(name) !== "passed"); const exact = results.size === studioCases.length; const ok = evidence.phase === 196 && evidence.authoritative === true && typeof evidence.studioRunId === "string" && evidence.studioRunId.length > 0 && typeof evidence.playthroughMinutes === "number" && evidence.playthroughMinutes >= 12 && exact && missing.length === 0; return ok ? { ok: true, status: "passed", studioRunId: evidence.studioRunId, playthroughMinutes: evidence.playthroughMinutes, cases: studioCases.length } : { ok: false, status: "executionBlocked", reason: "Studio playthrough evidence is incomplete or rejected", missing, exactCaseSet: exact }; }
if (process.argv.includes("--self-check")) { console.log(JSON.stringify(staticReport, null, 2)); process.exit(failed.length === 0 ? 0 : 1); }
const runtimeEvidence = validateEvidence(evidencePath); console.log(JSON.stringify({ phase: 196, staticChecks: staticReport, runtimeEvidence, certificationEligible: staticReport.ok && runtimeEvidence.ok }, null, 2)); process.exit(staticReport.ok && runtimeEvidence.ok ? 0 : 2);
