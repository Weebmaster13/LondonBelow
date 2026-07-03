# TRIGGER DEFINITION RUNTIME

Trigger definitions are inert records that identify a future trigger by id, domain, owner, and referenced schema ids. They do not execute, dispatch, invoke callbacks, mutate runtime state, or own gameplay truth.

## Production Hardening

Production hardening: definitions reject invalid references, oversized reference lists, unsafe payloads, execution markers, event dispatch markers, callback markers, client/service/content markers, and duplicate ids before mutation.
