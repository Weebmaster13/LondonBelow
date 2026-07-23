--!strict

local Evidence = require(script.Parent.RenderingRuntimeEvidence)
local Metrics = require(script.Parent.RenderingRuntimeMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local renderers = {}
local order = {}
local nextOrdinal = 0

local function validString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

local function validKinds(values: any): boolean
	if type(values) ~= "table" or #values == 0 then
		return false
	end
	for _, value in ipairs(values) do
		if type(value) ~= "string" or not Types.isRenderingKind(value) then
			return false
		end
	end
	return true
end

function Registry.register(renderer: any)
	if #order >= Types.RenderingRuntimeLimits.MaxRenderers then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.LimitExceeded,
			message = "renderer limit exceeded",
		}
	end
	if type(renderer) ~= "table" then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.ValidationFailure,
			message = "renderer must be a table",
		}
	end
	for _, field in ipairs({ "rendererId", "providerName", "version", "status" }) do
		if not validString(renderer[field]) then
			return {
				ok = false,
				code = Types.RenderingRuntimeFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	if renderers[renderer.rendererId] ~= nil then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.DuplicateRenderer,
			message = "duplicate renderer",
		}
	end
	if
		not Types.isRenderingRuntimeRendererStatus(renderer.status)
		or not validKinds(renderer.supportedRenderingKinds)
	then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.ValidationFailure,
			message = "invalid renderer metadata",
		}
	end
	local serializable, reason = Serialization.validateSerializable(renderer.runtimeMetadata or {})
	if not serializable then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.ValidationFailure,
			message = reason,
		}
	end
	nextOrdinal += 1
	local record = {
		rendererId = renderer.rendererId,
		providerName = renderer.providerName,
		version = renderer.version,
		supportedRenderingKinds = Serialization.deepCopy(renderer.supportedRenderingKinds),
		supportedDescriptorVersions = Serialization.deepCopy(
			renderer.supportedDescriptorVersions or { "1.0.0" }
		),
		supportedContractVersions = Serialization.deepCopy(
			renderer.supportedContractVersions or { "1.0.0" }
		),
		capacity = tonumber(renderer.capacity) or 1,
		currentLoad = 0,
		priority = tonumber(renderer.priority) or 0,
		status = renderer.status,
		registrationOrdinal = nextOrdinal,
		runtimeMetadata = Serialization.deepCopy(renderer.runtimeMetadata or {}),
	}
	renderers[record.rendererId] = record
	order[#order + 1] = record.rendererId
	Metrics.increment("renderersRegistered")
	if record.status == Types.RenderingRuntimeRendererStatus.Available then
		Metrics.increment("renderersAvailable")
	end
	Evidence.record("renderer registered", record)
	return { ok = true, code = "Ok", renderer = Serialization.deepCopy(record) }
end

function Registry.get(rendererId: string)
	return Serialization.deepCopy(renderers[rendererId])
end

function Registry.assign(rendererId: string)
	local renderer = renderers[rendererId]
	if renderer == nil then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.UnknownRenderer,
			message = "unknown renderer",
		}
	end
	if
		renderer.status ~= Types.RenderingRuntimeRendererStatus.Available
		and renderer.status ~= Types.RenderingRuntimeRendererStatus.Registered
	then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.RendererUnavailable,
			message = "renderer unavailable",
		}
	end
	if renderer.currentLoad >= renderer.capacity then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.RendererCapacityExceeded,
			message = "renderer capacity exceeded",
		}
	end
	renderer.currentLoad += 1
	if renderer.currentLoad >= renderer.capacity then
		renderer.status = Types.RenderingRuntimeRendererStatus.Busy
	end
	return { ok = true, code = "Ok", renderer = Serialization.deepCopy(renderer) }
end

function Registry.inspect()
	local result = {}
	for index, rendererId in ipairs(order) do
		result[index] = Serialization.deepCopy(renderers[rendererId])
	end
	return result
end

function Registry.clear()
	table.clear(renderers)
	table.clear(order)
	nextOrdinal = 0
end

return Registry
