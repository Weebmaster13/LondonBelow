--!strict

local Catalog = require(script.Parent.RobloxGuiInstanceCatalog)

local Security = {}

function Security.evaluate(className: string, properties: any)
	if Catalog.isForbidden(className) then
		return false, "ForbiddenClass"
	end
	if not Catalog.isSupported(className) then
		return false, "UnsupportedClass"
	end
	for propertyName in pairs(properties or {}) do
		if
			propertyName == "Parent"
			or propertyName == "Archivable"
			or string.find(propertyName, "Source")
		then
			return false, "ForbiddenProperty"
		end
	end
	return true
end

return table.freeze(Security)
