import { git, getChangedFiles } from "./repository-state.mjs";

export function commitPhase(config, message, cwd = process.cwd()) {
  const before = git(config, ["rev-parse", "HEAD"], { cwd }).stdout.trim();
  const add = git(config, ["add", "-A"], { cwd });
  if (!add.ok) return { ok: false, step: "add", add };
  const commit = git(config, ["commit", "-m", message], { cwd, maxBuffer: 1024 * 1024 * 20 });
  if (!commit.ok) return { ok: false, step: "commit", commit };
  const after = git(config, ["rev-parse", "HEAD"], { cwd }).stdout.trim();
  return {
    ok: true,
    before,
    commit: after,
    changedFiles: getChangedFiles(config, before, after, cwd),
    output: commit.stdout + commit.stderr
  };
}

export function pushAndVerify(config, cwd = process.cwd()) {
  const push = git(config, ["push", "origin", config.branch ?? "main"], {
    cwd,
    maxBuffer: 1024 * 1024 * 20
  });
  if (!push.ok) return { ok: false, step: "push", push };
  const localHead = git(config, ["rev-parse", "HEAD"], { cwd }).stdout.trim();
  const remote = git(config, ["ls-remote", "origin", `refs/heads/${config.branch ?? "main"}`], {
    cwd
  });
  const remoteHead = remote.stdout.split(/\s+/)[0] ?? "";
  return {
    ok: remote.ok && localHead === remoteHead,
    localHead,
    remoteHead,
    url: `https://github.com/Weebmaster13/LondonBelow/commit/${localHead}`,
    push,
    remote
  };
}
