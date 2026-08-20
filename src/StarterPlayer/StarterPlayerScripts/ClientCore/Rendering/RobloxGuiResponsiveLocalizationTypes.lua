--!strict

local Types = {}

Types.RuntimeVersion = "191.1.0"
Types.ExecutionRuntimeVersion = "190.1.0"
Types.DefaultLocale = "en-us"
Types.FailureType = table.freeze({
	RuntimeShutdown = "ResponsiveLocalizationRuntimeShutdown",
	InvalidBundle = "InvalidLocalizationBundle",
	InvalidLocale = "InvalidLocale",
	InvalidContext = "InvalidResponsiveContext",
	MissingLocalizationKey = "MissingLocalizationKey",
	InvalidPlaceholder = "InvalidLocalizationPlaceholder",
	UnsupportedPolicy = "UnsupportedResponsivePolicy",
	OwnershipViolation = "ResponsiveLocalizationOwnershipViolation",
	StaleGeneration = "StaleResponsiveLocalizationGeneration",
	RuntimeBusy = "ResponsiveLocalizationRuntimeBusy",
	StaleBundleRevision = "StaleLocalizationBundleRevision",
	BundleRevisionConflict = "LocalizationBundleRevisionConflict",
	RefreshApplyFailed = "ResponsiveLocalizationRefreshApplyFailed",
	RefreshRollbackFailed = "ResponsiveLocalizationRefreshRollbackFailed",
	MalformedTemplate = "MalformedLocalizationTemplate",
})
Types.Limits = table.freeze({
	maxBundles = 32,
	maxEntriesPerBundle = 2048,
	maxTextLength = 8192,
	maxKeyLength = 160,
	maxPlaceholders = 32,
	maxAudit = 512,
	maxFailures = 128,
	maxLocaleLength = 35,
	maxRefreshPlans = 4096,
	maxQueuedViewportRefreshes = 1,
})

return table.freeze(Types)
