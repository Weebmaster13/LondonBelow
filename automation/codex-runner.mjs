import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runCommand } from "./repository-state.mjs";

export function buildCodexPrompt({ phase, specPath, reviewPath }) {
  return `Read AGENTS.md, ENGINE_CONSTITUTION.md, LONDON_ENGINE.md, LONDON_ENGINE_MASTER_CONTEXT.md, ROADMAP.md, TASKS.md, the generated phase specification at ${specPath}, and the architecture review at ${reviewPath}.

Implement exactly Phase ${phase.phase} - ${phase.name}.

Do not begin Phase ${phase.phase + 1}.
Use the repository as source of truth.
Preserve user changes.
Run required validation.
Do not fabricate commits, GitHub links, self-check totals, validation results, or Production Certification.
If authentication, usage limits, architecture gates, validation failures, or dirty worktrees block completion, stop and report the exact blocker.`;
}

export function runCodexTask({ config, phase, specPath, reviewPath, runRoot, cwd }) {
  const prompt = buildCodexPrompt({ phase, specPath, reviewPath });
  const promptPath = join(runRoot, `phase-${phase.phase}-codex-prompt.txt`);
  writeFileSync(promptPath, prompt);

  if (process.env.LONDON_AUTOPILOT_ENABLE_CODEX !== "1") {
    return {
      ok: false,
      blocked: true,
      promptPath,
      reason:
        "Codex execution is disabled. Set LONDON_AUTOPILOT_ENABLE_CODEX=1 after verifying codex login and CLI syntax."
    };
  }

  const inputPath = promptPath;
  const args = config.codexArgs ?? ["exec", "--full-auto", "-"];
  const stdinPrompt = readFileSync(inputPath, "utf8");
  const result = runCommand(config.codexExecutable ?? "codex", args, {
    cwd,
    env: process.env,
    maxBuffer: 1024 * 1024 * 50,
    input: stdinPrompt
  });
  writeFileSync(join(runRoot, `phase-${phase.phase}-codex-stdout.txt`), result.stdout);
  writeFileSync(join(runRoot, `phase-${phase.phase}-codex-stderr.txt`), result.stderr);
  writeFileSync(
    join(runRoot, `phase-${phase.phase}-codex-result.json`),
    `${JSON.stringify(
      {
        command: result.commandLine,
        exitCode: result.exitCode,
        status: result.status,
        ok: result.ok,
        durationMs: result.durationMs,
        failureKind: result.failureKind,
        error: result.error,
        signal: result.signal
      },
      null,
      2
    )}\n`
  );
  return { ok: result.ok, promptPath, result };
}
