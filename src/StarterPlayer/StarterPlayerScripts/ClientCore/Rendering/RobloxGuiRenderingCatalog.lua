--!strict

local Catalog = {}

local common = table.freeze({
	Name = true,
	Visible = true,
	Active = true,
	AnchorPoint = true,
	Position = true,
	Size = true,
	AutomaticSize = true,
	BackgroundColor3 = true,
	BackgroundTransparency = true,
	BorderSizePixel = true,
	LayoutOrder = true,
	Rotation = true,
	ZIndex = true,
	ClipsDescendants = true,
	Interactable = true,
	SelectionOrder = true,
	Selectable = true,
})

local function extend(extra: { [string]: boolean }): { [string]: boolean }
	local result = table.clone(common)
	for key in pairs(extra) do
		result[key] = true
	end
	return table.freeze(result)
end

local classes = table.freeze({
	ScreenGui = table.freeze({
		DisplayOrder = true,
		Enabled = true,
		IgnoreGuiInset = true,
		ResetOnSpawn = true,
		SafeAreaCompatibility = true,
		ScreenInsets = true,
		ZIndexBehavior = true,
	}),
	Frame = extend({}),
	CanvasGroup = extend({ GroupColor3 = true, GroupTransparency = true }),
	TextLabel = extend({
		Text = true,
		TextColor3 = true,
		TextTransparency = true,
		TextSize = true,
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = true,
		TextYAlignment = true,
		FontFace = true,
		RichText = true,
		MaxVisibleGraphemes = true,
	}),
	TextButton = extend({
		Text = true,
		TextColor3 = true,
		TextSize = true,
		TextScaled = true,
		TextWrapped = true,
		FontFace = true,
		AutoButtonColor = true,
		Modal = true,
		Selected = true,
	}),
	ImageLabel = extend({
		Image = true,
		ImageColor3 = true,
		ImageTransparency = true,
		ScaleType = true,
		SliceCenter = true,
		TileSize = true,
	}),
	ImageButton = extend({
		Image = true,
		ImageColor3 = true,
		ImageTransparency = true,
		ScaleType = true,
		AutoButtonColor = true,
		Modal = true,
		Selected = true,
	}),
	ScrollingFrame = extend({
		AutomaticCanvasSize = true,
		CanvasPosition = true,
		CanvasSize = true,
		ElasticBehavior = true,
		ScrollBarImageColor3 = true,
		ScrollBarThickness = true,
		ScrollingDirection = true,
	}),
	ViewportFrame = extend({
		Ambient = true,
		ImageColor3 = true,
		ImageTransparency = true,
		LightColor = true,
		LightDirection = true,
	}),
	UIListLayout = table.freeze({
		FillDirection = true,
		HorizontalAlignment = true,
		VerticalAlignment = true,
		Padding = true,
		SortOrder = true,
		Wraps = true,
	}),
	UIGridLayout = table.freeze({
		CellPadding = true,
		CellSize = true,
		FillDirection = true,
		FillDirectionMaxCells = true,
		HorizontalAlignment = true,
		VerticalAlignment = true,
		SortOrder = true,
	}),
	UIPadding = table.freeze({
		PaddingBottom = true,
		PaddingLeft = true,
		PaddingRight = true,
		PaddingTop = true,
	}),
	UICorner = table.freeze({ CornerRadius = true }),
	UIStroke = table.freeze({
		ApplyStrokeMode = true,
		Color = true,
		Enabled = true,
		LineJoinMode = true,
		Thickness = true,
		Transparency = true,
	}),
	UIGradient = table.freeze({
		Color = true,
		Enabled = true,
		Offset = true,
		Rotation = true,
		Transparency = true,
	}),
	UIScale = table.freeze({ Scale = true }),
	UIAspectRatioConstraint = table.freeze({
		AspectRatio = true,
		AspectType = true,
		DominantAxis = true,
	}),
	UISizeConstraint = table.freeze({ MaxSize = true, MinSize = true }),
	UITextSizeConstraint = table.freeze({ MaxTextSize = true, MinTextSize = true }),
})

function Catalog.supportsClass(className: string): boolean
	return classes[className] ~= nil
end

function Catalog.supportsProperty(className: string, propertyName: string): boolean
	local properties = classes[className]
	return properties ~= nil and properties[propertyName] == true
end

function Catalog.snapshot()
	return classes
end

return table.freeze(Catalog)
