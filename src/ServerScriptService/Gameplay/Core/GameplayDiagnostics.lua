--!strict

local GameplayDiagnostics = {}

function GameplayDiagnostics.capture(state: any, dependencies: { [string]: any })
	return {
		initialized = state.initialized,
		started = state.started,
		registry = dependencies.GameplayRegistry.inspect(),
		state = dependencies.GameplayState.inspect(),
		memory = dependencies.GameplayMemory.inspect(),
		objects = dependencies.ObjectRuntime.inspect(),
		doors = dependencies.DoorService.inspect(),
		inventory = dependencies.InventoryService.inspect(),
		keys = dependencies.KeyService.inspect(),
		objectives = dependencies.ObjectiveService.inspect(),
		puzzles = dependencies.PuzzleService.inspect(),
		health = {
			healthy = state.initialized,
			status = if state.started
				then "Running"
				elseif state.initialized then "Ready"
				else "NotInitialized",
			message = "Gameplay Intelligence is server-authoritative and content-free.",
		},
	}
end

return GameplayDiagnostics
