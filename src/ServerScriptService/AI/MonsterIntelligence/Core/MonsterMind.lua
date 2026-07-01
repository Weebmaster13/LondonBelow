--!strict
--[[
	MonsterMind decides intent from bounded scores and explainable reasons.

	It does not move, pathfind, animate, damage, spawn, or mutate Workspace.
	Future Monster AI may consume approved intentions later.
]]

local InterestModel = require(script.Parent.Parent.Behavior.InterestModel)
local ThreatModel = require(script.Parent.Parent.Behavior.ThreatModel)
local CuriosityModel = require(script.Parent.Parent.Behavior.CuriosityModel)
local PatienceModel = require(script.Parent.Parent.Behavior.PatienceModel)
local InvestigationModel = require(script.Parent.Parent.Behavior.InvestigationModel)
local SearchModel = require(script.Parent.Parent.Behavior.SearchModel)
local TerritoryModel = require(script.Parent.Parent.Behavior.TerritoryModel)
local Validator = require(script.Parent.MonsterValidator)

local MonsterMind = {}

local function append(target: { string }, source: { string })
	for _, value in ipairs(source) do
		table.insert(target, value)
	end
end

local function chooseKind(scores: any): string
	if scores.threat >= 75 and scores.patience < 35 then
		return "Pressure"
	end
	if scores.investigation >= 55 then
		return "Investigate"
	end
	if scores.search >= 45 then
		return "Search"
	end
	if scores.curiosity >= 35 and scores.patience >= 45 then
		return "Observe"
	end
	if scores.patience >= 70 then
		return "Wait"
	end
	if scores.territory >= 55 then
		return "Coordinate"
	end
	return "Ignore"
end

function MonsterMind.decide(monsterId: string, context: any)
	local reasons = {}
	local interest, interestReasons = InterestModel.score(context)
	append(reasons, interestReasons)

	local curiosity, curiosityReasons = CuriosityModel.score(context)
	append(reasons, curiosityReasons)

	local threat, threatReasons = ThreatModel.score({
		interest = interest,
		memoryConfidence = context.memoryConfidence,
		identityExposure = context.identityExposure,
		groupSplit = context.groupSplit,
	})
	append(reasons, threatReasons)

	local patience, patienceReasons = PatienceModel.score({
		basePatience = context.basePatience,
		investigationFailures = context.investigationFailures,
		pressure = threat,
	})
	append(reasons, patienceReasons)

	local search, searchReasons = SearchModel.score(context)
	append(reasons, searchReasons)

	local territory, territoryReasons = TerritoryModel.score(context)
	append(reasons, territoryReasons)

	local investigation, investigationReasons = InvestigationModel.score({
		interest = interest,
		curiosity = curiosity,
		patience = patience,
	})
	append(reasons, investigationReasons)

	local scores = {
		interest = interest,
		curiosity = curiosity,
		threat = threat,
		patience = patience,
		search = search,
		territory = territory,
		investigation = investigation,
	}
	local kind = chooseKind(scores)
	local priority = math.clamp(math.max(interest, threat, investigation, search), 0, 100)
	local confidence =
		math.clamp((priority / 100) * 0.7 + (context.memoryConfidence or 0) * 0.3, 0, 1)

	local intent = {
		intentId = string.format("%s:intent:%d", monsterId, math.floor(os.clock() * 1000)),
		monsterId = monsterId,
		kind = kind,
		targetPlayerId = context.targetPlayerId,
		targetZoneId = context.targetZoneId,
		confidence = confidence,
		priority = priority,
		reasons = reasons,
		createdAt = os.clock(),
		expiresAt = os.clock() + 8,
		metadata = {
			scores = scores,
			mode = "IntentOnly",
		},
	}

	local ok, reason = Validator.validateIntent(intent)
	if not ok then
		return nil, reason
	end

	return intent, nil
end

return MonsterMind
