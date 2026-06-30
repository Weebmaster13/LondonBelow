--!strict
--[[
	Server-facing type bridge for the Interaction Runtime.

	Shared payload contracts live in ReplicatedStorage so clients and server
	agree on shape. This module gives server interaction code a stable local
	import path and room for future server-only interaction contracts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedTypes = require(ReplicatedStorage.Shared.PlayerExperienceTypes)

local InteractionTypes = {}

export type InteractionKind = SharedTypes.InteractionKind
export type InteractionDescriptor = SharedTypes.InteractionDescriptor
export type InteractionRequest = SharedTypes.InteractionRequest
export type InteractionResult = SharedTypes.InteractionResult
export type FeedbackInstruction = SharedTypes.FeedbackInstruction

InteractionTypes.ResultCode = SharedTypes.ResultCode

return InteractionTypes
