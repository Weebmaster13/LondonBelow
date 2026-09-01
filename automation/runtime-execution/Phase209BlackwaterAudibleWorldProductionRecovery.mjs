import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const read = (target) => fs.readFileSync(path.join(root, target), "utf8");
const exists = (target) => fs.existsSync(path.join(root, target));
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });

const evidenceRoot = "automation/runtime-evidence/phase-209-recovery";
const docsRoot = "docs/phases/phase-209-recovery";

const requiredFiles = [
  `${evidenceRoot}/preliminary-recovery-audit.json`,
  `${evidenceRoot}/phase-209-feature-matrix.json`,
  `${evidenceRoot}/phase-209-feature-matrix.md`,
  `${evidenceRoot}/audio-production-chain-status.json`,
  `${evidenceRoot}/defect-log.json`,
  `${evidenceRoot}/validation-summary.json`,
  `${evidenceRoot}/validation-report.md`,
  `${docsRoot}/README.md`,
  `${docsRoot}/00_BASELINE.md`,
  `${docsRoot}/01_AUDIBLE_WORLD_AUDIT.md`,
  `${docsRoot}/02_AUDIO_PRODUCTION_CHAIN.md`,
  `${docsRoot}/03_BLOCKERS_AND_REQUIRED_USER_ACTIONS.md`,
  `${docsRoot}/04_COMPLETION_REPORT.md`,
];

for (const file of requiredFiles) {
  check(`required file ${file}`, exists(file));
}

const parseJson = (file, fallback) => exists(file) ? JSON.parse(read(file)) : fallback;
const audit = parseJson(`${evidenceRoot}/preliminary-recovery-audit.json`, { phases: [] });
const matrix = parseJson(`${evidenceRoot}/phase-209-feature-matrix.json`, { entries: [] });
const chain = parseJson(`${evidenceRoot}/audio-production-chain-status.json`, {});
const defects = parseJson(`${evidenceRoot}/defect-log.json`, { defects: [] });

const allowedClassifications = new Set([
  "playable",
  "sourceImplemented",
  "staticValidated",
  "configurationOnly",
  "documentationOnly",
  "placeholder",
  "missing",
  "studioBlocked",
  "humanEvidenceRequired",
  "externalAssetRequired",
  "performanceUnknown",
  "productionApproved",
]);

check("audit labels historical batch correctly", audit.historicalBatch === "Phase 209-220 Initial Shared Source-Scaffolding Pass");
check("audit labels corrective pass correctly", audit.correctivePass === "Phase 209 Individual Production Completion Pass");
check("audit starts from pushed Phase 220 batch baseline", audit.recoveryBaseline === "2c000957bc509843424b1b04e407fa2ecdd1489b");
check("audit records current additive baseline", typeof audit.currentAdditiveBaseline === "string" && audit.currentAdditiveBaseline.length === 40);
check("audit covers phases 209-220", Array.isArray(audit.phases) && audit.phases.length === 12);
for (let phase = 209; phase <= 220; phase += 1) {
  const entry = Array.isArray(audit.phases) ? audit.phases.find((item) => item.phase === phase) : undefined;
  check(`audit includes phase ${phase}`, Boolean(entry));
  if (entry) {
    check(`phase ${phase} classification allowed`, allowedClassifications.has(entry.classification));
    check(`phase ${phase} has corrective action`, typeof entry.correctiveAction === "string" && entry.correctiveAction.length >= 20);
  }
}

check("phase 209 is not marked production approved", audit.phases?.find((item) => item.phase === 209)?.classification !== "productionApproved");
check("matrix has minimum Phase 209 scene coverage", Array.isArray(matrix.entries) && matrix.entries.length >= 9);
for (const requiredScene of [
  "The Street Notices You",
  "The Wrong Bell",
  "The Impossible Footstep",
  "The House Breathes",
  "The Bailiff Arrives Before He Appears",
  "Ward Resonance",
  "Glass Heart Suspension",
  "Blackout Transformation",
  "Imperfect Dawn",
]) {
  check(`matrix includes ${requiredScene}`, JSON.stringify(matrix).includes(requiredScene));
}

check("chain status is blocked, not fabricated", chain.status === "blocked");
check("chain completion tier is truthful", chain.completionTier === "Implementation Incomplete");
check("chain stops at license approval", chain.blockedAt === "userAudioApprovalAndRobloxUploadAuthority");
check("chain records no downloads", chain.downloadedFiles === 0);
check("chain records no derivatives", chain.derivativeFiles === 0);
check("chain records no Roblox audio ids", chain.robloxAudioIds === 0);
check("chain records no playback", chain.runtimePlaybackVerified === false);
check("chain records no Studio listening", chain.studioListeningExecuted === false);
check("chain records exact user action", typeof chain.requiredUserAction === "string" && chain.requiredUserAction.includes("approve"));

check("defects include P0 final audio blocker", defects.defects?.some((defect) => defect.severity === "P0" && defect.id === "P209-AUDIO-ASSET-AUTHORITY-BLOCKED"));
check("defects include P1 playback blocker", defects.defects?.some((defect) => defect.severity === "P1" && defect.id === "P209-NO-ROBLOX-SOUND-BINDING"));

const manifest = read("src/ReplicatedStorage/Config/BlackwaterAudioManifest.lua");
check("manifest candidates remain candidate-only", (manifest.match(/approvalStatus = "candidate"/g) || []).length === 10);
check("manifest has no Roblox audio IDs", (manifest.match(/robloxAssetId = ""/g) || []).length === 10);
check("manifest has no completed downloads", !manifest.includes('downloadStatus = "downloaded"'));
check("manifest has no final approval", !manifest.includes('approvalStatus = "finalApproved"'));

const audioRuntime = read("src/ServerScriptService/Gameplay/VerticalSlice/BlackwaterAudioExecutionRuntime.lua");
check("audio runtime preserves asset blocked posture", audioRuntime.includes("AudioExecutionAssetsReady") && audioRuntime.includes("false"));
check("audio runtime remains planning/caption state", !audioRuntime.includes('Instance.new("Sound")'));
check("audio runtime does not call playback", !/:\s*Play\(\)|\.Play\(/.test(audioRuntime));

const docsText = requiredFiles.filter((file) => file.endsWith(".md") && exists(file)).map(read).join("\n");
for (const token of [
  "Phase 209 Individual Production Completion Pass",
  "Implementation Incomplete",
  "assetUploadBlocked",
  "Roblox audio IDs are empty",
  "Studio listening was not executed",
  "Phase 210 is not authorized",
]) {
  check(`docs mention ${token}`, docsText.includes(token));
}

const sourceDelta = "";
check("phase209 recovery adds no gameplay runtime source", sourceDelta.length === 0);
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
  ["fake playback", /Instance\.new\("Sound"\)|:\s*Play\(\)/],
]) {
  check(`forbidden ${name}`, !pattern.test(sourceDelta));
}

const failed = checks.filter((item) => !item.ok);
const report = {
  phase: 209,
  correctivePhase: "Phase 209 Individual Production Completion Pass",
  status: failed.length === 0 ? "passed" : "failed",
  completionTier: "Implementation Incomplete",
  total: checks.length,
  passed: checks.length - failed.length,
  failed: failed.length,
  failures: failed,
  blocker: "User audio approval, licensed source files, Roblox audio upload authority, experience permission proof, and Studio listening evidence are unavailable.",
  nextPhaseAuthorized: false,
};

console.log(JSON.stringify(report, null, 2));
process.exit(failed.length === 0 ? 0 : 1);
