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
				request = "ProtectEmotionalBeat",
				approvalOnly = true,
			},
		}
	end
	if action == "Silence" then
		return {
			{ target = "NarrativeRuntimeFuture", request = "HoldForMeaning", approvalOnly = true },
		}
	end
	return {
		{ target = "Narrative", request = "NoAction", approvalOnly = true },
	}
end

return NarrativeCoordination
