--!strict
--[[
	RemoteManager is the future-proof networking registry.

	It owns namespaced remote creation, lookup, validation hooks, versioning,
	rate limiting, statistics, developer diagnostics, and extension points for
	future middleware, permissions, and packet compression.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(script.Parent.Logger)

local RemoteManager = {}

export type RemoteKind = "Event" | "Function"
export type RemoteDefinition = {
	namespace: string,
	name: string,
	version: number,
	kind: RemoteKind,
	rateLimit: number?,
	validator: ((Player, ...any) -> (boolean, string?))?,
}

local log = Logger.scope("RemoteManager")
local rootFolderName = "Remotes"
local definitions: { [string]: RemoteDefinition } = {}
local remotes: { [string]: Instance } = {}
local stats: { [string]: { calls: number, rejected: number, createdAt: number } } = {}
local rateBuckets: { [string]: { [number]: { windowStart: number, count: number } } } = {}
local middleware: { (Player, string, ...any) -> (boolean, string?) } = {}

local function keyOf(namespace: string, name: string, version: number?): string
	return string.format("%s/%s/v%d", namespace, name, version or 1)
end

local function getRoot(): Folder
	local root = ReplicatedStorage:FindFirstChild(rootFolderName)

	if root == nil then
		root = Instance.new("Folder")
		root.Name = rootFolderName
		root.Parent = ReplicatedStorage
	end

	return root :: Folder
end

local function getNamespaceFolder(namespace: string): Folder
	local root = getRoot()
	local folder = root:FindFirstChild(namespace)

	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = namespace
		folder.Parent = root
	end

	return folder :: Folder
end

local function createRemote(definition: RemoteDefinition): Instance
	local namespaceFolder = getNamespaceFolder(definition.namespace)
	local remoteName = string.format("%s_v%d", definition.name, definition.version)
	local existing = namespaceFolder:FindFirstChild(remoteName)

	if existing ~= nil then
		return existing
	end

	local remote = if definition.kind == "Function"
		then Instance.new("RemoteFunction")
		else Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = namespaceFolder

	log.withContext("DEBUG", "Remote created", {
		namespace = definition.namespace,
		name = definition.name,
		version = definition.version,
		kind = definition.kind,
	})

	return remote
end

local function checkRateLimit(player: Player, key: string, limit: number?): (boolean, string?)
	if limit == nil then
		return true, nil
	end

	local now = os.clock()
	local buckets = rateBuckets[key]

	if buckets == nil then
		buckets = {}
		rateBuckets[key] = buckets
	end

	local bucket = buckets[player.UserId]

	if bucket == nil or now - bucket.windowStart >= 1 then
		bucket = {
			windowStart = now,
			count = 0,
		}
		buckets[player.UserId] = bucket
	end

	bucket.count += 1

	if bucket.count > limit then
		return false, "Rate limit exceeded"
	end

	return true, nil
end

function RemoteManager.configure(rootName: string?)
	if rootName ~= nil then
		assert(type(rootName) == "string" and rootName ~= "", "rootName must be a non-empty string")
		rootFolderName = rootName
	end
end

function RemoteManager.define(definition: RemoteDefinition): Instance
	assert(
		type(definition.namespace) == "string" and definition.namespace ~= "",
		"namespace is required"
	)
	assert(type(definition.name) == "string" and definition.name ~= "", "name is required")
	assert(
		definition.kind == "Event" or definition.kind == "Function",
		"kind must be Event or Function"
	)

	local version = definition.version or 1
	definition.version = version

	local key = keyOf(definition.namespace, definition.name, version)

	definitions[key] = definition

	local remote = createRemote(definition)
	remotes[key] = remote
	stats[key] = stats[key] or {
		calls = 0,
		rejected = 0,
		createdAt = os.clock(),
	}

	return remote
end

function RemoteManager.get(namespace: string, name: string, version: number?): Instance
	local key = keyOf(namespace, name, version)
	local remote = remotes[key]

	if remote == nil then
		local definition = definitions[key]

		if definition == nil then
			error("Remote is not defined: " .. key, 2)
		end

		remote = createRemote(definition)
		remotes[key] = remote
	end

	return remote
end

function RemoteManager.addMiddleware(callback: (Player, string, ...any) -> (boolean, string?))
	assert(type(callback) == "function", "callback must be a function")

	table.insert(middleware, callback)
end

function RemoteManager.validateCall(
	player: Player,
	namespace: string,
	name: string,
	version: number?,
	...: any
): (boolean, string?)
	local key = keyOf(namespace, name, version)
	local definition = definitions[key]

	if definition == nil then
		return false, "Remote is not defined"
	end

	local remoteStats = stats[key]

	if remoteStats ~= nil then
		remoteStats.calls += 1
	end

	local rateOk, rateErr = checkRateLimit(player, key, definition.rateLimit)

	if not rateOk then
		if remoteStats ~= nil then
			remoteStats.rejected += 1
		end

		return false, rateErr
	end

	for _, callback in ipairs(middleware) do
		local ok, allowed, reason = pcall(callback, player, key, ...)

		if not ok or not allowed then
			if remoteStats ~= nil then
				remoteStats.rejected += 1
			end

			return false, if ok then reason else tostring(allowed)
		end
	end

	if definition.validator ~= nil then
		local ok, allowed, reason = pcall(definition.validator, player, ...)

		if not ok or not allowed then
			if remoteStats ~= nil then
				remoteStats.rejected += 1
			end

			return false, if ok then reason else tostring(allowed)
		end
	end

	return true, nil
end

function RemoteManager.inspect()
	return {
		rootFolderName = rootFolderName,
		definitions = table.clone(definitions),
		stats = table.clone(stats),
		middlewareCount = #middleware,
	}
end

function RemoteManager.validate(): (boolean, string?)
	for key, definition in pairs(definitions) do
		if remotes[key] == nil then
			return false, "Remote definition has no instance: " .. key
		end

		if definition.version < 1 then
			return false, "Remote version must be positive: " .. key
		end
	end

	return true, nil
end

return RemoteManager
