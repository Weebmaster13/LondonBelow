--!strict

local Types = require(script.Parent.RobloxGuiInstanceContractTypes)

local Catalog = {}

local common = {
	Name = Types.ValueKind.String, Visible = Types.ValueKind.Boolean, Active = Types.ValueKind.Boolean,
	AnchorPoint = Types.ValueKind.Vector2, Position = Types.ValueKind.UDim2, Size = Types.ValueKind.UDim2,
	AutomaticSize = Types.ValueKind.Enum, BackgroundColor3 = Types.ValueKind.Color3,
	BackgroundTransparency = Types.ValueKind.Number, BorderSizePixel = Types.ValueKind.Number,
	LayoutOrder = Types.ValueKind.Number, Rotation = Types.ValueKind.Number, ZIndex = Types.ValueKind.Number,
	ClipsDescendants = Types.ValueKind.Boolean, Interactable = Types.ValueKind.Boolean,
	SelectionOrder = Types.ValueKind.Number, Selectable = Types.ValueKind.Boolean,
}

local function extend(extra)
	local result = {}
	for key, value in pairs(common) do result[key] = value end
	for key, value in pairs(extra or {}) do result[key] = value end
	return table.freeze(result)
end

local classes = {
	ScreenGui = { parents = { PlayerGui = true }, children = "GuiObject", properties = table.freeze({ DisplayOrder = Types.ValueKind.Number, Enabled = Types.ValueKind.Boolean, IgnoreGuiInset = Types.ValueKind.Boolean, ResetOnSpawn = Types.ValueKind.Boolean, SafeAreaCompatibility = Types.ValueKind.Enum, ScreenInsets = Types.ValueKind.Enum, ZIndexBehavior = Types.ValueKind.Enum }) },
	Frame = { parents = { ScreenGui = true, GuiObject = true }, children = "GuiObjectOrDecorator", properties = extend({}) },
	CanvasGroup = { parents = { ScreenGui = true, GuiObject = true }, children = "GuiObjectOrDecorator", properties = extend({ GroupColor3 = Types.ValueKind.Color3, GroupTransparency = Types.ValueKind.Number }) },
	TextLabel = { parents = { ScreenGui = true, GuiObject = true }, children = "Decorator", properties = extend({ Text = Types.ValueKind.String, TextColor3 = Types.ValueKind.Color3, TextTransparency = Types.ValueKind.Number, TextSize = Types.ValueKind.Number, TextScaled = Types.ValueKind.Boolean, TextWrapped = Types.ValueKind.Boolean, TextXAlignment = Types.ValueKind.Enum, TextYAlignment = Types.ValueKind.Enum, FontFace = Types.ValueKind.String, RichText = Types.ValueKind.Boolean, MaxVisibleGraphemes = Types.ValueKind.Number }) },
	TextButton = { parents = { ScreenGui = true, GuiObject = true }, children = "Decorator", properties = extend({ Text = Types.ValueKind.String, TextColor3 = Types.ValueKind.Color3, TextSize = Types.ValueKind.Number, TextScaled = Types.ValueKind.Boolean, TextWrapped = Types.ValueKind.Boolean, FontFace = Types.ValueKind.String, AutoButtonColor = Types.ValueKind.Boolean, Modal = Types.ValueKind.Boolean, Selected = Types.ValueKind.Boolean }) },
	ImageLabel = { parents = { ScreenGui = true, GuiObject = true }, children = "Decorator", properties = extend({ Image = Types.ValueKind.AssetReference, ImageColor3 = Types.ValueKind.Color3, ImageTransparency = Types.ValueKind.Number, ScaleType = Types.ValueKind.Enum, SliceCenter = Types.ValueKind.Rect, TileSize = Types.ValueKind.UDim2 }) },
	ImageButton = { parents = { ScreenGui = true, GuiObject = true }, children = "Decorator", properties = extend({ Image = Types.ValueKind.AssetReference, ImageColor3 = Types.ValueKind.Color3, ImageTransparency = Types.ValueKind.Number, ScaleType = Types.ValueKind.Enum, AutoButtonColor = Types.ValueKind.Boolean, Modal = Types.ValueKind.Boolean, Selected = Types.ValueKind.Boolean }) },
	ScrollingFrame = { parents = { ScreenGui = true, GuiObject = true }, children = "GuiObjectOrDecorator", properties = extend({ AutomaticCanvasSize = Types.ValueKind.Enum, CanvasPosition = Types.ValueKind.Vector2, CanvasSize = Types.ValueKind.UDim2, ElasticBehavior = Types.ValueKind.Enum, ScrollBarImageColor3 = Types.ValueKind.Color3, ScrollBarThickness = Types.ValueKind.Number, ScrollingDirection = Types.ValueKind.Enum }) },
	ViewportFrame = { parents = { ScreenGui = true, GuiObject = true }, children = "ViewportContent", properties = extend({ Ambient = Types.ValueKind.Color3, ImageColor3 = Types.ValueKind.Color3, ImageTransparency = Types.ValueKind.Number, LightColor = Types.ValueKind.Color3, LightDirection = Types.ValueKind.Vector2 }) },
	UIListLayout = { parents = { GuiObject = true }, children = "None", properties = table.freeze({ FillDirection = Types.ValueKind.Enum, HorizontalAlignment = Types.ValueKind.Enum, VerticalAlignment = Types.ValueKind.Enum, Padding = Types.ValueKind.UDim, SortOrder = Types.ValueKind.Enum, Wraps = Types.ValueKind.Boolean }) },
	UIGridLayout = { parents = { GuiObject = true }, children = "None", properties = table.freeze({ CellPadding = Types.ValueKind.UDim2, CellSize = Types.ValueKind.UDim2, FillDirection = Types.ValueKind.Enum, FillDirectionMaxCells = Types.ValueKind.Number, HorizontalAlignment = Types.ValueKind.Enum, VerticalAlignment = Types.ValueKind.Enum, SortOrder = Types.ValueKind.Enum }) },
	UIPadding = { parents = { GuiObject = true }, children = "None", properties = table.freeze({ PaddingBottom = Types.ValueKind.UDim, PaddingLeft = Types.ValueKind.UDim, PaddingRight = Types.ValueKind.UDim, PaddingTop = Types.ValueKind.UDim }) },
	UICorner = { parents = { GuiObject = true }, children = "None", properties = table.freeze({ CornerRadius = Types.ValueKind.UDim }) },
	UIStroke = { parents = { GuiObject = true }, children = "None", properties = table.freeze({ ApplyStrokeMode = Types.ValueKind.Enum, Color = Types.ValueKind.Color3, Enabled = Types.ValueKind.Boolean, LineJoinMode = Types.ValueKind.Enum, Thickness = Types.ValueKind.Number, Transparency = Types.ValueKind.Number }) },
	UIGradient = { parents = { GuiObject = true }, children = "None", properties = table.freeze({ Color = Types.ValueKind.ColorSequence, Enabled = Types.ValueKind.Boolean, Offset = Types.ValueKind.Vector2, Rotation = Types.ValueKind.Number, Transparency = Types.ValueKind.NumberSequence }) },
	UIScale = { parents = { GuiObject = true }, children = "None", properties = table.freeze({ Scale = Types.ValueKind.Number }) },
	UIAspectRatioConstraint = { parents = { GuiObject = true }, children = "None", properties = table.freeze({ AspectRatio = Types.ValueKind.Number, AspectType = Types.ValueKind.Enum, DominantAxis = Types.ValueKind.Enum }) },
	UISizeConstraint = { parents = { GuiObject = true }, children = "None", properties = table.freeze({ MaxSize = Types.ValueKind.Vector2, MinSize = Types.ValueKind.Vector2 }) },
	UITextSizeConstraint = { parents = { TextLabel = true, TextButton = true }, children = "None", properties = table.freeze({ MaxTextSize = Types.ValueKind.Number, MinTextSize = Types.ValueKind.Number }) },
}

local forbidden = table.freeze({ Script = true, LocalScript = true, ModuleScript = true, RemoteEvent = true, RemoteFunction = true, BindableEvent = true, BindableFunction = true })

function Catalog.get(className: string) return classes[className] end
function Catalog.isSupported(className: string): boolean return classes[className] ~= nil end
function Catalog.isForbidden(className: string): boolean return forbidden[className] == true end
function Catalog.snapshot() return { schemaVersion = Types.SchemaVersion, classes = classes, forbiddenClasses = forbidden } end

return table.freeze(Catalog)
