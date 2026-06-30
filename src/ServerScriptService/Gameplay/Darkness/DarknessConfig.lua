--!strict

local DarknessConfig = {}

DarknessConfig.ExposureIncreasePerSecond = 0.08
DarknessConfig.ExposureDecayPerSecond = 0.12
DarknessConfig.DirectorRequestThreshold = 0.35
DarknessConfig.HighExposureThreshold = 0.7
DarknessConfig.MaxExposure = 1
DarknessConfig.UpdateIntervalSeconds = 1
DarknessConfig.RecentEventLimit = 100

return DarknessConfig
