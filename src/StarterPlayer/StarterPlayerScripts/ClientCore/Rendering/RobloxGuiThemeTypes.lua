--!strict

local Types = {}

Types.SchemaVersion = "1.0.0"
Types.RuntimeVersion = "194.0.0"
Types.State = table.freeze({
	Idle = "Idle",
	Applying = "Applying",
	Applied = "Applied",
	Failed = "Failed",
	Shutdown = "Shutdown",
})
Types.FailureType = table.freeze({
	RuntimeShutdown = "GuiThemeRuntimeShutdown",
	RuntimeBusy = "GuiThemeRuntimeBusy",
	InvalidTheme = "GuiThemeInvalidTheme",
	InvalidRevision = "GuiThemeInvalidRevision",
	RevisionConflict = "GuiThemeRevisionConflict",
	StaleRevision = "GuiThemeStaleRevision",
	InvalidContract = "GuiThemeInvalidContract",
	InvalidTarget = "GuiThemeInvalidTarget",
	InvalidToken = "GuiThemeInvalidToken",
	UnsupportedProperty = "GuiThemeUnsupportedProperty",
	InvalidValue = "GuiThemeInvalidValue",
	BudgetExceeded = "GuiThemeBudgetExceeded",
	ApplyFailed = "GuiThemeApplyFailed",
	RollbackFailed = "GuiThemeRollbackFailed",
})
Types.Limits = table.freeze({
	maxThemes = 32,
	maxTokensPerTheme = 256,
	maxNodeStyles = 1024,
	maxPropertiesPerNode = 32,
	maxThemeIdLength = 64,
	maxTokenNameLength = 96,
	maxAudit = 1024,
	maxFailures = 256,
})
Types.AllowedProperties = table.freeze({
	BackgroundColor3 = "Color3",
	BorderColor3 = "Color3",
	ImageColor3 = "Color3",
	TextColor3 = "Color3",
	PlaceholderColor3 = "Color3",
	ScrollBarImageColor3 = "Color3",
	BackgroundTransparency = "number",
	BorderSizePixel = "number",
	ImageTransparency = "number",
	TextTransparency = "number",
	TextStrokeTransparency = "number",
	ScrollBarThickness = "number",
	TextStrokeColor3 = "Color3",
	FontFace = "Font",
	TextSize = "number",
})

return table.freeze(Types)
