--!strict

local Types = {}

Types.SchemaVersion = "1.0.0"
Types.RuntimeVersion = "196.0.0"
Types.RenderingExecutionVersion = "195.0.0"
Types.RuntimeState = table.freeze({
	Idle = "Idle",
	Composing = "Composing",
	Committed = "Committed",
	Failed = "Failed",
	Shutdown = "Shutdown",
})
Types.ComponentKind = table.freeze({
	Screen = "Screen",
	Panel = "Panel",
	Stack = "Stack",
	Grid = "Grid",
	Text = "Text",
	Button = "Button",
	Image = "Image",
	Scroll = "Scroll",
})
Types.FailureType = table.freeze({
	RuntimeShutdown = "ComponentRuntimeShutdown",
	RuntimeBusy = "ComponentRuntimeBusy",
	InvalidComposition = "InvalidComposition",
	UnsupportedSchemaVersion = "UnsupportedComponentSchemaVersion",
	UnsupportedKind = "UnsupportedComponentKind",
	DuplicateComponent = "DuplicateComponent",
	MissingParent = "MissingComponentParent",
	HierarchyCycle = "ComponentHierarchyCycle",
	BudgetExceeded = "ComponentBudgetExceeded",
	InvalidProps = "InvalidComponentProps",
	RenderRejected = "ComponentRenderRejected",
})
Types.Limits = table.freeze({
	maxComponents = 512,
	maxDepth = 32,
	maxPropsPerComponent = 64,
	maxStringLength = 8192,
	maxTagsPerComponent = 32,
	maxAuditRecords = 1024,
	maxFailures = 256,
})

return table.freeze(Types)
