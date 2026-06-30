--!strict
--[[
	Runtime validation for standard Director contract modules.
]]

local DirectorContract = {}

local REQUIRED_METHODS = {
	"Initialize",
	"Start",
	"Shutdown",
	"Observe",
	"RequestApproval",
	"CancelRequest",
	"GetHealth",
	"GetSnapshot",
	"GetDiagnostics",
	"GetCapabilities",
	"Validate",
	"Describe",
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
		return director:Describe()
	end)

	if not ok or type(description) ~= "table" then
		return false, "Director Describe failed"
	end

	if type(description.name) ~= "string" or description.name == "" then
		return false, "Director description requires name"
	end

	return true, nil
end

return DirectorContract
