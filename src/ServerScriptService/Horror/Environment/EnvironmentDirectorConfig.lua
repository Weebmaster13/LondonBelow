--!strict

local EnvironmentDirectorConfig = {}

EnvironmentDirectorConfig.MemoryLimit = 80
EnvironmentDirectorConfig.SelectionHistoryLimit = 60
EnvironmentDirectorConfig.DecisionHistoryLimit = 60
EnvironmentDirectorConfig.MaxExecutionMetadataKeys = 24
EnvironmentDirectorConfig.MaxPayloadDepth = 4
EnvironmentDirectorConfig.ZonePressureTtlSeconds = 300
EnvironmentDirectorConfig.DefaultZoneId = "unknown"
EnvironmentDirectorConfig.DefaultZoneKind = "Unknown"
EnvironmentDirectorConfig.DefaultCooldownSeconds = 20
EnvironmentDirectorConfig.DefaultZoneCooldownSeconds = 30
EnvironmentDirectorConfig.MaxIntensity = 1
EnvironmentDirectorConfig.ReleaseThreshold = -0.25
EnvironmentDirectorConfig.WatchfulThreshold = 0.2
EnvironmentDirectorConfig.UneasyThreshold = 0.45
EnvironmentDirectorConfig.OppressiveThreshold = 0.7
EnvironmentDirectorConfig.HostileThreshold = 0.9

EnvironmentDirectorConfig.SelfCheckZoneId = "self-check-zone"

return EnvironmentDirectorConfig
