--!strict

local Workspace = game:GetService("Workspace")

local RenderingRuntime = require(script.Parent.Parent.Rendering.RobloxGuiRenderingRuntime)
local InteractionRuntime = require(script.Parent.Parent.Rendering.RobloxGuiInteractionRuntime)

local ROOT_NAME = "LondonBelow_Phase196_BlackwaterDescent"
local CONTRACT_ID = "blackwater-descent-player-experience"
local THEME_ID = "blackwater-house"
local JOURNAL_ACTION_ID = "blackwater.toggle-case-file"
local revision = 0
local rootConnections: { RBXScriptConnection } = {}
local renderScheduled = false
local journalOpen = false
local currentRoot = nil :: Instance?

local function color(r: number, g: number, b: number)
	return { kind = "Color3RGB", r = r, g = g, b = b }
end

local function size(xScale: number, xOffset: number, yScale: number, yOffset: number)
	return { kind = "UDim2", xScale = xScale, xOffset = xOffset, yScale = yScale, yOffset = yOffset }
end

local function accessibility(role: string, label: string, liveRegion: string?)
	return { role = role, label = label, focusable = false, liveRegion = liveRegion or "Off" }
end

local function node(
	nodeId: string,
	className: string,
	parentNodeId: string,
	properties: any,
	metadata: any?
)
	return {
		nodeId = nodeId,
		className = className,
		parentNodeId = parentNodeId,
		properties = properties,
		accessibility = metadata and metadata.accessibility or {},
		responsive = metadata and metadata.responsive or nil,
		tags = metadata and metadata.tags or nil,
	}
end

local function textAttribute(root: Instance, name: string, fallback: string): string
	local value = root:GetAttribute(name)
	return if type(value) == "string" and value ~= "" then value else fallback
end

local function buildContract(root: Instance, targetRevision: number)
	local objectiveNumber = tonumber(root:GetAttribute("ObjectiveNumber")) or 1
	local objectiveTotal = tonumber(root:GetAttribute("ObjectiveTotal")) or 9
	local progress = math.clamp(tonumber(root:GetAttribute("Progress")) or 0, 0, 1)
	local pressure = math.clamp(tonumber(root:GetAttribute("Pressure")) or 0, 0, 1)
	local narrative =
		textAttribute(root, "NarrativeText", "The street is waiting. Light the lantern.")
	local bailiffState = textAttribute(root, "BailiffState", "Dormant")
	local audioState = textAttribute(root, "AudioState", "quiet")
	local streetAudioCaption =
		textAttribute(root, "StreetAudioCaption", "Rain falls across wet stone.")
	local bailiffAudioCaption = textAttribute(root, "BailiffAudioCaption", "")
	local audioExecutionSnapshot = textAttribute(root, "AudioExecutionSnapshot", "ordinary_london")
	local captionText = if bailiffAudioCaption ~= ""
		then bailiffAudioCaption
		else streetAudioCaption
	local endingText = textAttribute(root, "EndingText", "")
	return {
		schemaVersion = "1.0.0",
		contractId = CONTRACT_ID,
		targetRevision = targetRevision,
		rootNodeId = "blackwaterHud",
		nodes = {
			node("blackwaterHud", "ScreenGui", "PlayerGui", {
				DisplayOrder = 30,
				IgnoreGuiInset = false,
				ResetOnSpawn = false,
				ZIndexBehavior = "Enum.ZIndexBehavior.Sibling",
			}, {
				accessibility = accessibility(
					"Application",
					"Blackwater Descent chapter interface"
				),
			}),
			node("pressureVignette", "Frame", "blackwaterHud", {
				Size = size(1, 0, 1, 0),
				BackgroundColor3 = color(42, 0, 7),
				BackgroundTransparency = 1 - pressure * 0.16,
				BorderSizePixel = 0,
				ZIndex = 1,
			}, {
				accessibility = accessibility("Presentation", "Chapter danger pressure"),
				responsive = { policy = "SafeArea" },
				tags = { "pressure", "horror-presentation" },
			}),
			node("objectivePanel", "CanvasGroup", "blackwaterHud", {
				AnchorPoint = { kind = "Vector2", x = 0.5, y = 0 },
				Position = size(0.5, 0, 0.035, 0),
				Size = size(1, -32, 0, 160),
				BackgroundColor3 = color(10, 12, 15),
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0,
				GroupTransparency = 0.28,
				ZIndex = 10,
			}, {
				accessibility = accessibility("Region", "Current chapter objective", "Polite"),
				responsive = { policy = "SafeArea" },
				tags = { "objective", "chapter-hud" },
			}),
			node("panelConstraint", "UISizeConstraint", "objectivePanel", {
				MaxSize = { kind = "Vector2", x = 720, y = 160 },
				MinSize = { kind = "Vector2", x = 288, y = 160 },
			}),
			node(
				"panelCorner",
				"UICorner",
				"objectivePanel",
				{ CornerRadius = { kind = "UDim", scale = 0, offset = 9 } }
			),
			node(
				"panelStroke",
				"UIStroke",
				"objectivePanel",
				{ Color = color(138, 102, 58), Transparency = 0.2, Thickness = 1.5 }
			),
			node("chapterTitle", "TextLabel", "objectivePanel", {
				BackgroundTransparency = 1,
				Position = size(0, 18, 0, 9),
				Size = size(0.7, -18, 0, 22),
				FontFace = "Gotham",
				Text = { kind = "LocalizationReference", key = "blackwater.title" },
				TextSize = 14,
				TextXAlignment = "Enum.TextXAlignment.Left",
				TextColor3 = color(190, 154, 104),
				ZIndex = 11,
			}, { accessibility = accessibility("Heading", "The Blackwater Descent") }),
			node("threatState", "TextLabel", "objectivePanel", {
				BackgroundTransparency = 1,
				Position = size(0.7, 0, 0, 9),
				Size = size(0.3, -18, 0, 22),
				FontFace = "Gotham",
				Text = textAttribute(root, "ThreatText", "QUIET"),
				TextSize = 13,
				TextXAlignment = "Enum.TextXAlignment.Right",
				TextColor3 = color(158, 38, 48),
				ZIndex = 11,
			}, {
				accessibility = accessibility(
					"Status",
					"Threat level " .. textAttribute(root, "ThreatText", "quiet"),
					"Assertive"
				),
			}),
			node("bailiffState", "TextLabel", "objectivePanel", {
				BackgroundTransparency = 1,
				Position = size(0.7, 0, 0, 30),
				Size = size(0.3, -18, 0, 18),
				FontFace = "Gotham",
				Text = bailiffState .. " / " .. audioState,
				TextSize = 11,
				TextXAlignment = "Enum.TextXAlignment.Right",
				TextColor3 = color(149, 126, 92),
				ZIndex = 11,
			}, {
				accessibility = accessibility(
					"Status",
					"Blackwater pressure state "
						.. bailiffState
						.. " and audio state "
						.. audioState,
					"Polite"
				),
			}),
			node("objectiveText", "TextLabel", "objectivePanel", {
				BackgroundTransparency = 1,
				Position = size(0, 18, 0, 34),
				Size = size(1, -36, 0, 38),
				FontFace = "Gotham",
				Text = textAttribute(root, "ObjectiveText", "Listen to the silence."),
				TextScaled = true,
				TextWrapped = true,
				TextXAlignment = "Enum.TextXAlignment.Left",
				TextColor3 = color(236, 231, 218),
				ZIndex = 11,
			}, {
				accessibility = accessibility(
					"Status",
					textAttribute(root, "ObjectiveText", "Current objective"),
					"Polite"
				),
				responsive = { policy = "AdaptiveText" },
			}),
			node(
				"objectiveTextConstraint",
				"UITextSizeConstraint",
				"objectiveText",
				{ MinTextSize = 13, MaxTextSize = 21 }
			),
			node("narrativeText", "TextLabel", "objectivePanel", {
				BackgroundTransparency = 1,
				Position = size(0, 18, 0, 76),
				Size = size(1, -178, 0, 34),
				FontFace = "Gotham",
				Text = narrative,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = "Enum.TextXAlignment.Left",
				TextColor3 = color(174, 177, 176),
				ZIndex = 11,
			}, {
				accessibility = accessibility("Narrative", narrative, "Polite"),
				responsive = { policy = "AdaptiveText" },
			}),
			node("streetAudioCaption", "TextLabel", "objectivePanel", {
				BackgroundTransparency = 1,
				Position = size(0, 18, 0, 111),
				Size = size(1, -36, 0, 18),
				FontFace = "Gotham",
				Text = captionText,
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = "Enum.TextXAlignment.Left",
				TextColor3 = color(149, 126, 92),
				ZIndex = 11,
			}, {
				accessibility = accessibility(
					"Status",
					captionText .. " Mix " .. audioExecutionSnapshot,
					"Polite"
				),
				responsive = { policy = "AdaptiveText" },
			}),
			node("caseFileButton", "TextButton", "objectivePanel", {
				Position = size(1, -140, 0, 77),
				Size = size(0, 122, 0, 30),
				BackgroundColor3 = color(44, 36, 28),
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				FontFace = "Gotham",
				Text = if journalOpen then "CLOSE FILE" else "CASE FILE",
				TextColor3 = color(210, 181, 137),
				TextSize = 13,
				AutoButtonColor = true,
				SelectionOrder = 1,
				ZIndex = 12,
			}, {
				accessibility = {
					role = "Button",
					label = if journalOpen
						then "Close Blackwater case file"
						else "Open Blackwater case file",
					description = "Shows discoveries and chapter relics",
					focusable = true,
					actionId = JOURNAL_ACTION_ID,
					disabled = false,
					selectionOrder = 1,
					liveRegion = "Off",
				},
				tags = { "case-file", "presentation-action" },
			}),
			node(
				"caseFileCorner",
				"UICorner",
				"caseFileButton",
				{ CornerRadius = { kind = "UDim", scale = 0, offset = 6 } }
			),
			node("inventoryText", "TextLabel", "objectivePanel", {
				BackgroundTransparency = 1,
				Position = size(0, 18, 1, -42),
				Size = size(0.72, -18, 0, 18),
				FontFace = "Gotham",
				Text = textAttribute(root, "InventoryText", "No chapter relics"),
				TextSize = 12,
				TextXAlignment = "Enum.TextXAlignment.Left",
				TextColor3 = color(149, 126, 92),
				ZIndex = 11,
			}, {
				accessibility = accessibility(
					"Status",
					"Chapter inventory: "
						.. textAttribute(root, "InventoryText", "No chapter relics")
				),
			}),
			node("progressText", "TextLabel", "objectivePanel", {
				BackgroundTransparency = 1,
				Position = size(0.72, 0, 1, -42),
				Size = size(0.28, -18, 0, 18),
				FontFace = "Gotham",
				Text = string.format("OBJECTIVE %d / %d", objectiveNumber, objectiveTotal),
				TextSize = 12,
				TextXAlignment = "Enum.TextXAlignment.Right",
				TextColor3 = color(149, 126, 92),
				ZIndex = 11,
			}, {
				accessibility = accessibility(
					"Status",
					string.format("Objective %d of %d", objectiveNumber, objectiveTotal)
				),
			}),
			node("progressBack", "Frame", "objectivePanel", {
				Position = size(0, 18, 1, -15),
				Size = size(1, -36, 0, 5),
				BackgroundColor3 = color(42, 44, 48),
				BorderSizePixel = 0,
				ZIndex = 11,
			}),
			node("progressFill", "Frame", "progressBack", {
				Size = size(progress, 0, 1, 0),
				BackgroundColor3 = color(144, 25, 34),
				BorderSizePixel = 0,
				ZIndex = 12,
			}, {
				accessibility = accessibility(
					"ProgressBar",
					string.format("Chapter progress %d percent", math.floor(progress * 100 + 0.5))
				),
			}),
			node("caseFilePanel", "Frame", "blackwaterHud", {
				AnchorPoint = { kind = "Vector2", x = 0.5, y = 0 },
				Position = size(0.5, 0, 0.035, 172),
				Size = size(1, -32, 0, 260),
				BackgroundColor3 = color(13, 14, 16),
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				Visible = journalOpen,
				ZIndex = 20,
			}, {
				accessibility = accessibility(
					"Region",
					"Blackwater investigation case file",
					if journalOpen then "Polite" else "Off"
				),
				responsive = { policy = "SafeArea" },
				tags = { "case-file", "investigation" },
			}),
			node("caseFileConstraint", "UISizeConstraint", "caseFilePanel", {
				MaxSize = { kind = "Vector2", x = 720, y = 260 },
				MinSize = { kind = "Vector2", x = 288, y = 220 },
			}),
			node(
				"caseFilePanelCorner",
				"UICorner",
				"caseFilePanel",
				{ CornerRadius = { kind = "UDim", scale = 0, offset = 9 } }
			),
			node(
				"caseFilePanelStroke",
				"UIStroke",
				"caseFilePanel",
				{ Color = color(98, 76, 48), Transparency = 0.25, Thickness = 1.25 }
			),
			node("caseFileTitle", "TextLabel", "caseFilePanel", {
				BackgroundTransparency = 1,
				Position = size(0, 18, 0, 12),
				Size = size(1, -36, 0, 24),
				FontFace = "Gotham",
				Text = "BLACKWATER CASE FILE",
				TextColor3 = color(190, 154, 104),
				TextSize = 16,
				TextXAlignment = "Enum.TextXAlignment.Left",
				ZIndex = 21,
			}, { accessibility = accessibility("Heading", "Blackwater Case File") }),
			node("caseFileRelics", "TextLabel", "caseFilePanel", {
				BackgroundTransparency = 1,
				Position = size(0, 18, 0, 42),
				Size = size(1, -36, 0, 22),
				FontFace = "Gotham",
				Text = "RELICS  •  " .. textAttribute(root, "InventoryText", "No chapter relics"),
				TextColor3 = color(149, 126, 92),
				TextSize = 12,
				TextXAlignment = "Enum.TextXAlignment.Left",
				ZIndex = 21,
			}, {
				accessibility = accessibility(
					"Status",
					"Relics: " .. textAttribute(root, "InventoryText", "No chapter relics")
				),
			}),
			node("caseFileDiscoveries", "TextLabel", "caseFilePanel", {
				BackgroundTransparency = 1,
				Position = size(0, 18, 0, 70),
				Size = size(1, -36, 1, -84),
				FontFace = "Gotham",
				Text = textAttribute(root, "DiscoveryLog", "• No discoveries recorded."),
				TextColor3 = color(214, 210, 198),
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = "Enum.TextXAlignment.Left",
				TextYAlignment = "Enum.TextYAlignment.Top",
				ZIndex = 21,
			}, {
				accessibility = accessibility(
					"Document",
					textAttribute(root, "DiscoveryLog", "No discoveries recorded"),
					"Polite"
				),
				responsive = { policy = "AdaptiveText" },
			}),
			node("caseFileEnding", "TextLabel", "caseFilePanel", {
				BackgroundTransparency = 1,
				Position = size(0, 18, 1, -30),
				Size = size(1, -36, 0, 18),
				FontFace = "Gotham",
				Text = if endingText ~= "" then endingText else "ENDING  •  undecided",
				TextColor3 = color(190, 154, 104),
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = "Enum.TextXAlignment.Left",
				ZIndex = 21,
			}, {
				accessibility = accessibility(
					"Status",
					if endingText ~= "" then endingText else "Ending undecided",
					"Polite"
				),
			}),
		},
	}
end

local function applyTheme(targetRevision: number)
	return RenderingRuntime.applyTheme({
		schemaVersion = "1.0.0",
		contractId = CONTRACT_ID,
		targetRevision = targetRevision,
		themeId = THEME_ID,
		themeRevision = 1,
		nodes = {
			{
				nodeId = "objectivePanel",
				styles = {
					BackgroundColor3 = "surface.deep",
					BackgroundTransparency = "surface.transparency",
				},
			},
			{ nodeId = "chapterTitle", styles = { TextColor3 = "text.brass" } },
			{ nodeId = "bailiffState", styles = { TextColor3 = "text.secondary" } },
			{ nodeId = "objectiveText", styles = { TextColor3 = "text.primary" } },
			{ nodeId = "narrativeText", styles = { TextColor3 = "text.secondary" } },
			{ nodeId = "streetAudioCaption", styles = { TextColor3 = "text.secondary" } },
			{
				nodeId = "caseFilePanel",
				styles = {
					BackgroundColor3 = "surface.deep",
					BackgroundTransparency = "journal.transparency",
				},
			},
			{ nodeId = "caseFileTitle", styles = { TextColor3 = "text.brass" } },
			{ nodeId = "caseFileDiscoveries", styles = { TextColor3 = "text.primary" } },
			{ nodeId = "progressFill", styles = { BackgroundColor3 = "accent.blood" } },
		},
	})
end

local function animate(targetRevision: number)
	RenderingRuntime.playAnimation({
		schemaVersion = "1.0.0",
		animationId = "blackwater-objective-" .. targetRevision,
		targetNodeId = "objectivePanel",
		targetRevision = targetRevision,
		duration = 0.42,
		delay = 0,
		easingStyle = "Quint",
		easingDirection = "Out",
		repeatCount = 0,
		reverses = false,
		restoreOnCancel = false,
		motionEssential = false,
		goals = { GroupTransparency = 0 },
	})
end

local function render(root: Instance)
	revision += 1
	local result = RenderingRuntime.render(buildContract(root, revision))
	if not result.ok then
		warn("[LondonEngine][BlackwaterHUD] render failed", result.code)
		return
	end
	local themeResult = applyTheme(revision)
	if not themeResult.ok then
		warn("[LondonEngine][BlackwaterHUD] theme failed", themeResult.code)
	end
	animate(revision)
	RenderingRuntime.verifyIntegrity()
	RenderingRuntime.verifyThemeIntegrity()
	RenderingRuntime.verifyAnimationIntegrity()
end

local function scheduleRender(root: Instance)
	if renderScheduled then
		return
	end
	renderScheduled = true
	task.defer(function()
		renderScheduled = false
		if root.Parent then
			render(root)
		end
	end)
end

local function bind(root: Instance)
	currentRoot = root
	for _, connection in ipairs(rootConnections) do
		connection:Disconnect()
	end
	table.clear(rootConnections)
	for _, attribute in ipairs({
		"ObjectiveText",
		"ObjectiveNumber",
		"Progress",
		"Pressure",
		"NarrativeText",
		"DiscoveryLog",
		"InventoryText",
		"ChapterPhase",
		"ThreatText",
		"ChapterState",
		"BailiffState",
		"AudioState",
		"StreetAudioCaption",
		"StreetAudioEvent",
		"StreetAudioSegment",
		"BailiffAudioCaption",
		"BailiffAudioTelegraph",
		"AudioExecutionSnapshot",
		"AudioExecutionZone",
		"AudioExecutionSilence",
		"EndingText",
	}) do
		rootConnections[#rootConnections + 1] = root:GetAttributeChangedSignal(attribute)
			:Connect(function()
				scheduleRender(root)
			end)
	end
	rootConnections[#rootConnections + 1] = root.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			currentRoot = nil
			RenderingRuntime.unmount()
		end
	end)
	scheduleRender(root)
end

local configured = RenderingRuntime.inspect().configured
for _ = 1, 600 do
	if configured then
		break
	end
	task.wait()
	configured = RenderingRuntime.inspect().configured
end
if not configured then
	warn("[LondonEngine][BlackwaterHUD] rendering runtime was not configured")
	return
end
RenderingRuntime.registerLocalizationBundle(
	"en-us",
	{ ["blackwater.title"] = "THE BLACKWATER DESCENT" },
	1
)
RenderingRuntime.registerTheme(THEME_ID, 1, {
	["surface.deep"] = Color3.fromRGB(10, 12, 15),
	["surface.transparency"] = 0.12,
	["journal.transparency"] = 0.08,
	["text.brass"] = Color3.fromRGB(190, 154, 104),
	["text.primary"] = Color3.fromRGB(236, 231, 218),
	["text.secondary"] = Color3.fromRGB(174, 177, 176),
	["accent.blood"] = Color3.fromRGB(144, 25, 34),
})
RenderingRuntime.setLocale("en-us")
InteractionRuntime.registerAction(JOURNAL_ACTION_ID, function()
	journalOpen = not journalOpen
	local root = currentRoot
	if root then
		task.defer(scheduleRender, root)
	end
end)

local existing = Workspace:FindFirstChild(ROOT_NAME)
if existing then
	bind(existing)
end
local childConnection = Workspace.ChildAdded:Connect(function(child)
	if child.Name == ROOT_NAME then
		bind(child)
	end
end)
script.Destroying:Connect(function()
	childConnection:Disconnect()
	for _, connection in ipairs(rootConnections) do
		connection:Disconnect()
	end
	table.clear(rootConnections)
	InteractionRuntime.unregisterAction(JOURNAL_ACTION_ID)
end)
