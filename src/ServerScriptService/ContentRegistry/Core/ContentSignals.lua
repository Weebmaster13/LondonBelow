--!strict
-- EventBus signal names emitted by Content Registry Runtime.

local Signals = {
	ContentDefinitionRegistered = "ContentRegistry.ContentDefinitionRegistered",
	CategoryRegistered = "ContentRegistry.CategoryRegistered",
	ReferenceRegistered = "ContentRegistry.ReferenceRegistered",
	DependencyRegistered = "ContentRegistry.DependencyRegistered",
	PackageRegistered = "ContentRegistry.PackageRegistered",
	VersionRegistered = "ContentRegistry.VersionRegistered",
	TagRegistered = "ContentRegistry.TagRegistered",
	ValidationFailed = "ContentRegistry.ValidationFailed",
	SnapshotCaptured = "ContentRegistry.SnapshotCaptured",
}

return Signals
