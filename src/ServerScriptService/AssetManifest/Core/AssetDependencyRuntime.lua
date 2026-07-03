--!strict

local Coordinator = require(script.Parent.AssetManifestCoordinator)

return {
	register = Coordinator.registerAssetDependency,
}
