--!strict
--[[
	Presentation-only feedback hook receiver.

	Owns local debug handling for audio, visual, prompt, haptic, and screen
	effect instructions. It does not decide when feedback is allowed.
]]

local HapticService = game:GetService("HapticService")

local FeedbackController = {}

function FeedbackController.play(payload: any)
	if type(payload) ~= "table" or type(payload.instructions) ~= "table" then
		return
	end

	for _, instruction in ipairs(payload.instructions) do
		if type(instruction) ~= "table" then
			continue
		end

		print("[LondonBelow][Feedback]", instruction.kind, instruction.id, instruction.intensity)

		if
			instruction.kind == "Haptics"
			and HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1)
		then
			HapticService:SetMotor(
				Enum.UserInputType.Gamepad1,
				Enum.VibrationMotor.Small,
				instruction.intensity or 0
			)
			task.delay(instruction.duration or 0.15, function()
				HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
			end)
		end
	end
end

return FeedbackController
