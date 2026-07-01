--!strict

local GameplayExecutionConfig = {
	DefaultMode = "DryRun",
	PhysicalMutationEnabled = false,
	MaxQueueSize = 180,
	MaxExecutionRecordHistory = 320,
	RecentExecutionLimit = 160,
	RecentFailureLimit = 80,
	MaxPayloadDepth = 4,
	MaxPayloadKeys = 80,
	DefaultExpirationSeconds = 20,
	ObjectLeaseSeconds = 8,
	CleanupIntervalSeconds = 5,
	AllowedExecutionKinds = {
		DoorOpen = true,
		DoorClose = true,
		DoorLockVisual = true,
		DoorUnlockVisual = true,
		ObjectStateChange = true,
		DrawerMove = true,
		CabinetMove = true,
		SwitchMove = true,
		LeverMove = true,
		PuzzlePanelFeedback = true,
		KeyPickupPresentation = true,
		ObjectiveMarkerPresentation = true,
		EnvironmentalObjectResponse = true,
		StudioBoundAdapter = true,
	},
	ApprovalRequiredKinds = {
		EnvironmentalObjectResponse = true,
		PuzzlePanelFeedback = true,
		ObjectiveMarkerPresentation = true,
	},
}

return GameplayExecutionConfig
