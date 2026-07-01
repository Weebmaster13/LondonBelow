--!strict

local DoorDiagnostics = {}

function DoorDiagnostics.capture(state: any)
	local counts = {}
	for _, status in pairs(state.statuses) do
		counts[status.state] = (counts[status.state] or 0) + 1
	end
	return {
		registeredDoors = state.registeredCount,
		doorStateCounts = counts,
		statuses = state.statuses,
		recentTransitions = state.recentTransitions,
		counters = state.counters,
		health = {
			healthy = true,
			status = "Ready",
			message = "Door Runtime validates state transitions without Workspace mutation.",
		},
	}
end

return DoorDiagnostics
