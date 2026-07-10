--!strict

local Types = require(script.Parent.AssetGovernanceCertificationDecisionTypes)

local Serialization = {}

local FORBIDDEN_MARKERS = {
	"load" .. "Asset",
	"preload" .. "Asset",
	"content" .. "Provider",
	"preload" .. "Async",
	"stream" .. "Asset",
	"modelSpawn",
	"assetApplication",
	"assetPlayback",
	"assetHandle",
	"loadedAssetHandle",
	"createUI",
	"vfxCreate",
	"animationLoad",
	"soundLoad",
	"work" .. "space",
	"replicated" .. "Storage",
	"server" .. "Storage",
	"remote" .. "Event",
	"remote" .. "Function",
	"fire" .. "Client",
	"fire" .. "AllClients",
	"invoke" .. "Client",
	"clientAuthority",
	"data" .. "Store",
	"data" .. "StoreMarker",
	"http" .. "Service",
	"httpMarker",
	"messaging" .. "Service",
	"messagingMarker",
	"ana" .. "lytics",
	"analyticsMarker",
	"tele" .. "metry",
	"telemetryMarker",
	"networkingMarker",
	"persistenceMarker",
	"gameplayRun",
	"presentationRun",
	"saveRun",
	"chapterContent",
	"chapterContentMarker",
	"decisionEngine",
	"decisionTree",
	"decisionGraph",
	"approvalLogic",
	"approvalHandler",
	"rejectionHandler",
	"authorizationHandler",
	"repairHandler",
	"schedulerHandler",
	"orchestrationHandler",
	"networkingHandler",
	"persistenceHandler",
	"routingHandler",
	"dispatchHandler",
	"routingTable",
	"dispatchGraph",
	"messageBus",
	"eventRouting",
	"runtimeDispatch",
	"runtimeDispatcher",
	"runtimeScheduler",
	"schedulerQueue",
	"executionQueue",
	"repairQueue",
	"approvalRouting",
	"authorizationRouting",
	"executionRouting",
	"authorityToken",
	"futureExecutionMarker",
	"liveSubsystemHandle",
	"exec" .. "ution" .. "Adapter",
	"exec" .. "ute",
	"auth" .. "orize",
	"approve",
	"reject",
	"re" .. "pair",
	"mu" .. "tate",
	"sche" .. "dule",
	"orches" .. "trate",
	"callback",
	"listener",
	"service",
	"serviceHandle",
	"runtimeHandle",
	"liveStateHandle",
	"moduleReference",
	"mutableReference",
}

local FORBIDDEN_LOOKUP: { [string]: boolean } = {}
for _, marker in ipairs(FORBIDDEN_MARKERS) do
	FORBIDDEN_LOOKUP[string.lower(marker)] = true
end

local function isForbiddenMarker(value: string): boolean
	return FORBIDDEN_LOOKUP[string.lower(value)] == true
end

local function isInstanceShaped(value: any): boolean
	return type(value) == "table" and type(value.ClassName) == "string" and value.Parent ~= nil
end

local function validateValue(
	value: any,
	depth: number,
	seen: { [any]: boolean },
	count: { value: number }
): (boolean, string?)
	local valueType = type(value)
	if valueType == "nil" or valueType == "boolean" or valueType == "number" then
		return true, nil
	end
	if valueType == "string" then
		if #value > Types.Limits.MaxStringLength then
			return false, "AssetGovernanceCertificationDecision payload string exceeds limit"
		end
		if isForbiddenMarker(value) then
			return false, "AssetGovernanceCertificationDecision payload contains forbidden marker"
		end
		return true, nil
	end
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return false, "AssetGovernanceCertificationDecision payload contains unsafe runtime value"
	end
	if valueType ~= "table" then
		return false, "AssetGovernanceCertificationDecision payload contains unsupported value"
	end
	if seen[value] then
		return false, "AssetGovernanceCertificationDecision payload contains cycle"
	end
	if isInstanceShaped(value) then
		return false, "AssetGovernanceCertificationDecision payload contains instance-shaped table"
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "AssetGovernanceCertificationDecision payload depth exceeds limit"
	end
	count.value += 1
	if count.value > Types.Limits.MaxPayloadNodes then
		return false, "AssetGovernanceCertificationDecision payload node count exceeds limit"
	end
	seen[value] = true
	for key, nested in pairs(value) do
		if
			type(key) == "string"
			and (#key > Types.Limits.MaxStringLength or isForbiddenMarker(key))
		then
			return false, "AssetGovernanceCertificationDecision payload contains unsafe key"
		end
		local ok, reason = validateValue(nested, depth + 1, seen, count)
		if not ok then
			return false, reason
		end
	end
	seen[value] = nil
	return true, nil
end

function Serialization.validateSerializable(value: any): (boolean, string?)
	return validateValue(value, 0, {}, { value = 0 })
end

function Serialization.deepCopy(value: any, seen: { [any]: any }?): any
	if type(value) ~= "table" then
		return value
	end
	local activeSeen = seen or {}
	if activeSeen[value] then
		return activeSeen[value]
	end
	local copy = {}
	activeSeen[value] = copy
	for key, nested in pairs(value) do
		copy[Serialization.deepCopy(key, activeSeen)] = Serialization.deepCopy(nested, activeSeen)
	end
	return copy
end

function Serialization.diagnosticCopy(value: any): any
	local ok = Serialization.validateSerializable(value)
	if ok then
		return Serialization.deepCopy(value)
	end
	return "<unsafe-payload>"
end

function Serialization.forbiddenMarkers(): { string }
	return Serialization.deepCopy(FORBIDDEN_MARKERS)
end

return Serialization
