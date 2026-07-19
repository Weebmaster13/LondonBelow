import { fileURLToPath } from "node:url";
import { createReportBundle } from "./ExecutionReporter.mjs";
import { evaluateRuntimeExecution } from "./ExecutionPipeline.mjs";
import { runRuntimeExecutionSelfChecks } from "./SelfChecks.mjs";
import { createBackendRegistry } from "./backends/index.mjs";
import { writeBackendCatalog } from "./BackendCatalogWriter.mjs";

export function runRuntimeExecution(input = {}) {
  const evaluation = evaluateRuntimeExecution(input);
  return {
    ...evaluation,
    reports: createReportBundle(evaluation)
  };
}

function printSelfChecks() {
  const results = runRuntimeExecutionSelfChecks();
  const failures = results.filter((check) => !check.ok);
  console.log(`TOTAL ${results.length}`);
  console.log(`PASSED ${results.length - failures.length}`);
  console.log(`FAILURES ${failures.length}`);
  for (const failure of failures) {
    console.log(`FAIL ${failure.name}: ${failure.detail || "failed"}`);
  }
  process.exitCode = failures.length === 0 ? 0 : 5;
}

function main() {
  if (process.argv.includes("--help")) {
    console.log("Runtime Execution Framework");
    console.log("--self-check       run framework self-checks");
    console.log("--backends         print backend catalog");
    console.log("--write-catalog    write generated backend catalog");
    console.log("--json             print full JSON evaluation");
    console.log("--phase=152        override phase");
    process.exitCode = 0;
    return;
  }

  if (process.argv.includes("--self-check")) {
    printSelfChecks();
    return;
  }

  if (process.argv.includes("--backends")) {
    console.log(JSON.stringify(createBackendRegistry().backends, null, 2));
    process.exitCode = 0;
    return;
  }

  if (process.argv.includes("--write-catalog")) {
    const result = writeBackendCatalog();
    console.log(`Backend catalog: ${result.path}`);
    process.exitCode = result.ok ? 0 : 5;
    return;
  }

  const phaseArg = process.argv.find((arg) => arg.startsWith("--phase="));
  const phase = phaseArg ? Number.parseInt(phaseArg.split("=")[1], 10) : undefined;

  const result = runRuntimeExecution(Number.isInteger(phase) ? { phase, phaseName: phase === 152 ? "Studio Execution Backend Foundation" : undefined } : {});
  if (process.argv.includes("--json")) {
    console.log(JSON.stringify(result, null, 2));
    process.exitCode = result.exitCode;
    return;
  }
  console.log(JSON.stringify(result.session.summary, null, 2));
  console.log(`Session: ${result.session.sessionId}`);
  console.log("Runtime invoked: false");
  console.log("Certification authority invoked: false");
  process.exitCode = result.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
