export function classifySessionRecovery(sessionRecord, nowTimestamp) {
  if (sessionRecord === null || sessionRecord === undefined) {
    return { status: "missingSession", resumable: false, reason: "No session record exists." };
  }
  if (sessionRecord.summary?.status === "executionBlocked") {
    return { status: "blockedSession", resumable: true, reason: "Blocked manual sessions may resume through evidence import." };
  }
  return { status: "archivedSession", resumable: false, reason: `Session already archived at ${nowTimestamp}.` };
}
