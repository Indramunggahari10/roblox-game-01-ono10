-- Crystal Caverns: builds one level's world from LevelData into Workspace.
-- One job only: turn data into parts. GameServer owns the rules; this module
-- owns the geometry. Every part it makes is anchored, named, and returned in
-- the handles table so GameServer can wire up touch detection.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local WorldBuilder = {}

local function makePart(name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = true
	return part
end

local function buildLavaSea(world, portalZ)
	local lava = makePart(
		"Lava",
		Vector3.new(180, 2, portalZ + 70),
		Vector3.new(0, -8, portalZ / 2),
		GameConfig.Palette.Lava,
		Enum.Material.Neon
	)
	lava.Parent = world
	return lava
end

local function buildPlatforms(world, levelDef, handles)
	for index, platform in ipairs(levelDef.Platforms) do
		local color = GameConfig.Palette.Stone
		local material = Enum.Material.Slate
		if platform.Kind == "crumble" then
			color = GameConfig.Palette.Crumble
			material = Enum.Material.WoodPlanks
		end
		local part = makePart("Platform" .. index, platform.Size, platform.Center, color, material)
		if platform.Kind == "crumble" then
			part.Name = "CrumblePlatform" .. index
			table.insert(handles.CrumblePlatforms, part)
		end
		part.Parent = world
		-- A thin lighter cap so each platform reads as a step, not a slab.
		local cap = makePart(
			"PlatformCap" .. index,
			Vector3.new(platform.Size.X, 0.4, platform.Size.Z),
			platform.Center + Vector3.new(0, 1, 0),
			GameConfig.Palette.StoneTop,
			Enum.Material.SmoothPlastic
		)
		cap.CanTouch = false
		cap.Parent = world
	end
end

local function buildCrystals(world, levelDef, handles)
	for index, position in ipairs(levelDef.Crystals) do
		local crystal = makePart(
			"Crystal" .. index,
			Vector3.new(2, 2, 2),
			position,
			GameConfig.Palette.Crystal,
			Enum.Material.Neon
		)
		crystal.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(45), 0)
		crystal.CanCollide = false
		crystal.Parent = world
		table.insert(handles.Crystals, crystal)
	end
end

local function buildSpikes(world, levelDef, handles)
	for index, position in ipairs(levelDef.Spikes) do
		local spike = makePart(
			"Spike" .. index,
			Vector3.new(4, 2, 4),
			position,
			GameConfig.Palette.Spike,
			Enum.Material.Neon
		)
		spike.Parent = world
		table.insert(handles.Spikes, spike)
	end
end

local function buildJumpPads(world, levelDef, handles)
	for index, position in ipairs(levelDef.JumpPads) do
		local pad = makePart(
			"JumpPad" .. index,
			Vector3.new(4, 1, 4),
			position,
			GameConfig.Palette.JumpPad,
			Enum.Material.Neon
		)
		pad.Parent = world
		table.insert(handles.JumpPads, pad)
	end
end

local function buildPortal(world, levelDef, handles)
	local portal = levelDef.Portal
	local leftPillar = makePart(
		"PortalPillarLeft",
		Vector3.new(1, 8, 1),
		portal + Vector3.new(-3, 4, 0),
		GameConfig.Palette.PortalLocked,
		Enum.Material.Neon
	)
	leftPillar.Parent = world
	local rightPillar = makePart(
		"PortalPillarRight",
		Vector3.new(1, 8, 1),
		portal + Vector3.new(3, 4, 0),
		GameConfig.Palette.PortalLocked,
		Enum.Material.Neon
	)
	rightPillar.Parent = world
	local topBar = makePart(
		"PortalTop",
		Vector3.new(7, 1, 1),
		portal + Vector3.new(0, 8, 0),
		GameConfig.Palette.PortalLocked,
		Enum.Material.Neon
	)
	topBar.Parent = world
	local pad = makePart(
		"PortalPad",
		Vector3.new(5, 0.5, 5),
		portal + Vector3.new(0, 0.25, 0),
		GameConfig.Palette.PortalLocked,
		Enum.Material.Neon
	)
	pad.CanCollide = false
	pad.Parent = world
	handles.PortalParts = { leftPillar, rightPillar, topBar, pad }
	handles.PortalPad = pad
end

local function buildSpawnPad(world, levelDef, handles)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnPad"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = levelDef.Spawn - Vector3.new(0, 2.5, 0)
	spawn.Color = GameConfig.Palette.Gold
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = world
	handles.SpawnCFrame = CFrame.new(levelDef.Spawn)
end

-- Builds the level into Workspace, replacing any previous level world.
-- Returns the handles GameServer needs: Crystals, PortalPad, PortalParts,
-- SpawnCFrame, CrumblePlatforms, Spikes, JumpPads, Lava.
function WorldBuilder.buildLevel(levelDef)
	local oldWorld = Workspace:FindFirstChild("CrystalCavernsWorld")
	if oldWorld then
		oldWorld:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "CrystalCavernsWorld"
	world.Parent = Workspace

	local handles = {
		Crystals = {},
		CrumblePlatforms = {},
		Spikes = {},
		JumpPads = {},
		PortalParts = {},
		PortalPad = nil,
		SpawnCFrame = CFrame.new(levelDef.Spawn),
		Lava = nil,
	}

	handles.Lava = buildLavaSea(world, levelDef.Portal.Z)
	buildPlatforms(world, levelDef, handles)
	buildCrystals(world, levelDef, handles)
	buildSpikes(world, levelDef, handles)
	buildJumpPads(world, levelDef, handles)
	buildPortal(world, levelDef, handles)
	buildSpawnPad(world, levelDef, handles)

	return handles
end

-- Recolours the portal to show whether it is open yet.
function WorldBuilder.setPortalOpen(handles, isOpen)
	local color = GameConfig.Palette.PortalLocked
	if isOpen then
		color = GameConfig.Palette.PortalOpen
	end
	for _, part in ipairs(handles.PortalParts) do
		part.Color = color
	end
end

return WorldBuilder
