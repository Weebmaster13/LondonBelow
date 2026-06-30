--!strict
-- Countdown, cooldown, transition, and recovery scheduling for lobby portals.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Scheduler = require(ServerScriptService.Core.Scheduler)
local MatchmakingService = require(ServerScriptService.Lobby.Matchmaking.MatchmakingService)

local PortalConfig = require(script.Parent.PortalConfig)
local PortalTypes = require(script.Parent.PortalTypes)

local PortalCountdown = {}

type PortalRuntime = PortalTypes.PortalRuntime
type PortalResult = PortalTypes.PortalResult
type TaskHandle = Scheduler.TaskHandle

export type Context = {
	serializePortal: (PortalRuntime) -> any,
	setState: (PortalRuntime, PortalTypes.PortalState, string, any?) -> boolean,
	validateReadyToLaunch: (Player, PortalRuntime) -> PortalResult,
	fireAtmosphereCue: (PortalRuntime, string, any?) -> (),
	refreshPortalState: (string, string) -> (),
}

local countdownHandles: { [string]: TaskHandle } = {}
local cooldownHandles: { [string]: TaskHandle } = {}
local transitionHandles: { [string]: { TaskHandle } } = {}

local function addTransitionHandle(portal: PortalRuntime, handle: TaskHandle)
	local handles = transitionHandles[portal.id]

	if handles == nil then
		handles = {}
		transitionHandles[portal.id] = handles
	end

	table.insert(handles, handle)
end

function PortalCountdown.cancelCountdown(portal: PortalRuntime)
	local handle = countdownHandles[portal.id]

	if handle ~= nil then
		Scheduler.cancel(handle)
		countdownHandles[portal.id] = nil
	end

	portal.countdownRemaining = 0
end

function PortalCountdown.cancelTransitionTasks(portal: PortalRuntime)
	local handles = transitionHandles[portal.id]

	if handles == nil then
		return
	end

	for _, handle in ipairs(handles) do
		Scheduler.cancel(handle)
	end

	transitionHandles[portal.id] = nil
end

function PortalCountdown.beginLaunchAttempt(portal: PortalRuntime): number
	portal.launchToken += 1
	return portal.launchToken
end

function PortalCountdown.scheduleCooldown(portal: PortalRuntime, reason: string, context: Context)
	local existing = cooldownHandles[portal.id]

	if existing ~= nil then
		Scheduler.cancel(existing)
	end

	portal.cooldownUntil = os.clock() + portal.definition.cooldownSeconds
	context.setState(portal, PortalConfig.PortalStates.Cooldown, reason, nil)

	cooldownHandles[portal.id] = Scheduler.delay(portal.definition.cooldownSeconds, function()
		cooldownHandles[portal.id] = nil
		context.refreshPortalState(portal.id, "CooldownComplete")
	end, "PortalCooldown:" .. portal.id, "LobbyPortal", { "Portal", "Cooldown" })
end

function PortalCountdown.failPortal(
	portal: PortalRuntime,
	reason: string,
	data: any?,
	context: Context
)
	PortalCountdown.cancelCountdown(portal)
	PortalCountdown.cancelTransitionTasks(portal)
	portal.lastFailure = reason
	context.setState(portal, PortalConfig.PortalStates.Failed, reason, data)

	addTransitionHandle(
		portal,
		Scheduler.delay(PortalConfig.FailedStateHoldSeconds, function()
			if portal.state == PortalConfig.PortalStates.Failed then
				transitionHandles[portal.id] = nil
				PortalCountdown.scheduleCooldown(portal, reason, context)
			end
		end, "PortalFailedHold:" .. portal.id, "LobbyPortal", { "Portal", "Failure" })
	)
end

function PortalCountdown.start(
	player: Player,
	portal: PortalRuntime,
	context: Context,
	transitionToLaunch: (Player, string, number?) -> PortalResult
): PortalResult
	if countdownHandles[portal.id] ~= nil then
		return PortalTypes.err(
			PortalTypes.ResultCode.LaunchInProgress,
			"Portal countdown is already running.",
			context.serializePortal(portal)
		)
	end

	local validation = context.validateReadyToLaunch(player, portal)

	if not validation.ok then
		return validation
	end

	local launchToken = PortalCountdown.beginLaunchAttempt(portal)
	portal.countdownRemaining = portal.definition.countdownSeconds
	context.setState(portal, PortalConfig.PortalStates.ReadyToLaunch, "LaunchRequested", nil)
	context.fireAtmosphereCue(portal, PortalConfig.AtmosphereCues.CarriageLanternFlicker, {
		countdown = portal.countdownRemaining,
	})
	context.setState(portal, PortalConfig.PortalStates.Countdown, "CountdownStarted", {
		countdown = portal.countdownRemaining,
	})

	countdownHandles[portal.id] = Scheduler.interval(1, function()
		if portal.launchToken ~= launchToken then
			return
		end

		local leader = Players:GetPlayerByUserId(player.UserId)
		local currentValidation = if leader ~= nil
			then context.validateReadyToLaunch(leader, portal)
			else PortalTypes.err(
				PortalTypes.ResultCode.NotLeader,
				"Party leader left during countdown.",
				context.serializePortal(portal)
			)

		if not currentValidation.ok then
			PortalCountdown.failPortal(
				portal,
				currentValidation.message,
				currentValidation,
				context
			)
			return
		end

		portal.countdownRemaining -= 1

		if portal.countdownRemaining <= 0 then
			PortalCountdown.cancelCountdown(portal)
			transitionToLaunch(leader :: Player, portal.id, launchToken)
			return
		end

		context.fireAtmosphereCue(portal, PortalConfig.AtmosphereCues.Heartbeat, {
			countdown = portal.countdownRemaining,
		})
		context.setState(portal, PortalConfig.PortalStates.Countdown, "CountdownTick", {
			countdown = portal.countdownRemaining,
		})
	end, "PortalCountdown:" .. portal.id, "LobbyPortal", { "Portal", "Countdown" })

	return PortalTypes.ok("Portal countdown started.", context.serializePortal(portal))
end

function PortalCountdown.transitionToLaunch(
	player: Player,
	portal: PortalRuntime,
	launchToken: number?,
	context: Context
): PortalResult
	if launchToken ~= nil and portal.launchToken ~= launchToken then
		return PortalTypes.err(
			PortalTypes.ResultCode.StateConflict,
			"Portal launch attempt is no longer current.",
			context.serializePortal(portal)
		)
	end

	local validation = context.validateReadyToLaunch(player, portal)

	if not validation.ok then
		PortalCountdown.failPortal(portal, validation.message, validation, context)
		return validation
	end

	context.setState(
		portal,
		PortalConfig.PortalStates.Transitioning,
		"CinematicTransitionStarted",
		nil
	)

	for index, cue in ipairs(portal.definition.cinematicSequence) do
		addTransitionHandle(
			portal,
			Scheduler.delay(
				(index - 1) * 0.15,
				function()
					if launchToken ~= nil and portal.launchToken ~= launchToken then
						return
					end

					context.fireAtmosphereCue(portal, cue, {
						sequenceIndex = index,
						total = #portal.definition.cinematicSequence,
					})
				end,
				"PortalCue:" .. portal.id .. ":" .. cue,
				"LobbyPortal",
				{
					"Portal",
					"Atmosphere",
				}
			)
		)
	end

	addTransitionHandle(
		portal,
		Scheduler.delay(1, function()
			if launchToken ~= nil and portal.launchToken ~= launchToken then
				return
			end

			if portal.state ~= PortalConfig.PortalStates.Transitioning then
				return
			end

			local leader = Players:GetPlayerByUserId(player.UserId)

			if leader == nil then
				PortalCountdown.failPortal(
					portal,
					"Party leader left before matchmaking launch.",
					nil,
					context
				)
				return
			end

			local launchValidation = context.validateReadyToLaunch(leader, portal)

			if not launchValidation.ok then
				PortalCountdown.failPortal(
					portal,
					launchValidation.message,
					launchValidation,
					context
				)
				return
			end

			context.setState(
				portal,
				PortalConfig.PortalStates.Launching,
				"DelegatingToMatchmaking",
				nil
			)

			local launchResult = MatchmakingService.requestLaunch(leader)
			transitionHandles[portal.id] = nil

			if not launchResult.ok then
				PortalCountdown.failPortal(portal, launchResult.message, launchResult, context)
			end
		end, "PortalLaunch:" .. portal.id, "LobbyPortal", { "Portal", "Launch" })
	)

	return PortalTypes.ok("Portal transition started.", context.serializePortal(portal))
end

function PortalCountdown.cleanup()
	for _, handle in pairs(countdownHandles) do
		Scheduler.cancel(handle)
	end

	for _, handle in pairs(cooldownHandles) do
		Scheduler.cancel(handle)
	end

	for _, handles in pairs(transitionHandles) do
		for _, handle in ipairs(handles) do
			Scheduler.cancel(handle)
		end
	end

	table.clear(countdownHandles)
	table.clear(cooldownHandles)
	table.clear(transitionHandles)
end

function PortalCountdown.inspect()
	return {
		countdowns = table.clone(countdownHandles),
		cooldowns = table.clone(cooldownHandles),
		transitionTaskGroups = table.clone(transitionHandles),
	}
end

return PortalCountdown
