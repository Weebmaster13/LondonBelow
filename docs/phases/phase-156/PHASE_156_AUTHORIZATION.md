# Authorization

Authorization is separate from mutation. A request is authorized only after validation, eligibility, replay resistance, rate limit, and contention checks pass.

Sessions record `serverAuthorized = true` and `clientAuthorityAccepted = false`.
