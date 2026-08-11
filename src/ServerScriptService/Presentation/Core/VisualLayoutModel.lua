--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Layout = {}

local validAnchor = {
	TopLeft = true,
	TopCenter = true,
	TopRight = true,
	Center = true,
	BottomLeft = true,
	BottomCenter = true,
	BottomRight = true,
	LeftCenter = true,
	RightCenter = true,
}

function Layout.normalize(value: any)
	local layout = Serialization.deepCopy(value or {})
	layout.mode = layout.mode or Types.VisualLayoutMode.AnchorIntent
	layout.anchor = layout.anchor or "Center"
	return layout
end

function Layout.validate(value: any): (boolean, string?)
	if type(value) ~= "table" then
		return false, "layout must be a table"
	end
	if not Types.isVisualLayoutMode(value.mode or Types.VisualLayoutMode.AnchorIntent) then
		return false, "invalid layout mode"
	end
	if value.anchor ~= nil and not validAnchor[value.anchor] then
		return false, "invalid anchor"
	end
	return true, nil
end

return Layout
