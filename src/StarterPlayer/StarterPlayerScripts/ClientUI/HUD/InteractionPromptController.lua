--!strict
--[[
	Minimal reusable interaction prompt presenter.

	This is not final UI. It creates a clean prompt surface for testing focus and
	interaction flow while future London Below UI art is designed separately.
]]

local Players = game:GetService("Players")

local InteractionPromptController = {}

local localPlayer = Players.LocalPlayer
local gui: ScreenGui? = nil
local label: TextLabel? = nil
local currentFocus: any? = nil

local function ensureGui()
	if gui ~= nil and label ~= nil then
		return
	end

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local screen = Instance.new("ScreenGui")
	screen.Name = "LondonInteractionPrompt"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true

	local text = Instance.new("TextLabel")
	text.Name = "Prompt"
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Position = UDim2.fromScale(0.5, 0.62)
	text.Size = UDim2.fromOffset(340, 44)
	text.BackgroundTransparency = 0.35
	text.BackgroundColor3 = Color3.fromRGB(8, 10, 12)
	text.BorderSizePixel = 0
	text.TextColor3 = Color3.fromRGB(235, 235, 225)
	text.TextStrokeTransparency = 0.65
	text.Font = Enum.Font.GothamMedium
	text.TextSize = 18
	text.Visible = false
	text.Parent = screen

	screen.Parent = playerGui
	gui = screen
	label = text
end

function InteractionPromptController.initialize()
	ensureGui()
end

function InteractionPromptController.updateFocus(focus: any?)
	ensureGui()
	currentFocus = focus

	local text = label :: TextLabel

	if focus == nil or focus.interactionId == nil then
		text.Visible = false
		text.Text = ""
		return
	end

	text.Text = string.format("[E] %s", tostring(focus.prompt or "Interact"))
	text.Visible = true
end

function InteractionPromptController.getFocus()
	return currentFocus
end

function InteractionPromptController.shutdown()
	if gui ~= nil then
		gui:Destroy()
	end

	gui = nil
	label = nil
	currentFocus = nil
end

return InteractionPromptController
