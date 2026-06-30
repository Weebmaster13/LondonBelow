--!strict
--[[
	SnapshotManager captures structured runtime snapshots for debugging.

	It currently captures engine, loaded systems, players, and extension slots
	for future objectives, AI state, Horror Director, save state, and lobby state.
]]

local Players = game:GetService("Players")

local Logger = require(script.Parent.Logger)

local SnapshotManager = {}

export type Snapshot = {
	id: number,
	label: string,
	capturedAt: string,
	engine: any,
	systems: any,
	players: any,
	objectives: any?,
	ai: any?,
	horror: any?,
	save: any?,
	lobby: any?,
}

local log = Logger.scope("SnapshotManager")
local nextSnapshotId = 0
local snapshots: { Snapshot } = {}
local maxSnapshots = 25
local providers: { [string]: () -> any } = {}

local function capturePlayers()
	local players = {}

	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(players, {
			userId = player.UserId,
			name = player.Name,
		})
	end

	return players
end

function SnapshotManager.registerProvider(name: string, callback: () -> any)
	assert(type(name) == "string" and name ~= "", "name must be a non-empty string")
	assert(type(callback) == "function", "callback must be a function")

	providers[name] = callback
end

function SnapshotManager.capture(label: string, engineState: any?, loadedSystems: any?): Snapshot
	nextSnapshotId += 1

	local snapshot: Snapshot = {
		id = nextSnapshotId,
		label = label,
		capturedAt = DateTime.now():ToIsoDate(),
		engine = engineState or {},
		systems = loadedSystems or {},
		players = capturePlayers(),
	}

	for name, provider in pairs(providers) do
		local ok, result = pcall(provider)

		if ok then
			(snapshot :: any)[name] = result
		else
			log.withContext("WARN", "Snapshot provider failed", {
				provider = name,
				error = tostring(result),
			})
		end
	end

	table.insert(snapshots, snapshot)

	if #snapshots > maxSnapshots then
		table.remove(snapshots, 1)
	end

	return snapshot
end

function SnapshotManager.getLatest(): Snapshot?
	return snapshots[#snapshots]
end

function SnapshotManager.getAll(): { Snapshot }
	return table.clone(snapshots)
end

function SnapshotManager.clear()
	table.clear(snapshots)
end

function SnapshotManager.setMaxSnapshots(limit: number)
	assert(type(limit) == "number" and limit > 0, "limit must be positive")

	maxSnapshots = limit
end

function SnapshotManager.validate(): (boolean, string?)
	if maxSnapshots <= 0 then
		return false, "Snapshot limit must be positive"
	end

	return true, nil
end

return SnapshotManager
