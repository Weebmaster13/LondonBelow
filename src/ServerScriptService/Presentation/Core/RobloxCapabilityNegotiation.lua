--!strict

local Capabilities = require(script.Parent.RobloxCapabilityRegistry)
local Evidence = require(script.Parent.RobloxRenderingEvidence)
local Metrics = require(script.Parent.RobloxRenderingMetrics)
local Profiler = require(script.Parent.RobloxRenderingProfiler)
local Renderers = require(script.Parent.RobloxRendererRegistry)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Negotiation = {}
local records = {}
local nextOrdinal = 0

local function contains(values: { any }, expected: string): boolean
	for _, value in ipairs(values) do
		if value == expected then
			return true
		end
	end
	return false
end

local function featureForKind(renderingKind: string): string?
	if renderingKind == Types.RenderingKind.DialogueLine then
		return Types.RobloxRenderingFeature.DialogueWindows
	elseif renderingKind == Types.RenderingKind.DialogueChoiceList then
		return Types.RobloxRenderingFeature.ChoiceMenus
	elseif renderingKind == Types.RenderingKind.Notification then
		return Types.RobloxRenderingFeature.Notifications
	elseif renderingKind == Types.RenderingKind.HUDPlan then
		return Types.RobloxRenderingFeature.HUD
	elseif renderingKind == Types.RenderingKind.Menu then
		return Types.RobloxRenderingFeature.Menus
	elseif renderingKind == Types.RenderingKind.Overlay then
		return Types.RobloxRenderingFeature.Overlays
	elseif renderingKind == Types.RenderingKind.Subtitle then
		return Types.RobloxRenderingFeature.SubtitleRendering
	elseif renderingKind == Types.RenderingKind.Caption then
		return Types.RobloxRenderingFeature.CaptionRendering
	elseif renderingKind == Types.RenderingKind.CameraPlan then
		return Types.RobloxRenderingFeature.CameraPlanning
	elseif renderingKind == Types.RenderingKind.AnimationPlan then
		return Types.RobloxRenderingFeature.AnimationPlanning
	elseif renderingKind == Types.RenderingKind.AudioPlan then
		return Types.RobloxRenderingFeature.AudioPlanning
	end
	return nil
end

function Negotiation.negotiate(input: any)
	if #records >= Types.RobloxRenderingLimits.MaxCompatibilityRecords then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.LimitExceeded,
			message = "compatibility record limit exceeded",
		}
	end
	if type(input) ~= "table" then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.ValidationFailure,
			message = "negotiation must be a table",
		}
	end
	for _, field in ipairs({
		"rendererId",
		"contractVersion",
		"descriptorVersion",
		"renderingKind",
		"synchronizationPolicy",
	}) do
		if type(input[field]) ~= "string" or input[field] == "" then
			return {
				ok = false,
				code = Types.RobloxRenderingFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	local renderer = Renderers.get(input.rendererId)
	if renderer == nil then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.UnknownRenderer,
			message = "unknown renderer",
		}
	end
	if not contains(renderer.supportedContractVersions, input.contractVersion) then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.UnsupportedContractVersion,
			message = "unsupported contract version",
		}
	end
	if not contains(renderer.supportedDescriptorVersions, input.descriptorVersion) then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.UnsupportedDescriptorVersion,
			message = "unsupported descriptor version",
		}
	end
	if
		not Types.isRenderingKind(input.renderingKind)
		or not contains(renderer.supportedRenderingKinds, input.renderingKind)
	then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.UnsupportedRenderingKind,
			message = "unsupported rendering kind",
		}
	end
	if
		not Types.isRenderingSynchronizationPolicy(input.synchronizationPolicy)
		or not contains(renderer.supportedSynchronizationPolicies, input.synchronizationPolicy)
	then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.NegotiationFailure,
			message = "unsupported synchronization policy",
		}
	end
	local feature = featureForKind(input.renderingKind)
	if feature ~= nil and not Capabilities.supports(feature) then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.NegotiationFailure,
			message = "feature unavailable",
		}
	end
	nextOrdinal += 1
	local record = {
		compatibilityId = input.compatibilityId
			or ("roblox.rendering.compatibility." .. tostring(nextOrdinal)),
		rendererId = input.rendererId,
		platform = Types.RobloxRenderingPlatform,
		contractVersion = input.contractVersion,
		descriptorVersion = input.descriptorVersion,
		renderingKind = input.renderingKind,
		synchronizationPolicy = input.synchronizationPolicy,
		feature = feature,
		compatible = true,
		ordinal = nextOrdinal,
		runtimeMetadata = Serialization.deepCopy(input.runtimeMetadata or {}),
	}
	records[#records + 1] = record
	Metrics.increment("compatibilityChecks")
	Metrics.increment("successfulNegotiations")
	Evidence.record("negotiation performed", record)
	Evidence.record("compatibility evaluated", record)
	Profiler.record(record.compatibilityId, "negotiationDuration", 0)
	Profiler.record(record.compatibilityId, "compatibilityLatency", 0)
	return { ok = true, code = "Ok", negotiation = Serialization.deepCopy(record) }
end

function Negotiation.inspect()
	return Serialization.deepCopy(records)
end

function Negotiation.clear()
	table.clear(records)
	nextOrdinal = 0
end

return Negotiation
