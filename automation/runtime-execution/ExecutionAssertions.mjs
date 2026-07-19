export function createAssertion(assertionId, name, status, category, message) {
  return { assertionId, name, status, category, message };
}

export function createFrameworkAssertions(sessionId) {
  return [
    createAssertion(`${sessionId}.assertion.schema`, "SchemaValidated", "PASS", "Static", "Session schema validated."),
    createAssertion(`${sessionId}.assertion.environment`, "EnvironmentCaptured", "PASS", "Static", "Repository environment captured."),
    createAssertion(`${sessionId}.assertion.backend`, "BackendSelected", "PASS", "Static", "Backend contract selected."),
    createAssertion(`${sessionId}.assertion.runtime`, "RuntimeExecuted", "BLOCKED", "Runtime", "No supported backend invoked runtime."),
    createAssertion(
      `${sessionId}.assertion.certification`,
      "CertificationDecision",
      "NOT_EXECUTED",
      "Certification",
      "Framework does not own certification decisions."
    ),
    createAssertion(`${sessionId}.assertion.cleanup`, "CleanupRegistered", "PASS", "Static", "Cleanup policy registered.")
  ];
}
