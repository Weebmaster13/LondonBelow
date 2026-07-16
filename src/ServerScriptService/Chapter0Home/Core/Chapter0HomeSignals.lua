--!strict

local Types = require(script.Parent.Chapter0HomeTypes)

return {
	Started = "Chapter0Home.Started",
	Reset = "Chapter0Home.Reset",
	InteractionRecorded = "Chapter0Home.InteractionRecorded",
	AtmosphericFeedbackRecorded = "Chapter0Home.AtmosphericFeedbackRecorded",
	EnvironmentalReactionApplied = "Chapter0Home.EnvironmentalReactionApplied",
	AtmosphericProgressionAdvanced = "Chapter0Home.AtmosphericProgressionAdvanced",
	ObservationFactPublished = Types.ChapterObservationFactPublishedSignalName,
	Completed = "Chapter0Home.Completed",
}
