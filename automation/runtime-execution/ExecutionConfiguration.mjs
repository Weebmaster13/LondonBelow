export function createExecutionConfiguration(input = {}) {
  return {
    phase: input.phase ?? 151,
    phaseName: input.phaseName ?? "Runtime Execution Framework Foundation",
    requestedBackend: input.requestedBackend ?? "StudioManual",
    participants: input.participants ?? [],
    targets: input.targets ?? ["RuntimeValidation", "RegressionSuite", "QASession", "CertificationRun"],
    policies: {
      timeoutMs: input.timeoutMs ?? 300000,
      retries: input.retries ?? 0,
      cleanupRequired: true,
      runtimeEvidenceRequired: input.runtimeEvidenceRequired ?? false,
      certificationDecisionAllowed: false
    }
  };
}
