--!strict
-- Shared constants for Phase 36 Content Registry Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeContentRegistrySchemaRuntime"

Types.SchemaType = {
	ContentDefinitionSchema = "ContentDefinitionSchema",
	ContentCategorySchema = "ContentCategorySchema",
	ContentReferenceSchema = "ContentReferenceSchema",
	ContentDependencySchema = "ContentDependencySchema",
	ContentPackageSchema = "ContentPackageSchema",
	ContentVersionSchema = "ContentVersionSchema",
	ContentTagSchema = "ContentTagSchema",
	SystemContentRegistrySchema = "SystemContentRegistrySchema",
}

Types.ContentDomain = {
	Chapter = true,
	Scene = true,
	Room = true,
	Region = true,
	Building = true,
	World = true,
	Item = true,
	Inventory = true,
	Puzzle = true,
	Interaction = true,
	Objective = true,
	Narrative = true,
	Localization = true,
	Audio = true,
	Presentation = true,
	Monster = true,
	Entity = true,
	Accessibility = true,
	Save = true,
	Session = true,
	System = true,
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateContent = "DuplicateContent",
	DuplicateCategory = "DuplicateCategory",
	DuplicateReference = "DuplicateReference",
	DuplicateDependency = "DuplicateDependency",
	DuplicatePackage = "DuplicatePackage",
	DuplicateVersion = "DuplicateVersion",
	DuplicateTag = "DuplicateTag",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxContentDefinitions = 2000,
	MaxCategories = 700,
	MaxReferences = 2000,
	MaxDependencies = 2000,
	MaxPackages = 700,
	MaxVersions = 900,
	MaxTags = 900,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 420,
	MaxPayloadStringLength = 640,
	MaxTagsPerSchema = 32,
	MaxPackageMembers = 128,
	MaxDependencyLinks = 64,
	MaxReferenceLinks = 64,
}

return Types
