--!strict
-- Type definitions and constants for the server-authoritative party runtime.

local PartyTypes = {}

export type PartyMember = {
	userId: number,
	name: string,
	joinedAt: number,
}

export type Party = {
	id: string,
	leaderUserId: number,
	members: { [number]: PartyMember },
	memberOrder: { number },
	ready: { [number]: boolean },
	selectedChapterId: string,
	locked: boolean,
	launching: boolean,
	createdAt: number,
	updatedAt: number,
}

export type Result = {
	ok: boolean,
	code: string,
	message: string,
	party: any?,
	data: any?,
}

PartyTypes.ResultCode = {
	Ok = "OK",
	InvalidRequest = "INVALID_REQUEST",
	AlreadyInParty = "ALREADY_IN_PARTY",
	NotInParty = "NOT_IN_PARTY",
	PartyNotFound = "PARTY_NOT_FOUND",
	PartyFull = "PARTY_FULL",
	PartyLocked = "PARTY_LOCKED",
	NotLeader = "NOT_LEADER",
	CannotKickSelf = "CANNOT_KICK_SELF",
	MemberNotFound = "MEMBER_NOT_FOUND",
	InvalidChapter = "INVALID_CHAPTER",
	NotReady = "NOT_READY",
	LaunchInProgress = "LAUNCH_IN_PROGRESS",
	LaunchCooldown = "LAUNCH_COOLDOWN",
	TeleportDisabled = "TELEPORT_DISABLED",
	TeleportFailed = "TELEPORT_FAILED",
}

function PartyTypes.ok(message: string, party: any?, data: any?): Result
	return {
		ok = true,
		code = PartyTypes.ResultCode.Ok,
		message = message,
		party = party,
		data = data,
	}
end

function PartyTypes.err(code: string, message: string, party: any?, data: any?): Result
	return {
		ok = false,
		code = code,
		message = message,
		party = party,
		data = data,
	}
end

return PartyTypes
