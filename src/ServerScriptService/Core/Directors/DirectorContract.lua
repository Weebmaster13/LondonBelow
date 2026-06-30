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

local function validateStringArray(values: any, fieldName: string): (boolean, string?)
	if type(values) ~= "table" or #values == 0 then
		return false, "Director description requires " .. fieldName
	end

	for index, value in ipairs(values) do
		if type(value) ~= "string" or value == "" then
			return false, fieldName .. " entry " .. tostring(index) .. " must be a non-empty string"
		end
	end

	return true, nil
end

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

	if type(description.displayName) ~= "string" or description.displayName == "" then
		return false, "Director description requires displayName"
	end

	local responsibilitiesValid, responsibilitiesErr =
		validateStringArray(description.responsibilities, "responsibilities")

	if not responsibilitiesValid then
		return false, responsibilitiesErr
	end

	local boundariesValid, boundariesErr = validateStringArray(description.doesNotOwn, "doesNotOwn")

	if not boundariesValid then
		return false, boundariesErr
	end

	if type(description.capabilities) ~= "table" or #description.capabilities == 0 then
		return false, "Director description requires capabilities"
	end

	for index, capability in ipairs(description.capabilities) do
		if type(capability) ~= "table" then
			return false, "Director capability " .. tostring(index) .. " must be a table"
		end

		if type(capability.id) ~= "string" or capability.id == "" then
			return false, "Director capability " .. tostring(index) .. " requires id"
		end

		if type(capability.description) ~= "string" or capability.description == "" then
			return false, "Director capability " .. tostring(index) .. " requires description"
		end

		local requestKindsValid, requestKindsErr =
			validateStringArray(capability.requestKinds, "capability.requestKinds")

		if not requestKindsValid then
			return false, requestKindsErr
		end
	end

	local validateOk, directorOk, directorErr = pcall(function()
		return director:validate()
	end)

	if not validateOk then
		return false, "Director self-validation threw: " .. tostring(directorOk)
	end

	if directorOk ~= true then
		return false, directorErr or "Director self-validation failed"
	end

	return true, nil
end

return DirectorContract
