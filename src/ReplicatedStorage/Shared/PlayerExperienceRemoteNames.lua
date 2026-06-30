--!strict
--[[
	Remote names for the Player Experience Foundation.

	All remotes are defined by server-side RemoteManager. Clients wait for these
	names and never create remotes themselves.
]]

local PlayerExperienceConfig = require(script.Parent.Parent.Config.PlayerExperienceConfig)

local PlayerExperienceRemoteNames = {}

PlayerExperienceRemoteNames.Namespace = PlayerExperienceConfig.RemoteNamespace
PlayerExperienceRemoteNames.Version = PlayerExperienceConfig.RemoteVersion

PlayerExperienceRemoteNames.ClientToServer = {
	RequestInteraction = "RequestInteraction",
	UpdateMovementState = "UpdateMovementState",
	RequestFocus = "RequestFocus",
}

PlayerExperienceRemoteNames.ServerToClient = {
	InteractionResult = "InteractionResult",
	FocusUpdated = "FocusUpdated",
	Feedback = "Feedback",
	MovementProfileUpdated = "MovementProfileUpdated",
}

return PlayerExperienceRemoteNames
