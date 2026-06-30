--!strict

local DirectorContract = {}

local REQUIRED_METHODS = {
	"initialize",
	"start",
	"shutdown",
	"observe",
	"requestApproval",
	"cancelRequest",
	"getCapabilities",
	"getHealth",
	"getSnapshot",
	"getDiagnostics",
	"validate",
	"describe",
}

function DirectorContract.validate(director: any): (boolean, string?)
	if type(director) ~= "table" then
		return false, "Director must be a table"
	end

	for _, methodName in ipairs(REQUIRED_METHODS) do
		if type(director[methodName]) ~= "function" then
			return false, "Director missing method: " .. methodName
		end
	end

	local ok, description = pcall(function()
		return director:describe()
	end)

	if not ok or type(description) ~= "table" then
		return false, "Director describe failed"
	end

	if type(description.name) ~= "string" or description.name == "" then
		return false, "Director description requires name"
	end

	return true, nil
end

return DirectorContract
