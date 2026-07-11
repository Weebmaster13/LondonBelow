--!strict

local Serialization = require(script.Parent.AssetExecutionAuthorizationSerialization)
local Types = require(script.Parent.AssetExecutionAuthorizationTypes)

local Validation = {}

local fieldLookup: { [string]: { [string]: boolean } } = {}
for schemaName, fields in pairs(Types.SchemaFields) do
	local lookup = {}
	for _, field in ipairs(fields) do
		lookup[field] = true
	end
	fieldLookup[schemaName] = lookup
end

local integrationFieldLookup: { [string]: boolean } = {}
for _, field in ipairs(Types.IntegrationReadinessDeclarationFields) do
	integrationFieldLookup[field] = true
end

local executionReadinessFieldLookup: { [string]: boolean } = {}
for _, field in ipairs(Types.ExecutionReadinessDeclarationFields) do
	executionReadinessFieldLookup[field] = true
end

local function orderNameForField(fieldName: string): string
	return string.upper(string.sub(fieldName, 1, 1)) .. string.sub(fieldName, 2) .. "Order"
end

local integrationOrderNameByField = {
	integrationId = "IntegrationIdOrder",
	compatibilityId = "CompatibilityIdOrder",
	integrationDeclarationId = "IntegrationDeclarationIdOrder",
	integrationKind = "IntegrationKindOrder",
	integrationStatus = "IntegrationStatusOrder",
	runtimeName = "RuntimeNameOrder",
	providerName = "ProviderNameOrder",
	snapshotProviderName = "SnapshotProviderNameOrder",
	coordinatorName = "CoordinatorNameOrder",
	diagnosticsProviderName = "DiagnosticsProviderNameOrder",
	bootstrapDependencyName = "BootstrapDependencyNameOrder",
	engineGovernanceSnapshotProviderName = "EngineGovernanceSnapshotProviderNameOrder",
	documentationReference = "DocumentationReferenceOrder",
	governanceRuntimeName = "GovernanceRuntimeNameOrder",
	governanceProviderName = "GovernanceProviderNameOrder",
	governanceSnapshotProviderName = "GovernanceSnapshotProviderNameOrder",
	authorizationReadinessEvidenceKind = "AuthorizationReadinessEvidenceKindOrder",
	authorizationRuntimeName = "AuthorizationRuntimeNameOrder",
	authorizationProviderName = "AuthorizationProviderNameOrder",
	authorizationSnapshotProviderName = "AuthorizationSnapshotProviderNameOrder",
	executionBoundaryKind = "ExecutionBoundaryKindOrder",
	required = "RequiredOrder",
}

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
	local count = 0
	for key in pairs(values) do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false, label .. " must be an ordered array"
		end
		count += 1
	end
	if count ~= #values then
		return false, label .. " must not be sparse"
	end
	if count > limit then
		return false, label .. " exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	local previous = ""
	for _, value in ipairs(values) do
		if not validId(value) then
			return false, label .. " contains invalid id"
		end
		if seen[value] then
			return false, label .. " contains duplicate id"
		end
		if previous ~= "" and value < previous then
			return false, label .. " must be deterministic ascending order"
		end
		previous = value
		seen[value] = true
	end
	return true, nil
end

local function validateMetadata(metadata: any, label: string): (boolean, string?)
	if type(metadata) ~= "table" then
		return false, label .. " metadata is required"
	end
	for key in pairs(metadata) do
		if type(key) ~= "string" or not validId(key) then
			return false, label .. " metadata key is invalid"
		end
	end
	return true, nil
end

local function validateExactArray(
	values: { string },
	expected: { string },
	label: string
): (boolean, string?)
	if #values ~= #expected then
		return false, label .. " count drift"
	end
	for index, value in ipairs(values) do
		if value ~= expected[index] then
			return false, label .. " ordering drift"
		end
	end
	return true, nil
end

local function validateExactValue(actual: any, expected: any, label: string): (boolean, string?)
	if type(expected) == "table" then
		if type(actual) ~= "table" then
			return false, label .. " must be a table"
		end
		local count = 0
		for key in pairs(actual) do
			count += 1
			if expected[key] == nil then
				return false, label .. " contains unsupported field"
			end
		end
		local expectedCount = 0
		for key, expectedValue in pairs(expected) do
			expectedCount += 1
			local ok, reason =
				validateExactValue(actual[key], expectedValue, label .. "." .. tostring(key))
			if not ok then
				return false, reason
			end
		end
		if count ~= expectedCount then
			return false, label .. " field count drift"
		end
		return true, nil
	end
	if actual ~= expected then
		return false, label .. " value drift"
	end
	return true, nil
end

local function validateEvidence(values: any): (boolean, string?)
	if values == nil then
		return false, "evidence is required"
	end
	return validateArrayIds(values, Types.Limits.MaxEvidence, "evidence")
end

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return false, "tags are required"
	end
	return validateArrayIds(tags, Types.Limits.MaxTags, "tags")
end

local function validateIntegrationFieldSet(declaration: any): (boolean, string?, number?)
	if type(declaration) ~= "table" then
		return false, "integration declaration must be a table", nil
	end
	local fieldCount = 0
	for key in pairs(declaration) do
		fieldCount += 1
		if type(key) ~= "string" or integrationFieldLookup[key] ~= true then
			return false, "integration declaration contains unsupported field", nil
		end
	end
	if fieldCount ~= #Types.IntegrationReadinessDeclarationFields then
		return false, "integration declaration field count drift", nil
	end
	return true, nil, fieldCount
end

local function validateIntegrationOrder(declaration: any, index: number): (boolean, string?)
	for _, fieldName in ipairs(Types.IntegrationReadinessDeclarationFields) do
		local orderName = integrationOrderNameByField[fieldName]
		if orderName ~= nil then
			if type(Types.IntegrationReadinessDeclarationOrder) ~= "table" then
				return false, "integration declaration order table is missing"
			end
			local expectedOrder = Types.IntegrationReadinessDeclarationOrder[orderName]
			if type(expectedOrder) ~= "table" then
				return false, fieldName .. " order array is missing"
			end
			if #expectedOrder ~= #Types.AuthorizationIntegrationReadinessDeclarations then
				return false, fieldName .. " order array count drift"
			end
			if expectedOrder[index] ~= declaration[fieldName] then
				return false, fieldName .. " order drift at declaration " .. index
			end
		end
	end
	return true, nil
end

local function validateIntegrationDeclaration(
	declaration: any,
	expected: any,
	index: number
): (boolean, string?)
	local fieldSetOk, fieldSetReason = validateIntegrationFieldSet(declaration)
	if not fieldSetOk then
		return false, fieldSetReason
	end
	local orderOk, orderReason = validateIntegrationOrder(declaration, index)
	if not orderOk then
		return false, orderReason
	end
	local safe, safeReason = Serialization.validateSerializable(declaration)
	if not safe then
		return false, safeReason
	end
	for _, idField in ipairs({
		"integrationId",
		"compatibilityId",
		"integrationDeclarationId",
	}) do
		if not validId(declaration[idField]) then
			return false, idField .. " is invalid"
		end
	end
	if Types.IntegrationKind[declaration.integrationKind] ~= true then
		return false, "integrationKind is invalid"
	end
	if Types.IntegrationStatus[declaration.integrationStatus] ~= true then
		return false, "integrationStatus is invalid"
	end
	if Types.ExecutionBoundaryKind[declaration.executionBoundaryKind] ~= true then
		return false, "executionBoundaryKind is invalid"
	end
	for _, nameField in ipairs({
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"coordinatorName",
		"diagnosticsProviderName",
		"bootstrapDependencyName",
		"engineGovernanceSnapshotProviderName",
		"documentationReference",
		"governanceRuntimeName",
		"governanceProviderName",
		"governanceSnapshotProviderName",
		"authorizationReadinessEvidenceKind",
		"authorizationRuntimeName",
		"authorizationProviderName",
		"authorizationSnapshotProviderName",
	}) do
		if not validId(declaration[nameField]) then
			return false, nameField .. " is invalid"
		end
	end
	if declaration.runtimeName ~= Types.RuntimeName then
		return false, "integration runtimeName drift"
	end
	if declaration.providerName ~= Types.RuntimeProviderName then
		return false, "integration providerName drift"
	end
	if declaration.snapshotProviderName ~= Types.RuntimeProviderName then
		return false, "integration snapshotProviderName drift"
	end
	if declaration.coordinatorName ~= Types.CoordinatorName then
		return false, "integration coordinatorName drift"
	end
	if declaration.diagnosticsProviderName ~= Types.RuntimeProviderName then
		return false, "integration diagnosticsProviderName drift"
	end
	if declaration.bootstrapDependencyName ~= Types.BootstrapDependencyOrder[1] then
		return false, "integration Bootstrap dependency drift"
	end
	if declaration.engineGovernanceSnapshotProviderName ~= Types.RuntimeProviderName then
		return false, "integration Engine Governance provider drift"
	end
	if declaration.governanceRuntimeName ~= "AssetExecutionGovernance" then
		return false, "integration governanceRuntimeName drift"
	end
	if declaration.governanceProviderName ~= "assetExecutionGovernanceRuntime" then
		return false, "integration governanceProviderName drift"
	end
	if declaration.governanceSnapshotProviderName ~= "assetExecutionGovernanceRuntime" then
		return false, "integration governanceSnapshotProviderName drift"
	end
	if declaration.authorizationRuntimeName ~= Types.RuntimeName then
		return false, "integration authorizationRuntimeName drift"
	end
	if declaration.authorizationProviderName ~= Types.RuntimeProviderName then
		return false, "integration authorizationProviderName drift"
	end
	if declaration.authorizationSnapshotProviderName ~= Types.RuntimeProviderName then
		return false, "integration authorizationSnapshotProviderName drift"
	end
	if type(declaration.required) ~= "boolean" or not declaration.required then
		return false, "integration required flag drift"
	end
	local evidenceOk, evidenceReason = validateEvidence(declaration.evidence)
	if not evidenceOk then
		return false, evidenceReason
	end
	local tagsOk, tagsReason = validateTags(declaration.tags)
	if not tagsOk then
		return false, tagsReason
	end
	local metadataOk, metadataReason =
		validateMetadata(declaration.metadata, "integration declaration")
	if not metadataOk then
		return false, metadataReason
	end
	local exactOk, exactReason =
		validateExactValue(declaration, expected, "integration declaration " .. index)
	if not exactOk then
		return false, exactReason
	end
	return true, nil
end

local function validateIntegrationDeclarations(declarations: any): (boolean, string?)
	if declarations == nil then
		return false, "integration declarations are nil"
	end
	if type(declarations) ~= "table" then
		return false, "integration declarations must be a table"
	end
	local count = 0
	for key in pairs(declarations) do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false, "integration declarations must be an ordered array"
		end
		count += 1
	end
	if count ~= #declarations then
		return false, "integration declarations must not be sparse"
	end
	if count ~= #Types.AuthorizationIntegrationReadinessDeclarations then
		return false, "integration declaration count drift"
	end
	local seenIntegrationIds: { [string]: boolean } = {}
	local seenCompatibilityIds: { [string]: boolean } = {}
	local seenDeclarationIds: { [string]: boolean } = {}
	for index, expected in ipairs(Types.AuthorizationIntegrationReadinessDeclarations) do
		local declaration = declarations[index]
		local ok, reason = validateIntegrationDeclaration(declaration, expected, index)
		if not ok then
			return false, reason
		end
		if seenIntegrationIds[declaration.integrationId] then
			return false, "duplicate integrationId"
		end
		if seenCompatibilityIds[declaration.compatibilityId] then
			return false, "duplicate compatibilityId"
		end
		if seenDeclarationIds[declaration.integrationDeclarationId] then
			return false, "duplicate integrationDeclarationId"
		end
		seenIntegrationIds[declaration.integrationId] = true
		seenCompatibilityIds[declaration.compatibilityId] = true
		seenDeclarationIds[declaration.integrationDeclarationId] = true
	end
	return true, nil
end

local function validateExecutionReadinessFieldSet(declaration: any): (boolean, string?, number?)
	if type(declaration) ~= "table" then
		return false, "execution readiness declaration must be a table", nil
	end
	local fieldCount = 0
	for key in pairs(declaration) do
		fieldCount += 1
		if type(key) ~= "string" or executionReadinessFieldLookup[key] ~= true then
			return false, "execution readiness declaration contains unsupported field", nil
		end
	end
	if fieldCount ~= #Types.ExecutionReadinessDeclarationFields then
		return false, "execution readiness declaration field count drift", nil
	end
	return true, nil, fieldCount
end

local function validateExecutionReadinessOrderTable(): (boolean, string?)
	if type(Types.ExecutionReadinessDeclarationOrder) ~= "table" then
		return false, "execution readiness declaration order table is missing"
	end
	local expectedNames: { [string]: boolean } = {}
	local expectedCount = 0
	for _, fieldName in ipairs(Types.ExecutionReadinessDeclarationFields) do
		if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
			expectedNames[orderNameForField(fieldName)] = true
			expectedCount += 1
		end
	end
	local actualCount = 0
	for orderName, orderValues in pairs(Types.ExecutionReadinessDeclarationOrder) do
		actualCount += 1
		if type(orderName) ~= "string" or expectedNames[orderName] ~= true then
			return false, "execution readiness declaration order table contains unsupported field"
		end
		if type(orderValues) ~= "table" then
			return false, orderName .. " execution readiness order array must be a table"
		end
		local arrayCount = 0
		for key in pairs(orderValues) do
			if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
				return false, orderName .. " execution readiness order array must be ordered"
			end
			arrayCount += 1
		end
		if arrayCount ~= #orderValues then
			return false, orderName .. " execution readiness order array must not be sparse"
		end
		if arrayCount ~= #Types.AssetExecutionReadinessDeclarations then
			return false, orderName .. " execution readiness order array count drift"
		end
	end
	if actualCount ~= expectedCount then
		return false, "execution readiness declaration order table count drift"
	end
	return true, nil
end

local function validateExecutionReadinessOrder(declaration: any, index: number): (boolean, string?)
	for _, fieldName in ipairs(Types.ExecutionReadinessDeclarationFields) do
		if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
			local orderName = orderNameForField(fieldName)
			local expectedOrder = Types.ExecutionReadinessDeclarationOrder[orderName]
			if expectedOrder[index] ~= declaration[fieldName] then
				return false,
					fieldName .. " execution readiness order drift at declaration " .. index
			end
		end
	end
	return true, nil
end

local function validateExecutionReadinessDeclaration(
	declaration: any,
	expected: any,
	index: number
): (boolean, string?)
	local fieldSetOk, fieldSetReason = validateExecutionReadinessFieldSet(declaration)
	if not fieldSetOk then
		return false, fieldSetReason
	end
	local orderOk, orderReason = validateExecutionReadinessOrder(declaration, index)
	if not orderOk then
		return false, orderReason
	end
	local safe, safeReason = Serialization.validateSerializable(declaration)
	if not safe then
		return false, safeReason
	end
	for _, idField in ipairs({
		"readinessId",
		"compatibilityId",
		"readinessDeclarationId",
	}) do
		if not validId(declaration[idField]) then
			return false, idField .. " is invalid"
		end
	end
	if Types.ExecutionReadinessKind[declaration.readinessKind] ~= true then
		return false, "readinessKind is invalid"
	end
	if Types.ExecutionReadinessStatus[declaration.readinessStatus] ~= true then
		return false, "readinessStatus is invalid"
	end
	if Types.ExecutionBoundaryKind[declaration.executionBoundaryKind] ~= true then
		return false, "executionBoundaryKind is invalid"
	end
	for _, nameField in ipairs({
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"coordinatorName",
		"diagnosticsProviderName",
		"bootstrapDependencyName",
		"engineGovernanceSnapshotProviderName",
		"documentationReference",
		"governanceRuntimeName",
		"governanceProviderName",
		"governanceSnapshotProviderName",
		"authorizationRuntimeName",
		"authorizationProviderName",
		"authorizationSnapshotProviderName",
		"authorizationCoordinatorName",
		"authorizationIntegrationEvidenceKind",
		"futureExecutionRuntimeName",
		"futureExecutionProviderName",
		"futureExecutionSnapshotProviderName",
		"futureExecutionCoordinatorName",
	}) do
		if not validId(declaration[nameField]) then
			return false, nameField .. " is invalid"
		end
	end
	if declaration.runtimeName ~= Types.RuntimeName then
		return false, "execution readiness runtimeName drift"
	end
	if declaration.providerName ~= Types.RuntimeProviderName then
		return false, "execution readiness providerName drift"
	end
	if declaration.snapshotProviderName ~= Types.RuntimeProviderName then
		return false, "execution readiness snapshotProviderName drift"
	end
	if declaration.coordinatorName ~= Types.CoordinatorName then
		return false, "execution readiness coordinatorName drift"
	end
	if declaration.diagnosticsProviderName ~= Types.RuntimeProviderName then
		return false, "execution readiness diagnosticsProviderName drift"
	end
	if declaration.bootstrapDependencyName ~= Types.BootstrapDependencyOrder[1] then
		return false, "execution readiness Bootstrap dependency drift"
	end
	if declaration.engineGovernanceSnapshotProviderName ~= Types.RuntimeProviderName then
		return false, "execution readiness Engine Governance provider drift"
	end
	if declaration.governanceRuntimeName ~= "AssetExecutionGovernance" then
		return false, "execution readiness governanceRuntimeName drift"
	end
	if declaration.governanceProviderName ~= "assetExecutionGovernanceRuntime" then
		return false, "execution readiness governanceProviderName drift"
	end
	if declaration.governanceSnapshotProviderName ~= "assetExecutionGovernanceRuntime" then
		return false, "execution readiness governanceSnapshotProviderName drift"
	end
	if declaration.authorizationRuntimeName ~= Types.RuntimeName then
		return false, "execution readiness authorizationRuntimeName drift"
	end
	if declaration.authorizationProviderName ~= Types.RuntimeProviderName then
		return false, "execution readiness authorizationProviderName drift"
	end
	if declaration.authorizationSnapshotProviderName ~= Types.RuntimeProviderName then
		return false, "execution readiness authorizationSnapshotProviderName drift"
	end
	if declaration.authorizationCoordinatorName ~= Types.CoordinatorName then
		return false, "execution readiness authorizationCoordinatorName drift"
	end
	if declaration.futureExecutionRuntimeName ~= "AssetExecutionRuntime" then
		return false, "execution readiness future runtime separation drift"
	end
	if declaration.futureExecutionProviderName ~= "assetExecutionRuntime" then
		return false, "execution readiness future provider separation drift"
	end
	if declaration.futureExecutionSnapshotProviderName ~= "assetExecutionRuntime" then
		return false, "execution readiness future snapshot separation drift"
	end
	if declaration.futureExecutionCoordinatorName ~= "AssetExecutionCoordinator" then
		return false, "execution readiness future coordinator separation drift"
	end
	if type(declaration.required) ~= "boolean" or not declaration.required then
		return false, "execution readiness required flag drift"
	end
	local evidenceOk, evidenceReason = validateEvidence(declaration.evidence)
	if not evidenceOk then
		return false, evidenceReason
	end
	local tagsOk, tagsReason = validateTags(declaration.tags)
	if not tagsOk then
		return false, tagsReason
	end
	local metadataOk, metadataReason =
		validateMetadata(declaration.metadata, "execution readiness declaration")
	if not metadataOk then
		return false, metadataReason
	end
	local exactOk, exactReason =
		validateExactValue(declaration, expected, "execution readiness declaration " .. index)
	if not exactOk then
		return false, exactReason
	end
	return true, nil
end

local function validateExecutionReadinessDeclarations(declarations: any): (boolean, string?)
	if declarations == nil then
		return false, "execution readiness declarations are nil"
	end
	local orderTableOk, orderTableReason = validateExecutionReadinessOrderTable()
	if not orderTableOk then
		return false, orderTableReason
	end
	if type(declarations) ~= "table" then
		return false, "execution readiness declarations must be a table"
	end
	local count = 0
	for key in pairs(declarations) do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false, "execution readiness declarations must be an ordered array"
		end
		count += 1
	end
	if count ~= #declarations then
		return false, "execution readiness declarations must not be sparse"
	end
	if count ~= #Types.AssetExecutionReadinessDeclarations then
		return false, "execution readiness declaration count drift"
	end
	local seenReadinessIds: { [string]: boolean } = {}
	local seenCompatibilityIds: { [string]: boolean } = {}
	local seenDeclarationIds: { [string]: boolean } = {}
	for index, expected in ipairs(Types.AssetExecutionReadinessDeclarations) do
		local declaration = declarations[index]
		local ok, reason = validateExecutionReadinessDeclaration(declaration, expected, index)
		if not ok then
			return false, reason
		end
		if seenReadinessIds[declaration.readinessId] then
			return false, "duplicate readinessId"
		end
		if seenCompatibilityIds[declaration.compatibilityId] then
			return false, "duplicate compatibilityId"
		end
		if seenDeclarationIds[declaration.readinessDeclarationId] then
			return false, "duplicate readinessDeclarationId"
		end
		seenReadinessIds[declaration.readinessId] = true
		seenCompatibilityIds[declaration.compatibilityId] = true
		seenDeclarationIds[declaration.readinessDeclarationId] = true
	end
	return true, nil
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
	local safe, safeReason = Serialization.validateSerializable(schema)
	if not safe then
		return false, safeReason
	end
	local fieldCount = 0
	for key in pairs(schema) do
		fieldCount += 1
		if type(key) ~= "string" or fieldLookup[expectedType][key] ~= true then
			return false, label .. " contains unsupported field"
		end
	end
	if fieldCount ~= Types.SchemaFieldCount[expectedType] then
		return false, label .. " field count is invalid"
	end
	if not validId(schema[idField]) then
		return false, label .. " id is invalid"
	end
	local tagsOk, tagsReason = validateTags(schema.tags)
	if not tagsOk then
		return false, tagsReason
	end
	return validateMetadata(schema.metadata, label)
end

local function validateRuntimeIdentity(schema: any): (boolean, string?)
	if schema.runtimeName ~= Types.RuntimeName then
		return false, "runtimeName is unsupported"
	end
	if schema.providerName ~= Types.RuntimeProviderName then
		return false, "providerName is unsupported"
	end
	if schema.snapshotProviderName ~= Types.RuntimeProviderName then
		return false, "snapshotProviderName is unsupported"
	end
	return true, nil
end

function Validation.authorization(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"authorizationId",
		Types.SchemaType.ExecutionAuthorization,
		"authorization"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.governanceId) or not validId(schema.readinessId) then
		return false, "authorization upstream ids are invalid"
	end
	local runtimeOk, runtimeReason = validateRuntimeIdentity(schema)
	if not runtimeOk then
		return false, runtimeReason
	end
	if Types.AuthorizationKind[schema.authorizationKind] ~= true then
		return false, "authorizationKind is invalid"
	end
	if Types.AuthorizationStatus[schema.authorizationStatus] ~= true then
		return false, "authorizationStatus is invalid"
	end
	for _, group in ipairs({
		{ schema.requirementIds, "requirementIds" },
		{ schema.evaluationIds, "evaluationIds" },
		{ schema.boundaryIds, "boundaryIds" },
		{ schema.auditIds, "auditIds" },
	}) do
		if group[1] == nil then
			return false, group[2] .. " are required"
		end
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxChildReferences, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return validateEvidence(schema.evidence)
end

function Validation.requirement(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"requirementId",
		Types.SchemaType.ExecutionAuthorizationRequirement,
		"requirement"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.authorizationId) then
		return false, "requirement authorizationId is invalid"
	end
	if Types.RequirementKind[schema.requirementKind] ~= true then
		return false, "requirementKind is invalid"
	end
	if Types.RequirementStatus[schema.requirementStatus] ~= true then
		return false, "requirementStatus is invalid"
	end
	if type(schema.required) ~= "boolean" then
		return false, "required must be boolean"
	end
	return validateEvidence(schema.evidence)
end

function Validation.evaluation(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"evaluationId",
		Types.SchemaType.ExecutionAuthorizationEvaluation,
		"evaluation"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.authorizationId) or not validId(schema.requirementId) then
		return false, "evaluation references are invalid"
	end
	if Types.EvaluationKind[schema.evaluationKind] ~= true then
		return false, "evaluationKind is invalid"
	end
	if Types.EvaluationStatus[schema.evaluationStatus] ~= true then
		return false, "evaluationStatus is invalid"
	end
	if not validId(schema.evaluator) then
		return false, "evaluation evaluator is invalid"
	end
	return validateEvidence(schema.evidence)
end

function Validation.boundary(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"boundaryId",
		Types.SchemaType.ExecutionAuthorizationBoundary,
		"boundary"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.authorizationId) then
		return false, "boundary authorizationId is invalid"
	end
	if Types.BoundaryKind[schema.boundaryKind] ~= true then
		return false, "boundaryKind is invalid"
	end
	if Types.BoundaryStatus[schema.boundaryStatus] ~= true then
		return false, "boundaryStatus is invalid"
	end
	if
		type(schema.summary) ~= "string"
		or schema.summary == ""
		or #schema.summary > Types.Limits.MaxSummaryLength
	then
		return false, "boundary summary is invalid"
	end
	return validateEvidence(schema.evidence)
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.ExecutionAuthorizationAudit, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.authorizationId) then
		return false, "audit authorizationId is invalid"
	end
	if Types.AuditKind[schema.auditKind] ~= true then
		return false, "auditKind is invalid"
	end
	if Types.AuditStatus[schema.auditStatus] ~= true then
		return false, "auditStatus is invalid"
	end
	if not validId(schema.reviewer) then
		return false, "audit reviewer is invalid"
	end
	for _, group in ipairs({
		{ schema.evaluationIds, "evaluationIds" },
		{ schema.boundaryIds, "boundaryIds" },
	}) do
		if group[1] == nil then
			return false, group[2] .. " are required"
		end
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxChildReferences, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return validateEvidence(schema.evidence)
end

function Validation.validate(): (boolean, string?)
	if Types.RuntimeProviderName ~= "assetExecutionAuthorizationRuntime" then
		return false, "provider name drift"
	end
	if Types.SnapshotKind ~= "assetExecutionAuthorizationRuntimeSnapshot" then
		return false, "snapshot kind drift"
	end
	if Types.RuntimeName ~= "AssetExecutionAuthorization" then
		return false, "runtime name drift"
	end
	if Types.CoordinatorName ~= "AssetExecutionAuthorizationCoordinator" then
		return false, "coordinator name drift"
	end
	local docsOk, docsReason = validateExactArray(Types.DocumentationFiles, {
		"ASSET_EXECUTION_AUTHORIZATION_RUNTIME.md",
		"ASSET_EXECUTION_AUTHORIZATION_VALIDATION.md",
		"ASSET_EXECUTION_AUTHORIZATION_SERIALIZATION.md",
		"ASSET_EXECUTION_AUTHORIZATION_DIAGNOSTICS.md",
		"ASSET_EXECUTION_AUTHORIZATION_SELF_CHECKS.md",
		"ASSET_EXECUTION_AUTHORIZATION_RUNTIME_LIMITS.md",
		"ASSET_EXECUTION_AUTHORIZATION_PRODUCTION_REVIEW.md",
		"ASSET_EXECUTION_AUTHORIZATION_AUDIT.md",
		"ASSET_EXECUTION_AUTHORIZATION_INTEGRATION_READINESS.md",
		"ASSET_EXECUTION_AUTHORIZATION_EXECUTION_READINESS.md",
		"AUTHORIZATION_RUNTIME.md",
		"AUTHORIZATION_REQUIREMENT_RUNTIME.md",
		"AUTHORIZATION_EVALUATION_RUNTIME.md",
		"AUTHORIZATION_BOUNDARY_RUNTIME.md",
		"AUTHORIZATION_AUDIT_RUNTIME.md",
	}, "documentation")
	if not docsOk then
		return false, docsReason
	end
	local bootstrapOk, bootstrapReason = validateExactArray(
		Types.BootstrapDependencyOrder,
		{ "AssetExecutionGovernanceCoordinator" },
		"Bootstrap dependency"
	)
	if not bootstrapOk then
		return false, bootstrapReason
	end
	local governanceOk, governanceReason = validateExactArray(
		Types.GovernanceSnapshotProviders,
		{ Types.RuntimeProviderName },
		"Governance snapshot provider"
	)
	if not governanceOk then
		return false, governanceReason
	end
	local integrationOk, integrationReason =
		validateIntegrationDeclarations(Types.AuthorizationIntegrationReadinessDeclarations)
	if not integrationOk then
		return false, integrationReason
	end
	local executionReadinessOk, executionReadinessReason =
		validateExecutionReadinessDeclarations(Types.AssetExecutionReadinessDeclarations)
	if not executionReadinessOk then
		return false, executionReadinessReason
	end
	return true, nil
end

Validation.validId = validId
Validation.integrationDeclarations = validateIntegrationDeclarations
Validation.executionReadinessDeclarations = validateExecutionReadinessDeclarations

return Validation
