--!strict
-- Diagnostics aggregation for Save / Journal / Identity runtime foundation.

local Diagnostics = {}

function Diagnostics.capture(runtime: any, dependencies: { [string]: any })
	local profiles = dependencies.Profiles.inspect()
	local checkpoints = dependencies.Checkpoints.inspect()
	local journal = dependencies.Journal.inspect()
	local fragments = dependencies.MemoryFragments.inspect()
	local identity = dependencies.Identity.inspect()
	local replay = dependencies.Replay.inspect()
	return {
		initialized = runtime.initialized,
		started = runtime.started,
		mode = runtime.mode,
		profileCount = profiles.profileCount,
		checkpointCount = checkpoints.checkpointCount,
		journalEntryCount = journal.journalEntryCount,
		memoryFragmentCount = fragments.memoryFragmentCount,
		identityCount = identity.identityCount,
		replayStateCount = replay.replayStateCount,
		validationFailureCount = #runtime.validationFailures,
		profiles = profiles,
		checkpoints = checkpoints,
		journal = journal,
		memoryFragments = fragments,
		identity = identity,
		replay = replay,
		validationFailures = runtime.validationFailures,
		lastSelfChecks = runtime.lastSelfChecks,
		health = {
			healthy = runtime.initialized and runtime.mode == "ServerAuthoritativeFoundation",
			status = if not runtime.initialized
				then "NotInitialized"
				elseif runtime.started then "Running"
				else "Ready",
			message = "Save / Journal / Identity runtime is server-authoritative foundation state only.",
		},
	}
end

function Diagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics
