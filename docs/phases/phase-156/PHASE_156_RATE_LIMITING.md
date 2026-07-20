# Rate Limiting

The runtime tracks bounded per-player request windows. Excess requests reject with `RateLimited`.

Rate limiting is server-side and independent of client timing claims.
