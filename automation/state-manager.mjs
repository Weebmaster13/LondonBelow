import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

export const statePath = "automation/state/phase-state.json";

export function readState(path = statePath) {
  if (!existsSync(path)) {
    return null;
  }
  return JSON.parse(readFileSync(path, "utf8"));
}

export function writeState(state, path = statePath) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, `${JSON.stringify({ ...state, updatedAt: new Date().toISOString() }, null, 2)}\n`);
}

export function markStatus(state, status, reason = null, patch = {}) {
  return {
    ...state,
    ...patch,
    status,
    lastStopReason: reason
  };
}

export function updateFromRepository(state, repo) {
  return {
    ...state,
    activeBranch: repo.branch,
    localHead: repo.localHead,
    remoteHead: repo.remoteHead,
    workingTreeClean: repo.workingTreeClean
  };
}
