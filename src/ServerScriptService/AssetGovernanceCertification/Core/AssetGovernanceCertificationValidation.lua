--!strict

local Serialization = require(script.Parent.AssetGovernanceCertificationSerialization)
local Types = require(script.Parent.AssetGovernanceCertificationTypes)

local Validation = {}

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 150
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function validateArrayIds(values: any, limit: number, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	if type(values) ~= "table" then
		return false, label .. " must be a table"
	end
	if #values > limit then
		return false, label .. " exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	for _, value in ipairs(values) do
		if not validId(value) then
			return false, label .. " contains invalid id"
		end
		if seen[value] then
			return false, label .. " contains duplicate id"
		end
		seen[value] = true
	end
	return true, nil
end

local function validateTags(tags: any): (boolean, string?)
	return validateArrayIds(tags, Types.Limits.MaxTags, "tags")
end

local function validDocumentationFile(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= Types.Limits.MaxStringLength
		and string.match(value, "^[%w%._%-]+%.md$") ~= nil
end

local function validateIntegrationReadinessDeclaration(declaration: any): (boolean, string?)
	if declaration == nil then
		return false, "integration readiness declaration is nil"
	end
	if type(declaration) ~= "table" then
		return false, "integration readiness declaration must be a table"
	end
	local safe, reason = Validation.safePayload(declaration)
	if not safe then
		return false, reason
	end
	if not validId(declaration.readinessId) then
		return false, "integration readiness id is invalid"
	end
	if Types.IntegrationReadinessKind[declaration.readinessKind] ~= true then
		return false, "integration readiness kind is invalid"
	end
	if Types.IntegrationReadinessState[declaration.readinessState] ~= true then
		return false, "integration readiness state is invalid"
	end
	if type(declaration.required) ~= "boolean" then
		return false, "integration readiness required must be boolean"
	end
	if type(declaration.summary) ~= "string" or declaration.summary == "" then
		return false, "integration readiness summary is invalid"
	end
	if not validId(declaration.runtimeName) then
		return false, "integration readiness runtimeName is invalid"
	end
	if not validId(declaration.providerName) then
		return false, "integration readiness providerName is invalid"
	end
	if not validId(declaration.coordinatorName) then
		return false, "integration readiness coordinatorName is invalid"
	end
	if not validId(declaration.snapshotProvider) then
		return false, "integration readiness snapshotProvider is invalid"
	end
	if
		type(declaration.diagnosticsProvider) ~= "string"
		or declaration.diagnosticsProvider == ""
		or #declaration.diagnosticsProvider > Types.Limits.MaxStringLength
	then
		return false, "integration readiness diagnosticsProvider is invalid"
	end
	if declaration.diagnosticsProvider ~= declaration.coordinatorName .. ".inspect" then
		return false, "integration readiness diagnosticsProvider does not match coordinatorName"
	end
	if declaration.bootstrapAfter ~= nil and not validId(declaration.bootstrapAfter) then
		return false, "integration readiness bootstrapAfter is invalid"
	end
	if not validDocumentationFile(declaration.documentationFile) then
		return false, "integration readiness documentationFile is invalid"
	end
	local tagsOk, tagsReason = validateTags(declaration.tags)
	if not tagsOk then
		return false, tagsReason
	end
	if declaration.runtimeName == Types.CertificationRuntimeNode.runtimeName then
		if declaration.providerName ~= Types.CertificationRuntimeNode.providerName then
			return false, "integration readiness certification providerName is invalid"
		end
		if declaration.coordinatorName ~= Types.CertificationRuntimeNode.coordinatorName then
			return false, "integration readiness certification coordinatorName is invalid"
		end
		if declaration.snapshotProvider ~= Types.CertificationRuntimeNode.snapshotProvider then
			return false, "integration readiness certification snapshotProvider is invalid"
		end
		if declaration.bootstrapAfter ~= Types.CertificationRuntimeNode.bootstrapAfter then
			return false, "integration readiness certification bootstrapAfter is invalid"
		end
	else
		local runtimeOrder = Types.RuntimeName[declaration.runtimeName]
		if runtimeOrder == nil then
			return false, "integration readiness runtimeName is unsupported"
		end
		if Types.ProviderName[declaration.providerName] ~= runtimeOrder then
			return false, "integration readiness providerName does not match runtimeName"
		end
		if Types.CoordinatorName[declaration.coordinatorName] ~= runtimeOrder then
			return false, "integration readiness coordinatorName does not match runtimeName"
		end
		if declaration.snapshotProvider ~= declaration.providerName then
			return false, "integration readiness snapshotProvider does not match providerName"
		end
		if runtimeOrder == 1 then
			if declaration.bootstrapAfter ~= nil then
				return false, "integration readiness first runtime cannot declare bootstrapAfter"
			end
		elseif declaration.bootstrapAfter ~= Types.BootstrapDependencyOrder[runtimeOrder - 1] then
			return false, "integration readiness bootstrapAfter is out of order"
		end
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	return Serialization.validateSerializable(payload)
end

local function validateSchema(
	schema: any,
	idField: string,
	expectedType: string,
	label: string
): (boolean, string?)
	if schema == nil then
		return false, label .. " schema is nil"
	end
	if type(schema) ~= "table" then
		return false, label .. " schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema[idField]) then
		return false, label .. " id is invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= expectedType then
		return false, "unsupported " .. label .. " schema type"
	end
	return validateTags(schema.tags)
end

function Validation.certification(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"certificationId",
		Types.SchemaType.GovernanceCertification,
		"certification"
	)
	if not ok then
		return false, reason
	end
	if Types.CertificationKind[schema.certificationKind] ~= true then
		return false, "certification kind is invalid"
	end
	if Types.CertificationStatus[schema.certificationStatus] ~= true then
		return false, "certification status is invalid"
	end
	if not validId(schema.chainId) then
		return false, "certification chainId is invalid"
	end
	if not validId(schema.reviewer) then
		return false, "certification reviewer is invalid"
	end
	if type(schema.certificationVersion) ~= "string" or schema.certificationVersion == "" then
		return false, "certification version is invalid"
	end
	for _, group in ipairs({
		{ schema.requirementIds, "requirementIds" },
		{ schema.resultIds, "resultIds" },
		{ schema.auditIds, "auditIds" },
	}) do
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxCertificationChildren, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.requirement(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"requirementId",
		Types.SchemaType.GovernanceCertificationRequirement,
		"requirement"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.certificationId) then
		return false, "requirement certificationId is invalid"
	end
	if Types.RequirementKind[schema.requirementKind] ~= true then
		return false, "requirement kind is invalid"
	end
	if type(schema.required) ~= "boolean" then
		return false, "requirement required must be boolean"
	end
	if Types.RequirementStatus[schema.status] ~= true then
		return false, "requirement status is invalid"
	end
	if type(schema.summary) ~= "string" or schema.summary == "" then
		return false, "requirement summary is invalid"
	end
	return true, nil
end

function Validation.result(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "resultId", Types.SchemaType.GovernanceCertificationResult, "result")
	if not ok then
		return false, reason
	end
	if not validId(schema.certificationId) then
		return false, "result certificationId is invalid"
	end
	if Types.ResultKind[schema.resultKind] ~= true then
		return false, "result kind is invalid"
	end
	if Types.ResultStatus[schema.resultStatus] ~= true then
		return false, "result status is invalid"
	end
	if type(schema.message) ~= "string" or schema.message == "" then
		return false, "result message is invalid"
	end
	return validateArrayIds(schema.evidence, Types.Limits.MaxResultEvidence, "evidence")
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.GovernanceCertificationAudit, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.certificationId) then
		return false, "audit certificationId is invalid"
	end
	if Types.AuditKind[schema.auditKind] ~= true then
		return false, "audit kind is invalid"
	end
	if not validId(schema.reviewer) then
		return false, "audit reviewer is invalid"
	end
	if Types.AuditStatus[schema.status] ~= true then
		return false, "audit status is invalid"
	end
	return validateArrayIds(schema.findings, Types.Limits.MaxAuditFindings, "findings")
end

function Validation.integrationReadinessDeclaration(declaration: any): (boolean, string?)
	return validateIntegrationReadinessDeclaration(declaration)
end

function Validation.integrationReadinessDeclarations(declarations: any): (boolean, string?)
	if declarations == nil then
		return false, "integration readiness declarations are nil"
	end
	if type(declarations) ~= "table" then
		return false, "integration readiness declarations must be a table"
	end
	local seenReadinessIds: { [string]: boolean } = {}
	local seenRuntimeNames: { [string]: boolean } = {}
	local seenProviderNames: { [string]: boolean } = {}
	for _, declaration in ipairs(declarations) do
		local ok, reason = validateIntegrationReadinessDeclaration(declaration)
		if not ok then
			return false, reason
		end
		if seenReadinessIds[declaration.readinessId] then
			return false, "duplicate integration readiness id"
		end
		if seenRuntimeNames[declaration.runtimeName] then
			return false, "duplicate integration readiness runtimeName"
		end
		if seenProviderNames[declaration.providerName] then
			return false, "duplicate integration readiness providerName"
		end
		seenReadinessIds[declaration.readinessId] = true
		seenRuntimeNames[declaration.runtimeName] = true
		seenProviderNames[declaration.providerName] = true
	end
	if #declarations ~= #Types.CertifiedRuntimeOrder + 1 then
		return false, "integration readiness declaration count is invalid"
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	return Validation.integrationReadinessDeclarations(Types.IntegrationReadinessDeclarations)
end

return Validation
