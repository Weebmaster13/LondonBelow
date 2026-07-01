--!strict
--[[
	Small copy helpers for Gameplay Intelligence data boundaries.

	Runtime definitions and snapshots are plain data tables, but many contain
	nested arrays or dictionaries. These helpers keep public APIs from leaking
	mutable internal tables into future chapter code, save code, diagnostics, or
	tests.
]]

local GameplayCopy = {}

function GameplayCopy.deep(value: any, depth: number?): any
	local currentDepth = depth or 0

	if type(value) ~= "table" then
		return value
	end

	if currentDepth > 8 then
		return nil
	end

	local copied = {}

	for key, child in pairs(value) do
		copied[GameplayCopy.deep(key, currentDepth + 1)] =
			GameplayCopy.deep(child, currentDepth + 1)
	end

	return copied
end

function GameplayCopy.array(values: { any }?): { any }
	if values == nil then
		return {}
	end

	local copied = {}

	for _, value in ipairs(values) do
		table.insert(copied, GameplayCopy.deep(value))
	end

	return copied
end

function GameplayCopy.dictionary(values: { [any]: any }?): { [any]: any }
	if values == nil then
		return {}
	end

	return GameplayCopy.deep(values)
end

return GameplayCopy
