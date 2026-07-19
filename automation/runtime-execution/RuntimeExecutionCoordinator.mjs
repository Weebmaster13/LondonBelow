import { fileURLToPath } from "node:url";
import { createReportBundle } from "./ExecutionReporter.mjs";
import { evaluateRuntimeExecution } from "./ExecutionPipeline.mjs";
import { runRuntimeExecutionSelfChecks } from "./SelfChecks.mjs";

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
  if (process.argv.includes("--self-check")) {
    printSelfChecks();
    return;
  }

  const result = runRuntimeExecution();
  console.log(JSON.stringify(result.session.summary, null, 2));
  console.log(`Session: ${result.session.sessionId}`);
  console.log("Runtime invoked: false");
  console.log("Certification authority invoked: false");
  process.exitCode = result.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
