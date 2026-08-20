--!strict

local RenderingCatalog = require(script.Parent.RobloxGuiRenderingCatalog)

local Catalog = {}
local tweenable = table.freeze({
	AnchorPoint = true,
	Position = true,
	Size = true,
	BackgroundColor3 = true,
	BackgroundTransparency = true,
	Rotation = true,
	TextColor3 = true,
	TextTransparency = true,
	TextSize = true,
	ImageColor3 = true,
	ImageTransparency = true,
	GroupColor3 = true,
	GroupTransparency = true,
	CanvasPosition = true,
	ScrollBarImageColor3 = true,
	Transparency = true,
	Thickness = true,
	Color = true,
	Offset = true,
	Scale = true,
})

function Catalog.supports(className: string, propertyName: string): boolean
	return tweenable[propertyName] == true
		and RenderingCatalog.supportsProperty(className, propertyName)
end

function Catalog.snapshot()
	return tweenable
end

return table.freeze(Catalog)
