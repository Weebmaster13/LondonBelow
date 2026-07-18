import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join, relative, sep } from "node:path";

const repoRoot = process.cwd();
const generatedDir = join(repoRoot, "automation", "generated");
const governanceDir = join(repoRoot, "src", "ServerScriptService", "Core", "Governance");
const contractsDir = join(governanceDir, "Contracts");
const bootstrapPath = join(repoRoot, "src", "ServerScriptService", "Core", "Bootstrap.server.lua");
const statePath = join(repoRoot, "automation", "state", "phase-state.json");
const contractModuleOrder = [
  "CoreContracts.lua",
  "ObservationContracts.lua",
  "NarrativeContracts.lua",
  "GameplayContracts.lua",
  "PresentationContracts.lua",
  "CertificationContracts.lua",
  "AssetExecutionContracts.lua",
  "StudioExecutionContracts.lua",
  "ChapterContracts.lua",
  "InfrastructureContracts.lua",
];
const documentedExternalDependencies = new Set([
  "Director Ecosystem",
  "Governance",
  "London Bible canon",
  "Narrative Runtime",
  "Presentation Runtime",
  "RemoteManager",
  "Save Journal Identity Runtime Foundation",
]);
const frameworkBootstrapServices = new Set([
  "DependencyManager",
  "Diagnostics",
  "EventBus",
  "Logger",
  "RemoteManager",
  "Scheduler",
  "ServiceLocator",
  "SnapshotManager",
]);
const documentedDeferredBootstrapDependencies = new Set([
  "GameplayExecutionCoordinator->HorrorOrchestrator",
  "GameplayExecutionCoordinator->LivingCognitionCoordinator",
  "GameplayExecutionCoordinator->MonsterIntelligenceCoordinator",
  "GameplayExecutionCoordinator->NarrativeCoordinator",
  "GameplayExecutionCoordinator->SaveCoordinator",
  "LivingCognitionCoordinator->HorrorOrchestrator",
  "MonsterAIService->HorrorOrchestrator",
  "NarrativeCoordinator->HorrorOrchestrator",
  "NarrativeCoordinator->LivingCognitionCoordinator",
  "ObjectiveCoordinator->NarrativeCoordinator",
  "ObjectiveCoordinator->SaveCoordinator",
  "PersistenceCoordinator->SaveCoordinator",
  "PuzzleCoordinator->NarrativeCoordinator",
  "SessionCoordinator->SaveCoordinator",
]);

function normalizePath(path) {
  return path.split(sep).join("/");
}

function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.keys(value).sort().map((key) => [key, stable(value[key])]));
  }
  return value;
}

function writeDeterministicJson(path, value) {
  writeFileSync(path, `${JSON.stringify(stable(value), null, 2)}\n`);
}

function readGeneratedJson(name) {
  const path = join(generatedDir, name);
  if (!existsSync(path)) return null;
  return readFileSync(path, "utf8");
}

function extractBalanced(text, openIndex) {
  let depth = 0;
  for (let index = openIndex; index < text.length; index += 1) {
    const char = text[index];
    if (char === "{") depth += 1;
    if (char === "}") {
      depth -= 1;
      if (depth === 0) return text.slice(openIndex, index + 1);
    }
  }
  throw new Error("Unable to extract balanced Lua table");
}

function extractBalancedParentheses(text, openIndex) {
  let depth = 0;
  for (let index = openIndex; index < text.length; index += 1) {
    const char = text[index];
    if (char === "(") depth += 1;
    if (char === ")") {
      depth -= 1;
      if (depth === 0) return text.slice(openIndex, index + 1);
    }
  }
  throw new Error("Unable to extract balanced Lua call");
}

function splitTopLevelTables(body) {
  const entries = [];
  let depth = 0;
  let start = -1;
  for (let index = 0; index < body.length; index += 1) {
    const char = body[index];
    if (char === "{") {
      if (depth === 0) start = index;
      depth += 1;
    } else if (char === "}") {
      depth -= 1;
      if (depth === 0 && start >= 0) {
        entries.push(body.slice(start, index + 1));
        start = -1;
      }
    }
  }
  return entries;
}

function extractField(text, fieldName) {
  const match = text.match(new RegExp(`${fieldName}\\s*=\\s*"([^"]*)"`));
  return match ? match[1] : "";
}

function extractStringArray(text, fieldName) {
  const fieldIndex = text.indexOf(`${fieldName} =`);
  if (fieldIndex < 0) return [];
  const openIndex = text.indexOf("{", fieldIndex);
  if (openIndex < 0) return [];
  const table = extractBalanced(text, openIndex);
  return [...table.matchAll(/"([^"]*)"/g)].map((match) => match[1]);
}

function parseContracts() {
  if (!existsSync(contractsDir)) throw new Error("Governance Contracts directory is missing");
  const existingModules = new Set(readdirSync(contractsDir).filter((file) => file.endsWith("Contracts.lua")));
  const modules = contractModuleOrder.filter((file) => existingModules.has(file));
  const contracts = [];

  for (const module of modules) {
    const text = readFileSync(join(contractsDir, module), "utf8");
    const marker = "local contracts";
    const markerIndex = text.indexOf(marker);
    const openIndex = text.indexOf("{", text.indexOf("=", markerIndex));
    const table = extractBalanced(text, openIndex);
    const body = table.slice(1, -1);
    for (const entry of splitTopLevelTables(body)) {
      const systemName = extractField(entry, "systemName");
      if (!systemName) throw new Error(`Missing systemName in ${module}`);
      contracts.push({
        systemName,
        ownerLayer: extractField(entry, "ownerLayer"),
        status: extractField(entry, "status"),
        responsibilities: extractStringArray(entry, "responsibilities"),
        doesNotOwn: extractStringArray(entry, "doesNotOwn"),
        dependencies: extractStringArray(entry, "dependencies"),
        diagnosticsExposed: extractStringArray(entry, "diagnosticsExposed"),
        snapshotProviders: extractStringArray(entry, "snapshotProviders"),
        cleanupBehavior: extractStringArray(entry, "cleanupBehavior"),
        documentation: extractStringArray(entry, "documentation"),
        tags: extractStringArray(entry, "tags"),
        sourceModule: normalizePath(relative(repoRoot, join(contractsDir, module))),
      });
    }
  }

  const seen = new Set();
  for (const contract of contracts) {
    if (seen.has(contract.systemName)) throw new Error(`Duplicate contract: ${contract.systemName}`);
    seen.add(contract.systemName);
  }
  return contracts;
}

function parseBootstrap() {
  const text = readFileSync(bootstrapPath, "utf8");
  const requireMatches = [...text.matchAll(/local\s+([A-Za-z0-9_]+)\s*=\s*require\(([^)]+)\)/g)];
  const requireMap = new Map(requireMatches.map((match) => [match[1], match[2].replace(/\s+/g, " ").trim()]));
  const registrations = [];
  const marker = "Framework.registerModule";
  let position = 0;
  let searchIndex = 0;
  while (true) {
    const markerIndex = text.indexOf(marker, searchIndex);
    if (markerIndex < 0) break;
    const openIndex = text.indexOf("(", markerIndex);
    const call = extractBalancedParentheses(text, openIndex);
    searchIndex = openIndex + call.length;
    const nameMatch = call.match(/"([^"]+)"/);
    const symbolMatch = call.match(/,\s*([A-Za-z0-9_]+)\s*,/);
    if (!nameMatch || !symbolMatch) continue;
    const strings = [...call.matchAll(/"([^"]+)"/g)].map((match) => match[1]);
    position += 1;
    registrations.push({
      moduleName: nameMatch[1],
      implementationSymbol: symbolMatch[1],
      implementationRequire: requireMap.get(symbolMatch[1]) ?? "unknown",
      dependencies: strings.slice(1),
      registrationPosition: position,
    });
  }
  return registrations;
}

function catalogValidations() {
  const files = [];
  function walk(dir) {
    for (const item of readdirSync(dir, { withFileTypes: true })) {
      const path = join(dir, item.name);
      if (item.isDirectory()) walk(path);
      else if (item.name === "Validation.lua" || item.name.endsWith("Validation.lua")) files.push(path);
    }
  }
  walk(join(repoRoot, "src"));
  return files.sort().map((path) => ({
    subsystem: normalizePath(relative(join(repoRoot, "src", "ServerScriptService"), path)).split("/")[0],
    modulePath: normalizePath(relative(repoRoot, path)),
    callableEntryPoint: "validate",
    runtimeRequirement: "Roblox Luau module environment",
    staticExecutionAvailable: false,
    robloxStudioRequired: true,
    packageScriptExposure: "unknown",
    expectedOutputShape: "(boolean, string?)",
    certificationRelevance: "validation boundary evidence",
    currentExecutionStatus: "blocked",
  }));
}

function catalogSelfChecks() {
  const files = [];
  function walk(dir) {
    for (const item of readdirSync(dir, { withFileTypes: true })) {
      const path = join(dir, item.name);
      if (item.isDirectory()) walk(path);
      else if (item.name === "SelfChecks.lua" || item.name.endsWith("SelfChecks.lua")) files.push(path);
    }
  }
  walk(join(repoRoot, "src"));
  const packageJson = JSON.parse(readFileSync(join(repoRoot, "package.json"), "utf8"));
  const scripts = packageJson.scripts ?? {};
  return files.sort().map((path) => {
    const normalized = normalizePath(relative(repoRoot, path));
    const exposedScript = Object.entries(scripts).find(([, command]) => command.includes(normalized));
    return {
      subsystem: normalizePath(relative(join(repoRoot, "src", "ServerScriptService"), path)).split("/")[0],
      modulePath: normalized,
      callableEntryPoint: "run",
      runtimeRequirement: "Roblox Luau module environment unless wrapped by automation",
      staticExecutionAvailable: false,
      robloxStudioRequired: true,
      luneOrLuauRequired: false,
      packageScriptExposure: exposedScript ? exposedScript[0] : "notExposed",
      expectedOutputShape: "{ total: number, passed: number, failures: table }",
      certificationRelevance: "self-check evidence only when executed by an authoritative runtime",
      currentExecutionStatus: "blocked",
    };
  });
}

function docsCheck(contracts) {
  const state = JSON.parse(readFileSync(statePath, "utf8"));
  const required = [
    "ROADMAP.md",
    "TASKS.md",
    "LONDON_ENGINE.md",
    "LONDON_ENGINE_MASTER_CONTEXT.md",
  ];
  const findings = [];
  for (const file of required) {
    const text = readFileSync(join(repoRoot, file), "utf8");
    const normalizedText = text.replace(/\s+/g, " ");
    const normalizedNextPhase = state.nextRecommendedPhaseName.replace(/\s+/g, " ");
    if (!normalizedText.includes(`Phase ${state.latestCandidatePhase}`)) {
      findings.push(`${file} missing latest candidate phase`);
    }
    if (!normalizedText.includes(normalizedNextPhase)) findings.push(`${file} missing next recommended phase name`);
    if (!normalizedText.includes(`Phase ${state.lastCertifiedPhase}`)) {
      findings.push(`${file} missing latest certified phase`);
    }
  }

  for (const contract of contracts) {
    for (const doc of contract.documentation) {
      if (!existsSync(join(repoRoot, doc))) findings.push(`${contract.systemName} references missing doc ${doc}`);
    }
  }

  return findings;
}

function contractCheck(contracts) {
  const findings = [];
  const names = new Set(contracts.map((contract) => contract.systemName));
  for (const contract of contracts) {
    for (const dependency of contract.dependencies) {
      if (!names.has(dependency) && !documentedExternalDependencies.has(dependency)) {
        findings.push(`${contract.systemName} depends on missing contract ${dependency}`);
      }
    }
  }
  return findings;
}

function bootstrapCheck(registrations) {
  const findings = [];
  const positions = new Map(registrations.map((registration) => [registration.moduleName, registration.registrationPosition]));
  for (const registration of registrations) {
    for (const dependency of registration.dependencies) {
      const edge = `${registration.moduleName}->${dependency}`;
      if (frameworkBootstrapServices.has(dependency)) continue;
      if (documentedDeferredBootstrapDependencies.has(edge)) continue;
      if (!positions.has(dependency)) findings.push(`${registration.moduleName} depends on missing module ${dependency}`);
      else if (positions.get(dependency) > registration.registrationPosition) {
        findings.push(`${registration.moduleName} depends on later module ${dependency}`);
      }
    }
  }
  return findings;
}

function generate() {
  mkdirSync(generatedDir, { recursive: true });
  const contracts = parseContracts();
  const bootstrap = parseBootstrap();
  writeDeterministicJson(join(generatedDir, "engine-contract-catalog.json"), contracts);
  writeDeterministicJson(join(generatedDir, "bootstrap-order.json"), bootstrap);
  writeDeterministicJson(join(generatedDir, "validation-catalog.json"), catalogValidations());
  writeDeterministicJson(join(generatedDir, "self-check-catalog.json"), catalogSelfChecks());
  return { contracts, bootstrap };
}

function check() {
  const before = new Map([
    ["engine-contract-catalog.json", readGeneratedJson("engine-contract-catalog.json")],
    ["bootstrap-order.json", readGeneratedJson("bootstrap-order.json")],
    ["validation-catalog.json", readGeneratedJson("validation-catalog.json")],
    ["self-check-catalog.json", readGeneratedJson("self-check-catalog.json")],
  ]);
  const { contracts, bootstrap } = generate();
  const findings = [
    ...contractCheck(contracts),
    ...bootstrapCheck(bootstrap),
    ...docsCheck(contracts),
  ];
  for (const [name, content] of before.entries()) {
    const after = readGeneratedJson(name);
    if (content !== null && content !== after) findings.push(`${name} was not up to date`);
  }
  if (findings.length > 0) {
    console.error(findings.join("\n"));
    process.exit(1);
  }
  console.log(`Architecture catalogs valid: ${contracts.length} contracts, ${bootstrap.length} bootstrap registrations`);
}

function status() {
  const { contracts, bootstrap } = generate();
  console.log("London Engine Architecture Inventory");
  console.log(`Contracts: ${contracts.length}`);
  console.log(`Bootstrap registrations: ${bootstrap.length}`);
  console.log(`Validation modules: ${catalogValidations().length}`);
  console.log(`Self-check modules: ${catalogSelfChecks().length}`);
}

const command = process.argv[2] ?? "status";
if (command === "generate") generate();
else if (command === "check") check();
else if (command === "status") status();
else {
  console.error(`Unknown architecture catalog command: ${command}`);
  process.exit(1);
}
