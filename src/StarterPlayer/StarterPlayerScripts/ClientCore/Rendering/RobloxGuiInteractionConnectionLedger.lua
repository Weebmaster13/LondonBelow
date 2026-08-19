--!strict

local Ledger = {}
local connections = {} :: { RBXScriptConnection }
local connectedTotal = 0
local disconnectedTotal = 0

function Ledger.add(connection: RBXScriptConnection)
	connections[#connections + 1] = connection
	connectedTotal += 1
end

function Ledger.disconnectAll(): number
	local disconnected = 0
	for _, connection in ipairs(connections) do
		if connection.Connected then
			connection:Disconnect()
		end
		disconnected += 1
	end
	disconnectedTotal += disconnected
	table.clear(connections)
	return disconnected
end

function Ledger.inspect()
	return {
		active = #connections,
		connectedTotal = connectedTotal,
		disconnectedTotal = disconnectedTotal,
		balanced = connectedTotal - disconnectedTotal == #connections,
	}
end

function Ledger.reset()
	Ledger.disconnectAll()
	connectedTotal = 0
	disconnectedTotal = 0
end

return Ledger
