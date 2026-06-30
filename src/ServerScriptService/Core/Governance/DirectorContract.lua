--!strict
--[[
	Standard Director contract shape for London Engine.

	Owns the expected public interface for future Director systems.

	Does not implement any Director. It defines how Directors should expose
	lifecycle, observations, approvals, diagnostics, snapshots, and validation.
]]

local DirectorContract = {}

DirectorContract.RequiredMethods = {
	"initialize",
	"start",
	"shutdown",
	"observe",
	"requestApproval",
	"getSnapshot",
	"getDiagnostics",
	"validate",
}

function DirectorContract.describe()
	return {
		purpose = "Director systems interpret Observation Engine truth and publish server-owned approvals.",
		requiredMethods = table.clone(DirectorContract.RequiredMethods),
		rules = {
			"Directors do not execute physical gameplay actions directly.",
			"Directors publish approvals, denials, and diagnostic state.",
			"Directors consume Observation Engine facts rather than client-owned truth.",
			"Directors must fail safely and preserve server authority.",
		},
	}
end

function DirectorContract.validateInterface(systemName: string, module: any): (boolean, string?)
	if type(module) ~= "table" then
		return false, systemName .. " Director module must return a table"
	end

	for _, methodName in ipairs(DirectorContract.RequiredMethods) do
		if type(module[methodName]) ~= "function" then
			return false, systemName .. " missing Director method: " .. methodName
		end
	end

	return true, nil
end

return DirectorContract
