--!strict

local Resolver = {}
local supported = table.freeze({
	Fixed = true,
	Scale = true,
	Reflow = true,
	SafeArea = true,
	AdaptiveText = true,
})

function Resolver.classify(viewport: Vector2): string
	local shortest = math.min(viewport.X, viewport.Y)
	if shortest < 500 then
		return "Compact"
	elseif shortest < 800 then
		return "Standard"
	end
	return "Expanded"
end

function Resolver.resolve(policy: string, viewport: Vector2, safeInsets: any): (boolean, any)
	if not supported[policy] then
		return false, "UnsupportedResponsivePolicy"
	end
	local class = Resolver.classify(viewport)
	local shortest = math.max(1, math.min(viewport.X, viewport.Y))
	local scale = math.clamp(shortest / 720, 0.75, 1.35)
	local textScale = math.clamp(shortest / 720, 0.85, 1.25)
	return true,
		table.freeze({
			policy = policy,
			viewportClass = class,
			scale = policy == "Scale" and scale or 1,
			textScale = policy == "AdaptiveText" and textScale or 1,
			reflow = policy == "Reflow",
			safeInsets = policy == "SafeArea" and safeInsets or nil,
		})
end

return table.freeze(Resolver)
