--!strict

local Types = {}

Types.SchemaVersion = "1.0.0"
Types.ProviderName = "robloxGuiInstanceContractRuntime"

Types.ContractState = table.freeze({ Draft = "Draft", Validated = "Validated", Published = "Published", Rejected = "Rejected", Retired = "Retired" })
Types.ValueKind = table.freeze({ Boolean = "Boolean", Number = "Number", String = "String", Enum = "Enum", Color3 = "Color3", UDim = "UDim", UDim2 = "UDim2", Vector2 = "Vector2", Rect = "Rect", NumberSequence = "NumberSequence", ColorSequence = "ColorSequence", AssetReference = "AssetReference", NodeReference = "NodeReference", LocalizationReference = "LocalizationReference" })
Types.PropertyMutability = table.freeze({ CreateOnly = "CreateOnly", Mutable = "Mutable", Immutable = "Immutable", Derived = "Derived", Forbidden = "Forbidden" })
Types.ReferenceKind = table.freeze({ Parent = "Parent", SelectionGroup = "SelectionGroup", NextSelection = "NextSelection", Asset = "Asset", Localization = "Localization" })
Types.FailureType = table.freeze({
	RuntimeShutdown = "RuntimeShutdown", UnsafePayload = "UnsafePayload", InvalidSchema = "InvalidSchema",
	UnsupportedVersion = "UnsupportedVersion", UnsupportedClass = "UnsupportedClass", ForbiddenClass = "ForbiddenClass",
	UnsupportedProperty = "UnsupportedProperty", ForbiddenProperty = "ForbiddenProperty", InvalidPropertyValue = "InvalidPropertyValue",
	InvalidHierarchy = "InvalidHierarchy", InvalidReference = "InvalidReference", DuplicateContract = "DuplicateContract",
	DuplicateNode = "DuplicateNode", UnknownField = "UnknownField", MissingField = "MissingField",
	IllegalTransition = "IllegalTransition", TerminalMutation = "TerminalMutation", BudgetExceeded = "BudgetExceeded",
})
Types.Limits = table.freeze({ maxContracts = 256, maxNodesPerContract = 2048, maxDepth = 64, maxPropertiesPerNode = 96, maxTagsPerNode = 24, maxAuditRecords = 4096, maxFailures = 512 })

return table.freeze(Types)
