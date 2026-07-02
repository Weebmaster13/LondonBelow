--!strict
-- Translation package schema boundary. Packages are schema bundles, not translation files.

local LocalizationPackageRuntime = {}

function LocalizationPackageRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerPackage(schema)
end

return LocalizationPackageRuntime
