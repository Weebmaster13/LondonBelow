local Framework = require(script.Parent.Framework)
local Logger = require(script.Parent.Logger)

local log = Logger.scope("Bootstrap")

log.info("Starting LondonBelow server")

local ok, err = pcall(function()
	Framework.initialize()
	Framework.start()
end)

if not ok then
	log.error("Server startup failed: %s", tostring(err))
	error(err)
end

log.info("LondonBelow server started")
