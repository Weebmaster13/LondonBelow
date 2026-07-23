--!strict

local Capabilities = require(script.Parent.RobloxCapabilityRegistry)
local Negotiation = require(script.Parent.RobloxCapabilityNegotiation)
local Renderers = require(script.Parent.RobloxRendererRegistry)
local Types = require(script.Parent.PresentationTypes)

local Validation = {}

function Validation.validate(): (boolean, string?)
	for _, renderer in ipairs(Renderers.inspect()) do
		if renderer.platform ~= Types.RobloxRenderingPlatform then
			return false, "renderer platform mismatch"
		end
		if not Types.isRobloxRendererStatus(renderer.status) then
			return false, "invalid renderer status"
		end
	end
	for _, capability in ipairs(Capabilities.inspect()) do
		if not Types.isRobloxRenderingFeature(capability.feature) then
			return false, "invalid capability feature"
		end
	end
	for _, record in ipairs(Negotiation.inspect()) do
		if record.platform ~= Types.RobloxRenderingPlatform then
			return false, "compatibility platform mismatch"
		end
		if not Types.isRenderingKind(record.renderingKind) then
			return false, "invalid compatibility rendering kind"
		end
	end
	return true, nil
end

return Validation
