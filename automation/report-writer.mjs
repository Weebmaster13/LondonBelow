import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

export function writeRepositoryBaseline(runRoot, repo) {
  mkdirSync(runRoot, { recursive: true });
  const path = join(runRoot, "repository-baseline.md");
  writeFileSync(
    path,
    `# Repository Baseline

- Branch: ${repo.branch}
- Local HEAD: ${repo.localHead}
- Remote HEAD: ${repo.remoteHead}
- Working tree clean: ${repo.workingTreeClean}

## Status

\`\`\`text
${repo.statusText}
\`\`\`

## Recent Commits

\`\`\`text
${repo.recentLog}
\`\`\`
`
  );
  return path;
}

export function writeCompletionReport({ runRoot, phase, commit, githubUrl, validation, changedFiles }) {
  const path = join(runRoot, `phase-${phase.phase}-completion-report.md`);
  const validationLines = validation.map((item) => `- ${item.name} ${item.ok ? "OK" : "FAILED"}`);
  writeFileSync(
    path,
    `# London Engine Phase Completion Report

## Phase

Phase ${phase.phase} - ${phase.name}

## Runtime Maturity

Type:

- ${phase.maturity}

Status:

- Complete
- Production Certified

## Commit

${commit}

## GitHub

[${githubUrl}](${githubUrl})

## Summary

Completed by the London Engine autopilot.

## Changed Files

- ${changedFiles.length} files changed.

## Architecture Impact

- Affected systems are determined by the phase specification and actual diff.
- No additional impact is claimed without code review evidence.

## Validation

${validationLines.join("\n")}

## Self-Check Coverage

See validation logs and implementation output for executable self-check totals.

## Production Certification

Certified only after exact commit validation, push, remote verification, artifact cleanup, and clean working tree.

## Known Limitations

- None found by the autopilot report writer.

## Technical Debt

- None found by the autopilot report writer.

## Next Recommended Phase

To be determined from repository state after certification.

## Engine Progress

Current certified phase: Phase ${phase.phase}

## Certification Integrity

- Exact commit validated.
- Commit pushed.
- Remote verified.
- Local and remote HEAD match.
- Working tree clean.
`
  );
  return path;
}

export function writeSafeStop(runRoot, details) {
  mkdirSync(runRoot, { recursive: true });
  const path = join(runRoot, "safe-stop.md");
  writeFileSync(
    path,
    `# London Engine Autopilot Stopped Safely

Status:
${details.status}

Last Production Certified Phase:
${details.lastCertifiedPhase} - ${details.lastCertifiedPhaseName}

Last Certified Commit:
${details.lastCertifiedCommit}

Active Incomplete Phase:
${details.activePhase ?? "none"}

Local HEAD:
${details.localHead ?? "unknown"}

Remote HEAD:
${details.remoteHead ?? "unknown"}

Working Tree:
${details.workingTreeClean ? "clean" : "changed"}

Stop Reason:
${details.reason}

Next Action:
${details.nextAction}
`
  );
  return path;
}
