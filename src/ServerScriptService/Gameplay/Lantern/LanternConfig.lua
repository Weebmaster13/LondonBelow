--!strict

local LanternConfig = {}

LanternConfig.RemoteNamespace = "Lantern"
LanternConfig.RemoteVersion = 1
LanternConfig.RemoteRateLimitPerSecond = 6
LanternConfig.ClientToServer = {
	RequestToggle = "RequestToggle",
}
LanternConfig.ServerToClient = {
	StateUpdated = "StateUpdated",
	RequestResult = "RequestResult",
}

LanternConfig.DefaultBattery = 1
LanternConfig.LowBatteryThreshold = 0.2
LanternConfig.BatteryDrainPerToggle = 0.005
LanternConfig.OveruseIncrement = 0.16
LanternConfig.OveruseDecay = 0.04
LanternConfig.OveruseThreshold = 0.75
LanternConfig.MinToggleIntervalSeconds = 0.2
LanternConfig.ObservationCooldownSeconds = 0.75

return LanternConfig
