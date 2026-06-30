--!strict
--[[
	Server feedback dispatcher for Player Experience.

	Owns structured feedback instructions sent to clients after server-approved
	state changes. It does not play final sounds, draw final UI, vibrate devices
	directly, or decide horror pacing.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.PlayerExperienceTypes)

local FeedbackService = {}

type FeedbackInstruction = Types.FeedbackInstruction

local feedbackSent = 0
local lastFeedback: { FeedbackInstruction } = {}
local sendFeedback: ((Player, { FeedbackInstruction }) -> ())? = nil

function FeedbackService.configure(sender: (Player, { FeedbackInstruction }) -> ())
	sendFeedback = sender
end

function FeedbackService.send(player: Player, instructions: { FeedbackInstruction })
	if #instructions == 0 then
		return
	end

	feedbackSent += #instructions
	lastFeedback = table.clone(instructions)

	if sendFeedback ~= nil then
		sendFeedback(player, instructions)
	end
end

function FeedbackService.inspect()
	return {
		feedbackSent = feedbackSent,
		lastFeedback = lastFeedback,
	}
end

function FeedbackService.validate(): (boolean, string?)
	return true, nil
end

function FeedbackService.clear()
	feedbackSent = 0
	table.clear(lastFeedback)
	sendFeedback = nil
end

return FeedbackService
