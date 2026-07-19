export function createTimeoutPolicy(timeoutMs = 300000) {
  return {
    timeoutMs,
    startedAt: null,
    expiresAt: null,
    finite: Number.isInteger(timeoutMs) && timeoutMs > 0,
    cancellationSupported: true
  };
}

export function classifyTimeout(startedAtMs, timeoutMs, nowMs = Date.now()) {
  if (!Number.isInteger(timeoutMs) || timeoutMs <= 0) return "invalidTimeout";
  return nowMs - startedAtMs >= timeoutMs ? "timedOut" : "withinTimeout";
}
