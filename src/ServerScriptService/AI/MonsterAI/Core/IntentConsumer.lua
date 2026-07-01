--!strict
-- Normalizes approved monster intent/context into a safe dry-run execution request.

local Serialization = require(script.Parent.MonsterAISerialization)
local Types = require(script.Parent.MonsterAITypes)
local Validator = require(script.Parent.MonsterAIValidator)

local IntentConsumer = {}

local function now(): number
	return os.clock()
end

function IntentConsumer.normalize(rawIntent: any)
	local createdAt = if type(rawIntent) == "table"
			and type(rawIntent.createdAt) == "number"
		then rawIntent.createdAt
		else now()
	local intent = {
		intentId = if type(rawIntent) == "table" then rawIntent.intentId else nil,
		monsterId = if type(rawIntent) == "table" then rawIntent.monsterId else nil,
		intentKind = if type(rawIntent) == "table" then rawIntent.intentKind else nil,
		sourceSystem = if type(rawIntent) == "table" then rawIntent.sourceSystem else nil,
		approvedBy = if type(rawIntent) == "table" then rawIntent.approvedBy else nil,
		approvalId = if type(rawIntent) == "table" then rawIntent.approvalId else nil,
		priority = if type(rawIntent) == "table" and type(rawIntent.priority) == "number"
			then rawIntent.priority
			else 0,
		createdAt = createdAt,
		expiresAt = if type(rawIntent) == "table"
				and type(rawIntent.expiresAt) == "number"
			then rawIntent.expiresAt
			else createdAt + Types.Limits.DefaultExpirationSeconds,
		context = if type(rawIntent) == "table" and rawIntent.context ~= nil
			then Serialization.deepCopy(rawIntent.context)
			else {},
		metadata = if type(rawIntent) == "table" and rawIntent.metadata ~= nil
			then Serialization.deepCopy(rawIntent.metadata)
			else {},
		reasons = if type(rawIntent) == "table" and type(rawIntent.reasons) == "table"
			then table.clone(rawIntent.reasons)
			else {},
	}
	local ok, reason = Validator.validateIntent(intent, now())
	if not ok then
		return nil, reason
	end
	return intent, nil
end

return IntentConsumer
