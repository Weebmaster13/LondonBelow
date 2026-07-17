# Chapter 0 Home Phase 121 Studio Evidence Capture Support

Phase 121 adds repository-supported automation for Chapter 0 Home Studio
certification evidence capture. It is tooling-only and does not change Chapter 0
gameplay, observation facts, presentation, remotes, persistence, Monster AI, save
execution, or Chapter 1 content.

The command is:

```powershell
npm run london:certify:phase120
```

The command verifies source attribution before any certification decision:

- current branch is `main`;
- local `HEAD` is a full commit hash;
- `origin/main` resolves to the same commit;
- the working tree is clean;
- evidence is written only after attribution is known.

The command writes deterministic local artifacts under ignored local state:

- `automation/local-state/phase120-certification-evidence.json`;
- `automation/local-state/phase120-certification-evidence.md`.

The JSON evidence includes:

- `schemaVersion`;
- `phase`;
- `runnerId`;
- `runtime`;
- `studio`;
- `status`;
- `setupStatus`;
- `assertionStatus`;
- `cleanupStatus`;
- `upstreamStatus`;
- `executedSuites`;
- `skippedSuites`;
- `totals`;
- `failures`;
- `warnings`;
- `productionCertified`;
- `evidenceId`;
- `exactSourceCommit`;
- `captureTimestamp`;
- `validationStatus`;
- `decisionStatus`;
- `nextAction`.

Exit codes are stable:

- `0`: authoritative certification completed successfully;
- `1`: runtime unavailable;
- `2`: execution blocked;
- `3`: validation failed;
- `4`: runner failed;
- `5`: cleanup failed;
- `6`: upstream failed;
- `7`: source attribution invalid.

The command does not duplicate certification logic. Production certification remains
owned by:

- `Phase118CertificationContract.validateResult()`;
- `Phase118CertificationContract.canProductionCertify()`.

The supported command currently reports `executionBlocked` when Roblox Studio is
detected but no supported non-interactive Studio execution and structured-result
capture API is configured for:

`ServerScriptService.Chapter0Home.Studio.Phase118CertificationRunner`

That blocked result is intentional and truthful. It prevents false Production
Certification claims while preserving deterministic evidence for release review.

Self-check coverage for the capture wrapper is available through:

```powershell
npm run london:certify:phase120:selfcheck
```

The wrapper self-checks cover JSON schema, Markdown schema, source attribution,
evidence validation, decision consistency, machine-readable export, artifact
overwrite safety, stale artifact rejection, corrupted artifact rejection, wrapper
exit codes, wrapper argument validation, cleanup verification, rerun safety, and
runtime truthfulness.
