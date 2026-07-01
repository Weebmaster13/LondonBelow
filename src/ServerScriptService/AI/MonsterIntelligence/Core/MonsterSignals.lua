--!strict
--[[
	EventBus signal names for Monster Intelligence.

	These are server-process events only. Phase 15 creates no client remotes and
	no presentation channel.
]]

local MonsterSignals = {}

MonsterSignals.MonsterRegistered = "MonsterIntelligence.MonsterRegistered"
MonsterSignals.MonsterStateChanged = "MonsterIntelligence.StateChanged"
MonsterSignals.MemoryRecorded = "MonsterIntelligence.MemoryRecorded"
MonsterSignals.KnowledgeUpdated = "MonsterIntelligence.KnowledgeUpdated"
MonsterSignals.InterestUpdated = "MonsterIntelligence.InterestUpdated"
MonsterSignals.IntentRequested = "MonsterIntelligence.IntentRequested"
MonsterSignals.IntentDecided = "MonsterIntelligence.IntentDecided"
MonsterSignals.ClaimCreated = "MonsterIntelligence.ClaimCreated"
MonsterSignals.ClaimExpired = "MonsterIntelligence.ClaimExpired"
MonsterSignals.ValidationFailed = "MonsterIntelligence.ValidationFailed"

return MonsterSignals
