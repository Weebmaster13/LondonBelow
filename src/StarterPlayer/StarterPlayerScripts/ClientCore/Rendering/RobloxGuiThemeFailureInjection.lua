--!strict

local Injection = {}
local allowed = table.freeze({ Read = true, Apply = true, Rollback = true })
local pending = {}

function Injection.setForTest(stage: any, count: any): (boolean, string?)
	if type(stage) ~= "string" or not allowed[stage] then return false, "InvalidThemeFailureInjectionStage" end
	if type(count) ~= "number" or count % 1 ~= 0 or count < 0 or count > 32 then return false, "InvalidThemeFailureInjectionCount" end
	pending[stage] = count; return true, nil
end
function Injection.consume(stage: string): boolean
	local count = pending[stage] or 0; if count <= 0 then return false end
	pending[stage] = count - 1; return true
end
function Injection.snapshot() return table.clone(pending) end
function Injection.reset() pending = {} end

return Injection
