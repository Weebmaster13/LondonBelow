--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Config.Chapter196VerticalSliceConfig)

local Builder = {}
local lightingSnapshot: { [string]: any }? = nil

local MATERIAL_STONE = Enum.Material.Slate
local MATERIAL_WOOD = Enum.Material.WoodPlanks
local stone = Color3.fromRGB(38, 40, 43)
local wetStone = Color3.fromRGB(24, 27, 31)
local brass = Color3.fromRGB(132, 94, 46)
local warm = Color3.fromRGB(255, 184, 93)

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local instance = Instance.new("Part")
	instance.Name = name
	instance.Size = size
	instance.CFrame = cframe
	instance.Color = color
	instance.Material = material
	instance.Anchored = true
	instance.CastShadow = true
	instance.TopSurface = Enum.SurfaceType.Smooth
	instance.BottomSurface = Enum.SurfaceType.Smooth
	instance.Parent = parent
	return instance
end

local function wall(parent: Instance, name: string, size: Vector3, position: Vector3)
	return part(parent, name, size, CFrame.new(position), stone, MATERIAL_STONE)
end

local function lamp(parent: Instance, position: Vector3, name: string)
	local post = part(
		parent,
		name,
		Vector3.new(0.45, 8, 0.45),
		CFrame.new(position + Vector3.new(0, 4, 0)),
		brass,
		Enum.Material.Metal
	)
	local glass = part(
		parent,
		name .. "_Glass",
		Vector3.new(1.4, 2.2, 1.4),
		CFrame.new(position + Vector3.new(0, 8.3, 0)),
		Color3.fromRGB(255, 193, 108),
		Enum.Material.Glass
	)
	glass.Transparency = 0.3
	local light = Instance.new("PointLight")
	light.Name = "GasLight"
	light.Color = warm
	light.Range = 22
	light.Brightness = 1.7
	light.Shadows = true
	light.Parent = glass
	return post
end

local function room(parent: Instance, id: string, centerZ: number, width: number, depth: number)
	local model = Instance.new("Model")
	model.Name = id
	model:SetAttribute("RoomId", id)
	model.Parent = parent
	part(
		model,
		"Floor",
		Vector3.new(width, 1, depth),
		CFrame.new(0, 0, centerZ),
		wetStone,
		MATERIAL_STONE
	)
	wall(model, "LeftWall", Vector3.new(1, 14, depth), Vector3.new(-width / 2, 7, centerZ))
	wall(model, "RightWall", Vector3.new(1, 14, depth), Vector3.new(width / 2, 7, centerZ))
	return model
end

local function interaction(
	parent: Instance,
	id: string,
	label: string,
	position: Vector3,
	color: Color3,
	kind: string
): BasePart
	local target = part(
		parent,
		id,
		Vector3.new(2.4, 2.4, 2.4),
		CFrame.new(position),
		color,
		if kind == "Ward" then Enum.Material.Metal else MATERIAL_WOOD
	)
	target:SetAttribute("InteractionId", id)
	target:SetAttribute("InteractionKind", kind)
	target:SetAttribute("ObjectiveLabel", label)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChapterInteraction"
	prompt.ActionText = label
	prompt.ObjectText = Config.DisplayName
	prompt.MaxActivationDistance = Config.InteractionDistance
	prompt.HoldDuration = if kind == "Ward" then 1.25 else 0.65
	prompt.RequiresLineOfSight = true
	prompt.Enabled = false
	prompt.Parent = target
	return target
end

function Builder.build(): (Folder?, { [string]: BasePart }?, string?)
	local existing = Workspace:FindFirstChild(Config.RootName)
	if existing then
		existing:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = Config.RootName
	root:SetAttribute("ChapterId", Config.ChapterId)
	root:SetAttribute("OwnerRuntime", "Chapter196VerticalSliceCoordinator")
	root:SetAttribute("ObjectiveIndex", 1)
	root:SetAttribute("ObjectiveText", Config.Objectives[1].text)
	root:SetAttribute("Pressure", 0)
	root.Parent = Workspace

	part(
		root,
		"LondonStreet",
		Vector3.new(70, 1, 90),
		CFrame.new(0, 0, 58),
		wetStone,
		Enum.Material.Cobblestone
	)
	for z = 22, 94, 18 do
		lamp(root, Vector3.new(-25, 0, z), "GasLampWest" .. z)
		lamp(root, Vector3.new(25, 0, z), "GasLampEast" .. z)
	end
	for z = 24, 96, 24 do
		wall(root, "TerraceWest" .. z, Vector3.new(16, 24, 18), Vector3.new(-36, 12, z))
		wall(root, "TerraceEast" .. z, Vector3.new(16, 24, 18), Vector3.new(36, 12, z))
	end

	local house = Instance.new("Model")
	house.Name = "BlackwaterHouse"
	house.Parent = root
	wall(house, "FacadeLeft", Vector3.new(26, 30, 3), Vector3.new(-17, 15, 10))
	wall(house, "FacadeRight", Vector3.new(26, 30, 3), Vector3.new(17, 15, 10))
	wall(house, "FacadeTop", Vector3.new(8, 10, 3), Vector3.new(0, 25, 10))
	local foyer = room(house, "Foyer", -5, 34, 30)
	local gallery = room(house, "Gallery", -38, 34, 32)
	local archive = room(house, "ForbiddenArchive", -72, 34, 34)
	local crypt = room(house, "UnderStairCrypt", -105, 26, 30)
	local ritual = room(house, "GlassHeartChamber", -136, 38, 32)
	part(foyer, "Ceiling", Vector3.new(34, 1, 30), CFrame.new(0, 14, -5), stone, MATERIAL_STONE)
	part(gallery, "Ceiling", Vector3.new(34, 1, 32), CFrame.new(0, 14, -38), stone, MATERIAL_STONE)
	part(archive, "Ceiling", Vector3.new(34, 1, 34), CFrame.new(0, 14, -72), stone, MATERIAL_STONE)
	part(crypt, "Ceiling", Vector3.new(26, 1, 30), CFrame.new(0, 10, -105), stone, MATERIAL_STONE)
	part(ritual, "Ceiling", Vector3.new(38, 1, 32), CFrame.new(0, 16, -136), stone, MATERIAL_STONE)

	local interactions = {}
	interactions.ignite_lantern = interaction(
		root,
		"ignite_lantern",
		"Light lantern",
		Vector3.new(-8, 2, 67),
		brass,
		"Lantern"
	)
	interactions.read_ledger = interaction(
		gallery,
		"read_ledger",
		"Read ledger",
		Vector3.new(-8, 2, -37),
		Color3.fromRGB(74, 49, 31),
		"Note"
	)
	interactions.take_seal = interaction(
		gallery,
		"take_seal",
		"Take brass seal",
		Vector3.new(10, 2, -46),
		brass,
		"Collectible"
	)
	interactions.ward_west = interaction(
		archive,
		"ward_west",
		"Turn western ward",
		Vector3.new(-13, 4, -70),
		brass,
		"Ward"
	)
	interactions.ward_east = interaction(
		archive,
		"ward_east",
		"Turn eastern ward",
		Vector3.new(13, 4, -70),
		brass,
		"Ward"
	)
	interactions.ward_crypt =
		interaction(crypt, "ward_crypt", "Turn buried ward", Vector3.new(0, 3, -106), brass, "Ward")
	interactions.open_archive = interaction(
		archive,
		"open_archive",
		"Open sealed passage",
		Vector3.new(0, 5, -87),
		Color3.fromRGB(54, 38, 29),
		"Door"
	)
	interactions.take_heart = interaction(
		ritual,
		"take_heart",
		"Take the glass heart",
		Vector3.new(0, 4, -138),
		Color3.fromRGB(144, 20, 35),
		"Relic"
	)
	interactions.take_heart.Material = Enum.Material.Glass
	interactions.take_heart.Transparency = 0.18
	interactions.escape_gate = interaction(
		root,
		"escape_gate",
		"Break through the iron gate",
		Vector3.new(0, 5, 102),
		Color3.fromRGB(30, 32, 34),
		"Escape"
	)
	part(
		root,
		"SpawnMarker",
		Vector3.new(8, 0.5, 8),
		Config.StartCFrame,
		Color3.fromRGB(28, 30, 32),
		MATERIAL_STONE
	).Transparency =
		1

	if lightingSnapshot == nil then
		lightingSnapshot = {
			ClockTime = Lighting.ClockTime,
			Brightness = Lighting.Brightness,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			FogColor = Lighting.FogColor,
			FogStart = Lighting.FogStart,
			FogEnd = Lighting.FogEnd,
		}
	end
	Lighting.ClockTime = 1.15
	Lighting.Brightness = 1.15
	Lighting.Ambient = Color3.fromRGB(18, 21, 28)
	Lighting.OutdoorAmbient = Color3.fromRGB(25, 27, 34)
	Lighting.FogColor = Color3.fromRGB(63, 72, 78)
	Lighting.FogStart = 8
	Lighting.FogEnd = 125
	local atmosphere = Lighting:FindFirstChild("BlackwaterAtmosphere") or Instance.new("Atmosphere")
	atmosphere.Name = "BlackwaterAtmosphere"
	atmosphere.Density = 0.48
	atmosphere.Offset = -0.25
	atmosphere.Color = Color3.fromRGB(156, 165, 170)
	atmosphere.Decay = Color3.fromRGB(45, 52, 60)
	atmosphere.Glare = 0
	atmosphere.Haze = 2.8
	atmosphere.Parent = Lighting
	local colorGrade = Instance.new("ColorCorrectionEffect")
	colorGrade.Name = "BlackwaterColorGrade"
	colorGrade.Brightness = -0.04
	colorGrade.Contrast = 0.12
	colorGrade.Saturation = -0.35
	colorGrade.TintColor = Color3.fromRGB(197, 210, 214)
	colorGrade.Parent = Lighting
	return root, interactions, nil
end

function Builder.destroy()
	local root = Workspace:FindFirstChild(Config.RootName)
	if root then
		root:Destroy()
	end
	local atmosphere = Lighting:FindFirstChild("BlackwaterAtmosphere")
	if atmosphere then
		atmosphere:Destroy()
	end
	local colorGrade = Lighting:FindFirstChild("BlackwaterColorGrade")
	if colorGrade then
		colorGrade:Destroy()
	end
	if lightingSnapshot then
		Lighting.ClockTime = lightingSnapshot.ClockTime
		Lighting.Brightness = lightingSnapshot.Brightness
		Lighting.Ambient = lightingSnapshot.Ambient
		Lighting.OutdoorAmbient = lightingSnapshot.OutdoorAmbient
		Lighting.FogColor = lightingSnapshot.FogColor
		Lighting.FogStart = lightingSnapshot.FogStart
		Lighting.FogEnd = lightingSnapshot.FogEnd
		lightingSnapshot = nil
	end
end

return Builder
