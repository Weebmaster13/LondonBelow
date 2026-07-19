# Manual Studio Backend

The manual backend is the first supported reusable Studio backend.

It creates:

- source-bound execution session;
- temporary Rojo place artifact;
- runner invocation payload;
- expected evidence output path;
- exact manual instruction file;
- timeout and cleanup metadata;
- structured result import validation.

It enters `waitingForManualAction` and does not launch Studio automatically.

Resume/import command:

`npm run london:studio-backend:manual:resume -- --session <session-id>`

Imported evidence must match session ID, phase, commit, schema version, runner ID, and certification boundary rules.
