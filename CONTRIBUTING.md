# Contributing to London Below

London Below is treated as a long-term Roblox horror engine, not a small experiment.

## Before Editing

- Read `AGENTS.md`, `ARCHITECTURE.md`, and the relevant design document.
- Run `git status --short --branch`.
- Inspect nearby code before changing it.
- Preserve unrelated user changes.

## Implementation Rules

- Do not add throwaway systems.
- Do not add placeholder logic unless the user explicitly requests scaffolding and the placeholder is clearly labeled.
- Do not create giant God scripts.
- Keep every system modular, logged, error-aware, multiplayer-safe, and expandable.
- Keep server authority over gameplay truth.
- Keep client code focused on input and presentation.
- Put code in the folder that matches its responsibility.

## Commit Rules

- Stage only files related to the task.
- Use clear imperative commit messages.
- Run relevant checks before committing.
- Do not commit generated `.rbxl`, `.rbxlx`, `.rbxm`, `.rbxmx`, `sourcemap.json`, or local verification files.

## Required Checks

For normal code changes:

```powershell
rojo sourcemap default.project.json --output sourcemap.json
Remove-Item -Force sourcemap.json
stylua --check src
selene src
```

For Rojo mapping changes:

```powershell
rojo build default.project.json --output rojo-verify.rbxlx
Remove-Item -Force rojo-verify.rbxlx
```

## Review Checklist

- Does this obey the user's request exactly?
- Does this preserve London Below's original horror identity?
- Is the server authoritative where it should be?
- Are remotes validated and rate-limited when introduced?
- Does the system log important transitions and failures?
- Does the system handle errors and disconnected players?
- Can this scale to more chapters, monsters, and multiplayer sessions?
