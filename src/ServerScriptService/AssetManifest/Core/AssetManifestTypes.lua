--!strict
-- Shared constants and runtime limits for Phase 45 Asset Manifest Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeAssetManifestSchemaRuntime"

Types.SchemaType = {
	AssetDefinitionSchema = "AssetDefinitionSchema",
	AssetCategorySchema = "AssetCategorySchema",
	AssetPackageSchema = "AssetPackageSchema",
	AssetReferenceSchema = "AssetReferenceSchema",
	AssetVariantSchema = "AssetVariantSchema",
	AssetDependencySchema = "AssetDependencySchema",
	AssetOwnershipSchema = "AssetOwnershipSchema",
	AssetBudgetSchema = "AssetBudgetSchema",
	AssetCompatibilitySchema = "AssetCompatibilitySchema",
	AssetAuditSchema = "AssetAuditSchema",
	SystemAssetManifestSchema = "SystemAssetManifestSchema",
}

Types.Domain = {
	Core = true,
	World = true,
	Room = true,
	Building = true,
	Environment = true,
	Character = true,
	Monster = true,
	NPC = true,
	Item = true,
	Inventory = true,
	Puzzle = true,
	Interaction = true,
	Objective = true,
	Narrative = true,
	Presentation = true,
	Audio = true,
	Lighting = true,
	Camera = true,
	VFX = true,
	UI = true,
	Animation = true,
	Localization = true,
	Accessibility = true,
	Performance = true,
	Security = true,
	DeveloperTools = true,
	ContentRegistry = true,
	Chapter = true,
	System = true,
	Future = true,
}

Types.AssetKind = {
	Model = true,
	Mesh = true,
	Texture = true,
	Decal = true,
	Image = true,
	Sound = true,
	Animation = true,
	Material = true,
	Particle = true,
	VFX = true,
	Font = true,
	UIAsset = true,
	LocalizationPackage = true,
	DataAsset = true,
	ConfigurationAsset = true,
	ScriptReferenceOnly = true,
	FutureAsset = true,
}

Types.PackageKind = {
	CorePackage = true,
	WorldPackage = true,
	CharacterPackage = true,
	MonsterPackage = true,
	AudioPackage = true,
	PresentationPackage = true,
	UIPackage = true,
	LocalizationPackage = true,
	ChapterPackage = true,
	ToolingPackage = true,
	FuturePackage = true,
}

Types.ReferenceKind = {
	RobloxAssetIdReference = true,
	PathReference = true,
	ManifestReference = true,
	PackageReference = true,
	LocalizationKeyReference = true,
	SymbolicReference = true,
	FutureReference = true,
}

Types.VariantKind = {
	PlatformVariant = true,
	QualityVariant = true,
	LanguageVariant = true,
	AccessibilityVariant = true,
	PerformanceVariant = true,
	ChapterVariant = true,
	FutureVariant = true,
}

Types.BudgetKind = {
	MemoryBudget = true,
	DownloadBudget = true,
	InstanceBudget = true,
	AudioBudget = true,
	TextureBudget = true,
	AnimationBudget = true,
	UIPerformanceBudget = true,
	FutureBudget = true,
}

Types.CompatibilityKind = {
	Compatible = true,
	RequiresVariant = true,
	RequiresPackage = true,
	Deprecated = true,
	Incompatible = true,
	FutureCompatible = true,
	Unknown = true,
}

Types.DependencyKind = {
	Requires = true,
	SoftRequires = true,
	ConflictsWith = true,
	Replaces = true,
	FutureDependency = true,
}

Types.Limits = {
	MaxAssets = 900,
	MaxCategories = 500,
	MaxPackages = 600,
	MaxReferences = 1100,
	MaxVariants = 900,
	MaxDependencies = 900,
	MaxOwnershipRecords = 700,
	MaxBudgets = 700,
	MaxCompatibilityRecords = 800,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 480,
	MaxPayloadStringLength = 700,
	MaxTagsPerSchema = 32,
	MaxAssetCategories = 64,
	MaxAssetReferences = 128,
	MaxAssetVariants = 96,
	MaxAssetDependencies = 128,
	MaxPackageAssets = 220,
	MaxAuditFindings = 96,
}

return Types
