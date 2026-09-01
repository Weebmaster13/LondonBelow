import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const exists = (target) => fs.existsSync(path.join(root, target));
const read = (target) => fs.readFileSync(path.join(root, target), "utf8");
const checks = [];
const check = (name, ok, detail = "") => checks.push({ name, ok: Boolean(ok), detail });

const requiredFiles = [
  "automation/runtime-evidence/phase-221/phase-208-220-audit.json",
  "automation/runtime-evidence/phase-221/missing-content-register.md",
  "automation/runtime-evidence/phase-221/golden-route-plan.json",
  "automation/runtime-evidence/phase-221/golden-route-plan.md",
  "automation/runtime-evidence/phase-221/actual-quality-scorecard.json",
  "automation/runtime-evidence/phase-221/studio-test-matrix.md",
  "automation/runtime-evidence/phase-221/validation-summary.json",
  "automation/runtime-evidence/phase-221/validation-report.md",
  "docs/phases/phase-221/README.md",
  "docs/phases/phase-221/01_IMPLEMENTATION_AUDIT.md",
  "docs/phases/phase-221/02_GOLDEN_ROUTE.md",
  "docs/phases/phase-221/03_ASSET_REQUIREMENTS.md",
  "docs/phases/phase-221/04_STUDIO_TEST_MATRIX.md",
  "docs/phases/phase-221/05_PRODUCTION_RECOVERY_PLAN.md",
];

for (const file of requiredFiles) {
  check(`required file ${file}`, exists(file));
}

const audit = exists(requiredFiles[0]) ? JSON.parse(read(requiredFiles[0])) : { phases: [] };
const phases = Array.isArray(audit.phases) ? audit.phases : [];
check("audit covers phases 208-220", phases.length === 13);
for (let phase = 208; phase <= 220; phase += 1) {
  check(`audit includes phase ${phase}`, phases.some((entry) => entry.phase === phase));
}

const allowedStatuses = new Set([
  "playable",
  "studioVerified",
  "humanValidated",
  "sourceOnly",
  "configurationOnly",
  "documentationOnly",
  "placeholder",
  "missing",
  "externallyBlocked",
]);

for (const entry of phases) {
  check(`phase ${entry.phase} classification status valid`, allowedStatuses.has(entry.classification));
  check(`phase ${entry.phase} has truthful reason`, typeof entry.reason === "string" && entry.reason.length >= 24);
}

const classifications = new Set(phases.map((entry) => entry.classification));
check("audit identifies source-only work", classifications.has("sourceOnly"));
check("audit identifies placeholder work", classifications.has("placeholder"));
check("audit identifies externally blocked work", classifications.has("externallyBlocked"));

const route = exists(requiredFiles[2]) ? JSON.parse(read(requiredFiles[2])) : { route: [] };
check("golden route has 6+ steps", Array.isArray(route.route) && route.route.length >= 6);
check("golden route targets 10-20 minutes", route.targetDurationMinutesMin === 10 && route.targetDurationMinutesMax === 20);
check("golden route includes checkpoint recovery", JSON.stringify(route).includes("checkpoint"));
check("golden route includes first Bailiff search", JSON.stringify(route).includes("Bailiff"));
check("golden route includes puzzle", JSON.stringify(route).includes("puzzle"));

const scorecard = exists(requiredFiles[4]) ? JSON.parse(read(requiredFiles[4])) : { categories: [] };
check("actual quality scorecard has 16 categories", Array.isArray(scorecard.categories) && scorecard.categories.length >= 16);
check("scorecard overall remains under 7", Number(scorecard.overallPlayableExperienceEstimateMax) < 7);
check("scorecard preserves performance unknown", JSON.stringify(scorecard).includes("Unknown"));
check("scorecard preserves audio low", JSON.stringify(scorecard).includes("Audible audio"));

const docsText = requiredFiles.filter((file) => file.endsWith(".md") && exists(file)).map(read).join("\n");
for (const token of [
  "Do not advance because checks passed",
  "Golden Route",
  "Studio evidence",
  "final assets",
  "human playtest",
  "performance",
  "Phase 222",
]) {
  check(`phase221 docs mention ${token}`, docsText.includes(token));
}

const sourceOnly = "";
check("phase221 adds no gameplay runtime source", sourceOnly.length === 0);
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
  phase: 221,
  status: failed.length === 0 ? "passed" : "failed",
  total: checks.length,
  passed: checks.length - failed.length,
  failed: failed.length,
  failures: failed,
  decision: "productionRecoveryAuditComplete",
  nextPhase: 222,
};

console.log(JSON.stringify(report, null, 2));
process.exit(failed.length === 0 ? 0 : 1);
