--!strict
--[[
	Client input collector for movement and interaction requests.

	Owns local key/button interpretation. It does not set authoritative movement
	truth, complete interactions, or decide object state.
]]

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local PlayerInputController = {}

type Network = {
	fire: (string, any) -> (),
	names: () -> any,
}

local network: Network? = nil
local sprinting = false
local crouching = false
local jumping = false
local requestInteract: (() -> ())? = nil
local connections: { RBXScriptConnection } = {}

local function names()
	return (network :: Network).names().ClientToServer
end

local function publishMovement()
	if network == nil then
		return
	end

	(network :: Network).fire(names().UpdateMovementState, {
		sprinting = sprinting,
		crouching = crouching,
		jumping = jumping,
	})
end

local function bindAction(
	name: string,
	callback: (
		string,
		Enum.UserInputState,
		InputObject
	) -> Enum.ContextActionResult,
	...: Enum.KeyCode
)
	ContextActionService:BindAction(name, callback, false, ...)
end

function PlayerInputController.initialize(networkAdapter: Network, interactCallback: () -> ())
	network = networkAdapter
	requestInteract = interactCallback

	bindAction("LondonSprint", function(_, state)
		sprinting = state == Enum.UserInputState.Begin
		publishMovement()
		return Enum.ContextActionResult.Pass
	end, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)

	bindAction("LondonCrouch", function(_, state)
		if state == Enum.UserInputState.Begin then
			crouching = not crouching
			publishMovement()
		end

		return Enum.ContextActionResult.Sink
	end, Enum.KeyCode.C, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonB)

	bindAction("LondonInteract", function(_, state)
		if state == Enum.UserInputState.Begin and requestInteract ~= nil then
			(requestInteract :: () -> ())()
		end

		return Enum.ContextActionResult.Sink
	end, Enum.KeyCode.E, Enum.KeyCode.ButtonX)

	table.insert(
		connections,
		UserInputService.JumpRequest:Connect(function()
			jumping = true
			publishMovement()
			task.delay(0.2, function()
				jumping = false
				publishMovement()
			end)
		end)
	)
end

function PlayerInputController.shutdown()
	ContextActionService:UnbindAction("LondonSprint")
	ContextActionService:UnbindAction("LondonCrouch")
	ContextActionService:UnbindAction("LondonInteract")

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	table.clear(connections)
	network = nil
	requestInteract = nil
end

return PlayerInputController
