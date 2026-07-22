--!strict
local Serialization = require(script.Parent.QuerySerialization)
local Types = require(script.Parent.QueryTypes)
local Cache = {}
local entries = {}
function Cache.record(query: any, result: any)
	if query.cachePolicy == Types.CachePolicy.NoCache then
		return
	end
	entries[query.queryId] = Serialization.deepCopy({
		generation = query.queryId,
		version = query.schemaVersion,
		timestamp = os.clock(),
		freshness = "Fresh",
		resultCode = result.code,
	})
end
function Cache.inspect()
	return Serialization.deepCopy(entries)
end
function Cache.clear()
	table.clear(entries)
end
return Cache
