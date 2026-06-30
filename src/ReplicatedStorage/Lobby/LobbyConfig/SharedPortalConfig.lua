--!strict
-- Shared configuration for cinematic lobby chapter-entry portals.

local SharedPortalConfig = {}

SharedPortalConfig.DefaultPortalId = "main_carriage"
SharedPortalConfig.RemoteNamespace = "LobbyPortal"
SharedPortalConfig.MaxPortalOccupants = 4
SharedPortalConfig.CountdownSeconds = 6
SharedPortalConfig.CooldownSeconds = 5
SharedPortalConfig.RemoteRateLimitPerSecond = 6
SharedPortalConfig.AutoCreateSoloPartyOnBoard = true

SharedPortalConfig.PortalTypes = {
	VictorianCarriage = "VictorianCarriage",
	FogGate = "FogGate",
	ChapterDoor = "ChapterDoor",
}

SharedPortalConfig.PortalStates = {
	Idle = "Idle",
	WaitingForParty = "WaitingForParty",
	Boarding = "Boarding",
	ReadyToLaunch = "ReadyToLaunch",
	Countdown = "Countdown",
	Transitioning = "Transitioning",
	Launching = "Launching",
	Failed = "Failed",
	Cooldown = "Cooldown",
}

SharedPortalConfig.AtmosphereCues = {
	CarriageLanternFlicker = "CarriageLanternFlicker",
	DoorClosing = "DoorClosing",
	FogThickening = "FogThickening",
	HorseSound = "HorseSound",
	Heartbeat = "Heartbeat",
	Whisper = "Whisper",
	ScreenFade = "ScreenFade",
	RainMuffling = "RainMuffling",
	DistantMonsterGlimpse = "DistantMonsterGlimpse",
	ChapterTransition = "ChapterTransition",
}

SharedPortalConfig.Portals = {
	main_carriage = {
		id = "main_carriage",
		displayName = "Black Victorian Carriage",
		portalType = SharedPortalConfig.PortalTypes.VictorianCarriage,
		chapterId = "chapter_1",
		enabled = true,
		maxPlayers = 4,
		countdownSeconds = SharedPortalConfig.CountdownSeconds,
		cooldownSeconds = SharedPortalConfig.CooldownSeconds,
		cinematicSequence = {
			SharedPortalConfig.AtmosphereCues.CarriageLanternFlicker,
			SharedPortalConfig.AtmosphereCues.HorseSound,
			SharedPortalConfig.AtmosphereCues.DoorClosing,
			SharedPortalConfig.AtmosphereCues.FogThickening,
			SharedPortalConfig.AtmosphereCues.Heartbeat,
			SharedPortalConfig.AtmosphereCues.Whisper,
			SharedPortalConfig.AtmosphereCues.RainMuffling,
			SharedPortalConfig.AtmosphereCues.ScreenFade,
			SharedPortalConfig.AtmosphereCues.ChapterTransition,
		},
	},
	fog_gate = {
		id = "fog_gate",
		displayName = "Fog Gate",
		portalType = SharedPortalConfig.PortalTypes.FogGate,
		chapterId = "chapter_1",
		enabled = false,
		maxPlayers = 4,
		countdownSeconds = SharedPortalConfig.CountdownSeconds,
		cooldownSeconds = SharedPortalConfig.CooldownSeconds,
		cinematicSequence = {
			SharedPortalConfig.AtmosphereCues.FogThickening,
			SharedPortalConfig.AtmosphereCues.Whisper,
			SharedPortalConfig.AtmosphereCues.DistantMonsterGlimpse,
			SharedPortalConfig.AtmosphereCues.ScreenFade,
			SharedPortalConfig.AtmosphereCues.ChapterTransition,
		},
	},
	chapter_door = {
		id = "chapter_door",
		displayName = "Old Building Door",
		portalType = SharedPortalConfig.PortalTypes.ChapterDoor,
		chapterId = "chapter_1",
		enabled = false,
		maxPlayers = 4,
		countdownSeconds = SharedPortalConfig.CountdownSeconds,
		cooldownSeconds = SharedPortalConfig.CooldownSeconds,
		cinematicSequence = {
			SharedPortalConfig.AtmosphereCues.DoorClosing,
			SharedPortalConfig.AtmosphereCues.Heartbeat,
			SharedPortalConfig.AtmosphereCues.Whisper,
			SharedPortalConfig.AtmosphereCues.ScreenFade,
			SharedPortalConfig.AtmosphereCues.ChapterTransition,
		},
	},
}

SharedPortalConfig.ClientDebug = {
	printStateUpdates = true,
	printErrors = true,
	printAtmosphereCues = true,
}

return SharedPortalConfig
