# Binding And Ownership

Composition instances bind to Roblox rendering sessions, rendering execution
sessions, rendering sessions, presentation sessions, and renderer IDs. Binding
is one-to-one for Phase 183.

Duplicate Roblox rendering-session binding rejects. Ownership records preserve
composition instance, Roblox rendering session, renderer ID, owner runtime,
revision, and deterministic ownership ordinal.

Bindings and ownership are evidence-bearing metadata only. They do not mutate
Roblox Rendering Session Runtime or claim any client-side authority.
