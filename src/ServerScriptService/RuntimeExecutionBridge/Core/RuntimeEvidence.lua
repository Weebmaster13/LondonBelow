--!strict

local Serialization = require(script.Parent.Serialization)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local RuntimeEvidence = {}

function RuntimeEvidence.build(
	session: any,
	observation: any,
	assertions: { any },
	diagnostics: { any },
	snapshots: { any },
	cleanup: any
): (boolean, string?, any?)
	local bridgeDetails = {
		frameworkVersion = session.frameworkVersion,
		bridgeVersion = Types.BridgeVersion,
		bootstrapStarted = true,
		bootstrapCompleted = true,
		coordinators = observation.coordinators,
		trustLevel = "STUDIO_SERVER_OBSERVED_EXPORT_BLOCKED",
		writer = {
			expectedOutputPath = session.expectedOutputPath,
			filesystemWriteSupported = false,
			reason = "Roblox server runtime does not expose a supported local filesystem write API.",
		},
	}
	local evidence = {
		schemaVersion = Types.SchemaVersion,
		runnerId = session.runnerId,
		sessionId = session.sessionId,
		phase = session.phase,
		repositoryCommit = session.repositoryCommit,
		runtime = {
			backend = session.executionMode,
			bridge = Types.RuntimeName,
			bridgeVersion = Types.BridgeVersion,
			details = bridgeDetails,
		},
		status = Types.Status.Blocked,
		studioVersion = "observedInStudioRuntime",
		serverStarted = observation.runService.isServer,
		clientStarted = false,
		clientCount = observation.players.count,
		assertions = assertions,
		diagnostics = diagnostics,
		snapshots = snapshots,
		audit = {
			{
				event = "runtimeEvidencePrepared",
				source = Types.RuntimeName,
				checksum = Serialization.checksum(bridgeDetails),
			},
		},
		errors = {},
		warnings = {
			"runtime-result.json could not be written from Roblox server runtime without a supported export channel.",
		},
		cleanup = cleanup,
		productionCertified = false,
		capturedAt = Types.StableTimestamp,
	}
	local ok, reason = Validation.evidence(evidence)
	if not ok then
		return false, reason, nil
	end
	return true, nil, evidence
end

return RuntimeEvidence
