--!strict
--[[
	Standard observation definition contract.

	Owns validation rules for future observation definitions: stable ID,
	category, expected metadata, source system, security level, aggregation,
	expiration, and Director forwarding policy.

	Does not own ObservationService runtime behavior.
]]

local ObservationContract = {}

function ObservationContract.validateDefinition(definition: any): (boolean, string?)
	if type(definition) ~= "table" then
		return false, "Observation definition must be a table"
	end

	if type(definition.id) ~= "string" or not string.find(definition.id, "%.") then
		return false, "Observation definition requires stable namespaced id"
	end

	if type(definition.category) ~= "string" or definition.category == "" then
		return false, "Observation definition requires category"
	end

	if type(definition.expectedMetadata) ~= "table" then
		return false, "Observation definition requires expectedMetadata table"
	end

	if type(definition.sourceSystem) ~= "string" or definition.sourceSystem == "" then
		return false, "Observation definition requires sourceSystem"
	end

	if type(definition.securityLevel) ~= "string" or definition.securityLevel == "" then
		return false, "Observation definition requires securityLevel"
	end

	if type(definition.aggregationRule) ~= "string" or definition.aggregationRule == "" then
		return false, "Observation definition requires aggregationRule"
	end

	if type(definition.expirationRule) ~= "string" or definition.expirationRule == "" then
		return false, "Observation definition requires expirationRule"
	end

	return true, nil
end

function ObservationContract.describe()
	return {
		requiredFields = {
			"id",
			"category",
			"expectedMetadata",
			"sourceSystem",
			"securityLevel",
			"aggregationRule",
			"expirationRule",
			"directorForwarding",
		},
		rules = {
			"Clients never create trusted observations.",
			"Observation IDs are stable and namespaced.",
			"Metadata must be bounded and validated.",
			"Director forwarding must be explicit.",
		},
	}
end

return ObservationContract
