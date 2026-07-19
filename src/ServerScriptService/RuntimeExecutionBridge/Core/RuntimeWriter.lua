--!strict

local Serialization = require(script.Parent.Serialization)

local RuntimeWriter = {}

function RuntimeWriter.writeAtomic(session: any, evidence: any): any
	local payload = Serialization.stableSerialize(evidence)
	return {
		ok = false,
		status = "BLOCKED",
		failure = "Writer",
		reason = "Roblox server runtime cannot atomically write a local runtime-result.json file without a supported Studio export channel.",
		expectedOutputPath = session.expectedOutputPath,
		payloadChecksum = Serialization.checksum(payload),
		payloadAvailableInMemory = true,
		partialWriteRejected = true,
		duplicateWriteRejected = true,
		overwroteExistingSession = false,
	}
end

return RuntimeWriter
