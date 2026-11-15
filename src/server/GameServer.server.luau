-- Crystal Caverns: the server. It owns ALL game state in one table (`state`)
-- and is the only script that changes it. The client only mirrors what this
-- script sends over StateUpdate and Feedback, and only asks to start a game.
--
-- Flow: Lobby -> Playing -> (LevelClear) -> Playing ... -> Won | Lost.
-- Win: collect every crystal, then step into the open portal on level 3.
-- Lose: touch lava or a spike, or fall, three times.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local LevelData = require(ReplicatedStorage.Shared.LevelData)
local WorldBuilder = require(script.Parent.WorldBuilder)

-- RemoteEvents, created here so the client can WaitForChild them.
local PlayRequest = Instance.new("RemoteEvent")
PlayRequest.Name = "PlayRequest"
PlayRequest.Parent = ReplicatedStorage

local StateUpdate = Instance.new("RemoteEvent")
StateUpdate.Name = "StateUpdate"
StateUpdate.Parent = ReplicatedStorage

local Feedback = Instance.new("RemoteEvent")
Feedback.Name = "Feedback"
Feedback.Parent = ReplicatedStorage

-- The single source of truth for the game.
local state = {
	Phase = "Lobby", -- Lobby | Playing | LevelClear | Won | Lost
	LevelIndex = 1,
	CrystalsCollected = 0,
	TotalCrystals = 0,
	Lives = GameConfig.START_LIVES,
	Elapsed = 0,
}

local handles = nil
local collectedCrystals = {}
local invulnerableUntil = {}
local crumbleBusy = {}
local padCooldownUntil = {}
local portalMessageCooldownUntil = 0
local lastTimerPush = 0
local levelStartClock = 0

-- Forward declarations: buildCurrentLevel wires touches to these handlers.
local onCrystalTouched
local onPortalTouched
local onHazardTouched
local onJumpPadTouched
local onCrumbleTouched
local advanceLevel
local endGame

local function formatTime(seconds)
	local total = math.floor(seconds + 0.5)
	local minutes = math.floor(total / 60)
	local rest = total - minutes * 60
	return string.format("%02d:%02d", minutes, rest)
end

local function currentLevelDef()
	return LevelData.LEVELS[state.LevelIndex]
end

local function pushState()
	StateUpdate:FireAllClients({
		Phase = state.Phase,
		LevelIndex = state.LevelIndex,
		LevelName = currentLevelDef().Name,
		LevelCount = #LevelData.LEVELS,
		CrystalsCollected = state.CrystalsCollected,
		TotalCrystals = state.TotalCrystals,
		Lives = state.Lives,
		TimeText = formatTime(state.Elapsed),
	})
end

local function pushFeedback(kind, message)
	Feedback:FireAllClients({ Kind = kind, Message = message })
end

local function getCharacter(player)
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return nil
	end
	return character, humanoid, root
end

local function teleportToSpawn(player)
	local _, _, root = getCharacter(player)
	if root and handles then
		root.CFrame = handles.SpawnCFrame
	end
end

local function teleportAllToSpawn()
	for _, player in ipairs(Players:GetPlayers()) do
		teleportToSpawn(player)
	end
end

local function giveBriefShield(player)
	local character = player.Character
	if not character then
		return
	end
	local shield = Instance.new("ForceField")
	shield.Parent = character
	task.delay(GameConfig.HAZARD_INVULNERABLE_SECONDS, function()
		shield:Destroy()
	end)
end

local function isInvulnerable(player)
	local untilTime = invulnerableUntil[player]
	return untilTime ~= nil and os.clock() < untilTime
end

-- Builds the current level's world and wires every touch rule to it.
local function buildCurrentLevel()
	local levelDef = currentLevelDef()
	handles = WorldBuilder.buildLevel(levelDef)
	collectedCrystals = {}
	crumbleBusy = {}
	padCooldownUntil = {}
	state.CrystalsCollected = 0
	state.TotalCrystals = #levelDef.Crystals
	WorldBuilder.setPortalOpen(handles, false)

	for _, crystal in ipairs(handles.Crystals) do
		crystal.Touched:Connect(function(otherPart)
			onCrystalTouched(crystal, otherPart)
		end)
	end

	handles.PortalPad.Touched:Connect(function(otherPart)
		onPortalTouched(otherPart)
	end)

	handles.Lava.Touched:Connect(function(otherPart)
		onHazardTouched(otherPart, "lava")
	end)

	for _, spike in ipairs(handles.Spikes) do
		spike.Touched:Connect(function(otherPart)
			onHazardTouched(otherPart, "spike")
		end)
	end

	for _, pad in ipairs(handles.JumpPads) do
		pad.Touched:Connect(function(otherPart)
			onJumpPadTouched(pad, otherPart)
		end)
	end

	for _, platform in ipairs(handles.CrumblePlatforms) do
		platform.Touched:Connect(function(otherPart)
			onCrumbleTouched(platform, otherPart)
		end)
	end
end

onCrystalTouched = function(crystal, otherPart)
	if state.Phase ~= "Playing" then
		return
	end
	if collectedCrystals[crystal] then
		return
	end
	local character = otherPart.Parent
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	collectedCrystals[crystal] = true
	crystal:Destroy()
	state.CrystalsCollected += 1
	pushFeedback("crystal", "Crystal! " .. state.CrystalsCollected .. " of " .. state.TotalCrystals)
	if state.CrystalsCollected >= state.TotalCrystals then
		WorldBuilder.setPortalOpen(handles, true)
		pushFeedback("portalOpen", "The portal is OPEN! Step in!")
	end
	pushState()
end

onPortalTouched = function(otherPart)
	if state.Phase ~= "Playing" then
		return
	end
	local character = otherPart.Parent
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	if state.CrystalsCollected < state.TotalCrystals then
		if os.clock() > portalMessageCooldownUntil then
			portalMessageCooldownUntil = os.clock() + 2
			pushFeedback(
				"portalLocked",
				"The portal is locked! Collect " .. (state.TotalCrystals - state.CrystalsCollected) .. " more crystals."
			)
		end
		return
	end
	advanceLevel()
end

advanceLevel = function()
	if state.LevelIndex >= #LevelData.LEVELS then
		endGame(true)
		return
	end
	state.Phase = "LevelClear"
	pushFeedback("levelClear", "Level clear! Next cavern...")
	pushState()
	task.delay(GameConfig.LEVEL_CLEAR_PAUSE, function()
		if state.Phase ~= "LevelClear" then
			return
		end
		state.LevelIndex += 1
		state.Phase = "Playing"
		buildCurrentLevel()
		teleportAllToSpawn()
		pushFeedback("levelStart", "Level " .. state.LevelIndex .. ": " .. currentLevelDef().Name)
		pushState()
	end)
end

onHazardTouched = function(otherPart, hazardKind)
	if state.Phase ~= "Playing" then
		return
	end
	local character = otherPart.Parent
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	if isInvulnerable(player) then
		return
	end
	state.Lives -= 1
	invulnerableUntil[player] = os.clock() + GameConfig.HAZARD_INVULNERABLE_SECONDS
	if hazardKind == "lava" then
		pushFeedback("hazard", "The lava burns! " .. state.Lives .. " lives left.")
	else
		pushFeedback("hazard", "Spikes! " .. state.Lives .. " lives left.")
	end
	if state.Lives <= 0 then
		endGame(false)
		return
	end
	giveBriefShield(player)
	teleportToSpawn(player)
	pushState()
end

onJumpPadTouched = function(pad, otherPart)
	if state.Phase ~= "Playing" then
		return
	end
	local character = otherPart.Parent
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local _, humanoid, root = getCharacter(player)
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if os.clock() < (padCooldownUntil[pad] or 0) then
		return
	end
	padCooldownUntil[pad] = os.clock() + 0.5
	local velocity = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, GameConfig.JUMP_PAD_POWER, velocity.Z)
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

onCrumbleTouched = function(platform, otherPart)
	if state.Phase ~= "Playing" then
		return
	end
	local character = otherPart.Parent
	if not character then
		return
	end
	if not Players:GetPlayerFromCharacter(character) then
		return
	end
	if crumbleBusy[platform] then
		return
	end
	crumbleBusy[platform] = true
	task.spawn(function()
		task.wait(GameConfig.CRUMBLE_DELAY)
		platform.CanCollide = false
		platform.Transparency = 0.7
		task.wait(GameConfig.CRUMBLE_GONE_SECONDS)
		platform.CanCollide = true
		platform.Transparency = 0
		crumbleBusy[platform] = false
	end)
end

local function startGame()
	state.LevelIndex = 1
	state.Lives = GameConfig.START_LIVES
	state.Elapsed = 0
	state.Phase = "Playing"
	levelStartClock = os.clock()
	invulnerableUntil = {}
	buildCurrentLevel()
	teleportAllToSpawn()
	pushFeedback("levelStart", "Level 1: " .. currentLevelDef().Name .. " — collect every crystal!")
	pushState()
end

endGame = function(won)
	if won then
		state.Phase = "Won"
		pushFeedback("win", "YOU WIN! All caverns cleared in " .. formatTime(state.Elapsed) .. "!")
	else
		state.Phase = "Lost"
		pushFeedback("lose", "Out of lives! The caverns win this time.")
	end
	pushState()
end

PlayRequest.OnServerEvent:Connect(function(player)
	if state.Phase == "Lobby" or state.Phase == "Won" or state.Phase == "Lost" then
		startGame()
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if state.Phase == "Playing" or state.Phase == "LevelClear" then
			teleportToSpawn(player)
		end
		pushState()
	end)
	-- A player who joins mid-game gets the current state right away.
	task.wait(1)
	pushState()
end)

-- The heartbeat owns the timer and the fall check. It never busy-loops:
-- it runs once per frame and only pushes the timer twice a second.
RunService.Heartbeat:Connect(function(dt)
	if state.Phase == "Playing" then
		state.Elapsed += dt
		if os.clock() - lastTimerPush >= GameConfig.TIMER_PUSH_INTERVAL then
			lastTimerPush = os.clock()
			pushState()
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local _, humanoid, root = getCharacter(player)
			if root and root.Position.Y < GameConfig.FALL_KILL_Y then
				if humanoid and humanoid.Health > 0 then
					onHazardTouched(root, "lava")
				end
			end
		end
	end
end)

-- The lobby shows level 1 so the first screen already looks like the game.
buildCurrentLevel()
pushState()
print("Crystal Caverns server ready: " .. #LevelData.LEVELS .. " levels, " .. state.TotalCrystals .. " crystals on level 1.")
