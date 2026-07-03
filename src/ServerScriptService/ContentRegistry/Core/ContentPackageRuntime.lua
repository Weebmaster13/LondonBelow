--!strict
-- Content package schema boundary. Packages group ids and are not asset bundles.

local ContentPackageRuntime = {}

function ContentPackageRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerPackage(schema)
end

return ContentPackageRuntime
