# Studio Execution Path

Path evaluated: Rojo builds `default.project.json` into a temporary local place artifact, then the existing Studio automation bridge checks whether a supported non-interactive runner/capture path exists. Result: executionBlocked. Studio launch and Play/Run were not attempted because no supported capture path exists.
