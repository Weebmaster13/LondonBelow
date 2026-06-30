--!strict
--[[
	PortalZoneBinder discovers physical Studio portal zone parts.

	It is intentionally safe to run before the physical lobby exists. Missing
	Workspace/Portals or malformed zone parts are logged and skipped, never
	allowed to crash server startup.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Core = ServerScriptService.Core
local Logger = require(Core.Logger)

local PortalService = require(script.Parent.PortalService)

local PortalZoneBinder = {}

export type BindSummary = {
	rootFound: boolean,
	scanned: number,
	registered: number,
	warnings: { string },
}

local log = Logger.scope("PortalZoneBinder")
local rootFolderName = "Portals"
local bound = false
local lastSummary: BindSummary = {
	rootFound = false,
	scanned = 0,
	registered = 0,
	warnings = {},
}

local function warn(summary: BindSummary, message: string)
	table.insert(summary.warnings, message)
	log.warn(message)
end

local function getPortalId(instance: Instance): string?
	local attribute = instance:GetAttribute("PortalId")

	if type(attribute) == "string" and attribute ~= "" then
		return attribute
	end

	if instance.Name ~= "" then
		return instance.Name
	end

	return nil
end

function PortalZoneBinder.bindExistingZones(): BindSummary
	local summary: BindSummary = {
		rootFound = false,
		scanned = 0,
		registered = 0,
		warnings = {},
	}

	local root = Workspace:FindFirstChild(rootFolderName)

	if root == nil then
		warn(summary, "Workspace/Portals does not exist yet; portal zones were not bound.")
		lastSummary = summary
		return summary
	end

	if not root:IsA("Folder") then
		warn(summary, "Workspace/Portals exists but is not a Folder; portal zones were not bound.")
		lastSummary = summary
		return summary
	end

	summary.rootFound = true

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			summary.scanned += 1

			local portalId = getPortalId(descendant)

			if portalId == nil then
				warn(
					summary,
					string.format(
						"Portal zone %s has no PortalId attribute or usable name.",
						descendant:GetFullName()
					)
				)
				continue
			end

			local ok, err = PortalService.registerPortalZone(portalId, descendant)

			if ok then
				summary.registered += 1
				log.withContext("SUCCESS", "Portal zone bound", {
					portalId = portalId,
					zone = descendant:GetFullName(),
				})
			else
				warn(
					summary,
					string.format(
						"Portal zone %s failed to bind as %s: %s",
						descendant:GetFullName(),
						portalId,
						tostring(err)
					)
				)
			end
		end
	end

	if summary.scanned == 0 then
		warn(summary, "Workspace/Portals exists but contains no BasePart portal zones.")
	end

	lastSummary = summary
	return summary
end

function PortalZoneBinder.start()
	if bound then
		return
	end

	bound = true
	PortalZoneBinder.bindExistingZones()
end

function PortalZoneBinder.inspect()
	return {
		bound = bound,
		rootFolderName = rootFolderName,
		lastSummary = lastSummary,
	}
end

function PortalZoneBinder.validate(): (boolean, string?)
	return true, nil
end

return PortalZoneBinder
