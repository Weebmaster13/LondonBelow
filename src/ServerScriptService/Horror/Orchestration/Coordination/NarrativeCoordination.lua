--!strict
-- Future Narrative Runtime coordination without implementing narrative systems.

local NarrativeCoordination = {}

function NarrativeCoordination.build(action: string, request: any)
	if
		request.metadata
		and (request.metadata.emotionalBeat == true or request.metadata.majorReveal == true)
	then
		return {
			{
				target = "NarrativeRuntimeFuture",
				recommendation = "ProtectEmotionalBeat",
				approvalOnly = true,
			},
		}
	end
	if action == "Silence" then
		return {
			{
				target = "NarrativeRuntimeFuture",
				recommendation = "HoldForMeaning",
				approvalOnly = true,
			},
		}
	end
	return {
		{ target = "Narrative", recommendation = "NoAction", approvalOnly = true },
	}
end

return NarrativeCoordination
