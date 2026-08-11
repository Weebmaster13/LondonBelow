--!strict

local Evidence = require(script.Parent.VisualCompositionEvidence)
local Types = require(script.Parent.PresentationTypes)

local Lifecycle = {}

local allowed = {
	[Types.VisualCompositionState.Created] = {
		[Types.VisualCompositionState.Bound] = true,
		[Types.VisualCompositionState.Cancelled] = true,
	},
	[Types.VisualCompositionState.Bound] = {
		[Types.VisualCompositionState.Resolving] = true,
		[Types.VisualCompositionState.Released] = true,
		[Types.VisualCompositionState.Cancelled] = true,
	},
	[Types.VisualCompositionState.Resolving] = {
		[Types.VisualCompositionState.Resolved] = true,
		[Types.VisualCompositionState.Failed] = true,
	},
	[Types.VisualCompositionState.Resolved] = {
		[Types.VisualCompositionState.Active] = true,
		[Types.VisualCompositionState.Superseded] = true,
		[Types.VisualCompositionState.Released] = true,
	},
	[Types.VisualCompositionState.Active] = {
		[Types.VisualCompositionState.Superseded] = true,
		[Types.VisualCompositionState.Released] = true,
	},
	[Types.VisualCompositionState.Superseded] = {
		[Types.VisualCompositionState.Released] = true,
	},
	[Types.VisualCompositionState.Released] = {
		[Types.VisualCompositionState.Closed] = true,
	},
}

function Lifecycle.canTransition(fromState: string, toState: string): boolean
	return allowed[fromState] ~= nil and allowed[fromState][toState] == true
end

function Lifecycle.record(compositionInstanceId: string, fromState: string, toState: string)
	Evidence.record("composition lifecycle transition", {
		compositionInstanceId = compositionInstanceId,
		fromState = fromState,
		toState = toState,
	})
end

return Lifecycle
