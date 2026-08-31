--!strict

local Types = require(script.Parent.RobloxGuiThemeTypes)

local Catalog = {}
local themes = {}
local count = 0

local function validId(value: any): boolean
	return type(value) == "string" and #value > 0 and #value <= Types.Limits.maxThemeIdLength
		and string.match(value, "^[a-z][a-z0-9%-_]*$") ~= nil
end

local function copyTokens(tokens: any): (any?, string?)
	if type(tokens) ~= "table" then return nil, Types.FailureType.InvalidToken end
	local result = {}
	local tokenCount = 0
	for name, value in pairs(tokens) do
		if type(name) ~= "string" or #name == 0 or #name > Types.Limits.maxTokenNameLength
			or string.match(name, "^[a-z][a-zA-Z0-9%.%-_]*$") == nil then
			return nil, Types.FailureType.InvalidToken
		end
		if typeof(value) ~= "Color3" and typeof(value) ~= "Font" and type(value) ~= "number" then
			return nil, Types.FailureType.InvalidValue
		end
		tokenCount += 1
		if tokenCount > Types.Limits.maxTokensPerTheme then return nil, Types.FailureType.BudgetExceeded end
		result[name] = value
	end
	return table.freeze(result), nil
end

function Catalog.register(themeId: any, revision: any, tokens: any)
	if not validId(themeId) or type(revision) ~= "number" or revision % 1 ~= 0 or revision < 1 then
		return { ok = false, code = Types.FailureType.InvalidTheme }
	end
	local existing = themes[themeId]
	if existing and revision < existing.revision then return { ok = false, code = Types.FailureType.StaleRevision } end
	local copied, reason = copyTokens(tokens)
	if not copied then return { ok = false, code = reason } end
	if existing and revision == existing.revision then
		for name, value in pairs(copied) do if existing.tokens[name] ~= value then return { ok = false, code = Types.FailureType.RevisionConflict } end end
		for name in pairs(existing.tokens) do if copied[name] == nil then return { ok = false, code = Types.FailureType.RevisionConflict } end end
		return { ok = true, idempotent = true, revision = revision }
	end
	if not existing then
		if count >= Types.Limits.maxThemes then return { ok = false, code = Types.FailureType.BudgetExceeded } end
		count += 1
	end
	themes[themeId] = table.freeze({ themeId = themeId, revision = revision, tokens = copied })
	return { ok = true, idempotent = false, revision = revision }
end

function Catalog.get(themeId: string) return themes[themeId] end
function Catalog.snapshot()
	local ids = {}; for id in pairs(themes) do ids[#ids + 1] = id end; table.sort(ids)
	local entries = {}; for _, id in ipairs(ids) do entries[#entries + 1] = { themeId = id, revision = themes[id].revision } end
	return { count = count, themes = entries }
end
function Catalog.reset() themes = {}; count = 0 end

return Catalog
