# Memory Provider

The Memory Provider supports `Save`, `Load`, `Delete`, `Exists`, and `List` using runtime memory only.

It deep-copies payloads on save and load boundaries. It does not write DataStores, access disk, create networking, or persist across shutdown.
