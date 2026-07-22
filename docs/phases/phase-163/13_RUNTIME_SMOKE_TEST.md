# Runtime Smoke Test

The intended smoke path is:

Initialize Session Runtime -> Open Session -> Acquire Lock -> Begin Transaction -> Mark Dirty -> Commit Transaction -> Persistence Save -> Mark Clean -> Release Lock -> Close Session -> Shutdown.

Authoritative runtime success must not be claimed without Roblox Studio evidence imported through the Runtime Execution Framework.
