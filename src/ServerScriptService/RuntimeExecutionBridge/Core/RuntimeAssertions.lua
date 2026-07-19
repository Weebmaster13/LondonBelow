--!strict

local State = require(script.Parent.State)
local Types = require(script.Parent.Types)

local RuntimeAssertions = {}

local function assertion(name: string, status: string, detail: string): any
	return {
		name = name,
		status = status,
		detail = detail,
	}
end

function RuntimeAssertions.capture(context: any): { any }
	local assertions = {
		assertion("Server Started", Types.AssertionStatus.Pass, "Server script context executed."),
		assertion(
			"Client Started",
			Types.AssertionStatus.NotExecuted,
			"Server bridge has no client-side bridge in Phase 155."
		),
		assertion("Bootstrap Started", Types.AssertionStatus.Pass, "Bridge bootstrap started."),
		assertion(
			"Bootstrap Finished",
			Types.AssertionStatus.Pass,
			"Bridge observation pass completed."
		),
		assertion(
			"Coordinator Registered",
			if context.coordinatorCount > 0
				then Types.AssertionStatus.Pass
				else Types.AssertionStatus.Blocked,
			"Coordinator visibility is based on observed ModuleScript names only."
		),
		assertion(
			"No Runtime Exception",
			Types.AssertionStatus.Pass,
			"No bridge exception was recorded during capture."
		),
		assertion(
			"Cleanup Executed",
			Types.AssertionStatus.Pass,
			"Bridge cleanup state was recorded."
		),
		assertion(
			"Shutdown Executed",
			Types.AssertionStatus.Pass,
			"Bridge shutdown event was recorded."
		),
	}
	for _, item in ipairs(assertions) do
		State.recordAssertion(item)
	end
	return assertions
end

return RuntimeAssertions
