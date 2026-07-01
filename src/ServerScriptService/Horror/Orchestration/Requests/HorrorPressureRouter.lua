--!strict
-- Converts approved orchestration decisions into approval-only bundles.

local Validator = require(script.Parent.Parent.Core.HorrorOrchestrationValidator)

local Router = {}

function Router.createBundle(
	action: string,
	request: any?,
	reasons: { string },
	requests: { any },
	metadata: any?
)
	local bundle = {
		bundleId = string.format("horror-bundle:%d", math.floor(os.clock() * 1000)),
		action = action,
		requestId = if request ~= nil then request.requestId else nil,
		reasons = table.clone(reasons),
		createdAt = os.clock(),
		requests = table.clone(requests),
		suppressed = action == "Suppress",
		delayed = action == "Delay" or action == "Silence" or action == "HoldPressure",
		releasePlanned = action == "Release",
		metadata = if type(metadata) == "table" then table.clone(metadata) else {},
	}
	local ok, reason = Validator.validateBundle(bundle)
	if not ok then
		return nil, reason
	end
	return bundle, nil
end

return Router
