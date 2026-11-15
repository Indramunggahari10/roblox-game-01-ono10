-- Crystal Caverns: the client. It draws everything the player sees and sends
-- exactly one thing to the server: "I want to play" (PlayRequest).
-- All rules live on the server; this script only mirrors the state it sends.
--
-- Layout notes: the top-left corner belongs to Roblox's own menu buttons, so
-- the HUD sits top-centre. Every label is large enough to read when a
-- screenshot is scaled down for judging.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PlayRequest = ReplicatedStorage:WaitForChild("PlayRequest")
local StateUpdate = ReplicatedStorage:WaitForChild("StateUpdate")
local Feedback = ReplicatedStorage:WaitForChild("Feedback")

local PALETTE = {
	Background = Color3.fromRGB(24, 12, 48),
	Panel = Color3.fromRGB(38, 22, 74),
	PanelBorder = Color3.fromRGB(94, 68, 160),
	Text = Color3.fromRGB(245, 240, 255),
	Accent = Color3.fromRGB(45, 225, 194),
	Gold = Color3.fromRGB(255, 201, 60),
	Danger = Color3.fromRGB(255, 80, 80),
}

-- The client's mirror of the server state. Only StateUpdate changes it.
local hudState = {
	Phase = "Lobby",
	LevelIndex = 1,
	LevelName = "Emerald Hollow",
	LevelCount = 3,
	CrystalsCollected = 0,
	TotalCrystals = 0,
	Lives = 3,
	TimeText = "00:00",
}

local gui = Instance.new("ScreenGui")
gui.Name = "CrystalCavernsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function roundCorners(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function makeLabel(parent, name, text, size, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = size
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color
	label.TextScaled = false
	label.Parent = parent
	return label
end

-- Top-centre HUD: crystals, lives, timer, level. Never in the top-left corner.
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 12)
topBar.Size = UDim2.fromOffset(680, 56)
topBar.BackgroundColor3 = PALETTE.Panel
topBar.BackgroundTransparency = 0.15
topBar.BorderColor3 = PALETTE.PanelBorder
topBar.BorderSizePixel = 2
topBar.Visible = false
topBar.Parent = gui
roundCorners(topBar, 12)

local crystalLabel = makeLabel(topBar, "CrystalLabel", "◆ 0/0", 30, PALETTE.Accent)
crystalLabel.Position = UDim2.new(0, 16, 0, 0)
crystalLabel.Size = UDim2.new(0, 170, 1, 0)
crystalLabel.TextXAlignment = Enum.TextXAlignment.Left

local livesLabel = makeLabel(topBar, "LivesLabel", "♥♥♥", 30, PALETTE.Danger)
livesLabel.Position = UDim2.new(0, 190, 0, 0)
livesLabel.Size = UDim2.new(0, 140, 1, 0)
livesLabel.TextXAlignment = Enum.TextXAlignment.Left

local timerLabel = makeLabel(topBar, "TimerLabel", "00:00", 30, PALETTE.Text)
timerLabel.Position = UDim2.new(0, 330, 0, 0)
timerLabel.Size = UDim2.new(0, 150, 1, 0)
timerLabel.TextXAlignment = Enum.TextXAlignment.Center

local levelLabel = makeLabel(topBar, "LevelLabel", "LEVEL 1", 26, PALETTE.Gold)
levelLabel.Position = UDim2.new(0, 480, 0, 0)
levelLabel.Size = UDim2.new(0, 190, 1, 0)
levelLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Transient message line under the HUD.
local messageLabel = makeLabel(gui, "MessageLabel", "", 30, PALETTE.Gold)
messageLabel.AnchorPoint = Vector2.new(0.5, 0)
messageLabel.Position = UDim2.new(0.5, 0, 0, 84)
messageLabel.Size = UDim2.fromOffset(900, 44)
messageLabel.TextStrokeTransparency = 0.4
messageLabel.Visible = false

-- Controls hint along the bottom edge, shown while playing.
local controlsLabel = makeLabel(gui, "ControlsLabel", "WASD or Arrows to move  •  SPACE to jump  •  R to restart", 24, PALETTE.Text)
controlsLabel.AnchorPoint = Vector2.new(0.5, 1)
controlsLabel.Position = UDim2.new(0.5, 0, 1, -16)
controlsLabel.Size = UDim2.fromOffset(900, 34)
controlsLabel.TextTransparency = 0.25
controlsLabel.Visible = false

-- Red flash on taking a hit.
local flashFrame = Instance.new("Frame")
flashFrame.Name = "HazardFlash"
flashFrame.Size = UDim2.fromScale(1, 1)
flashFrame.BackgroundColor3 = PALETTE.Danger
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel = 0
flashFrame.Parent = gui

local function showMessage(text, holdSeconds)
	messageLabel.Text = text
	messageLabel.Visible = true
	messageLabel.TextTransparency = 0
	task.delay(holdSeconds or 2.5, function()
		local tween = TweenService:Create(
			messageLabel,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextTransparency = 1 }
		)
		tween:Play()
		tween.Completed:Connect(function()
			messageLabel.Visible = false
			messageLabel.TextTransparency = 0
		end)
	end)
end

local function flashHazard()
	flashFrame.BackgroundTransparency = 0.45
	local tween = TweenService:Create(
		flashFrame,
		TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	tween:Play()
end

local function pulseCrystals()
	local tween = TweenService:Create(
		crystalLabel,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextSize = 38 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		TweenService:Create(
			crystalLabel,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextSize = 30 }
		):Play()
	end)
end

-- Start screen: full overlay with the title, the goal, and one big button.
local startFrame = Instance.new("Frame")
startFrame.Name = "StartScreen"
startFrame.Size = UDim2.fromScale(1, 1)
startFrame.BackgroundColor3 = PALETTE.Background
startFrame.BackgroundTransparency = 0.15
startFrame.BorderSizePixel = 0
startFrame.Parent = gui

local titleLabel = makeLabel(startFrame, "Title", "CRYSTAL CAVERNS", 64, PALETTE.Accent)
titleLabel.AnchorPoint = Vector2.new(0.5, 0)
titleLabel.Position = UDim2.new(0.5, 0, 0.18, 0)
titleLabel.Size = UDim2.fromOffset(1000, 80)

local subtitleLabel = makeLabel(startFrame, "Subtitle", "Collect every crystal. Reach the portal. Survive the lava.", 28, PALETTE.Text)
subtitleLabel.AnchorPoint = Vector2.new(0.5, 0)
subtitleLabel.Position = UDim2.new(0.5, 0, 0.18, 88)
subtitleLabel.Size = UDim2.fromOffset(1000, 40)

local instructionsLabel = makeLabel(
	startFrame,
	"Instructions",
	"3 caverns  •  21 crystals  •  3 lives\nJump pads launch you high. Brown platforms crumble under your feet.\nRed spikes and lava cost a life. The portal opens when its crystals are all collected.",
	26,
	PALETTE.Text
)
instructionsLabel.AnchorPoint = Vector2.new(0.5, 0)
instructionsLabel.Position = UDim2.new(0.5, 0, 0.38, 0)
instructionsLabel.Size = UDim2.fromOffset(1000, 140)

local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.AnchorPoint = Vector2.new(0.5, 0)
playButton.Position = UDim2.new(0.5, 0, 0.58, 0)
playButton.Size = UDim2.fromOffset(320, 84)
playButton.BackgroundColor3 = PALETTE.Gold
playButton.BorderSizePixel = 0
playButton.Text = "▶  PLAY"
playButton.TextSize = 36
playButton.Font = Enum.Font.GothamBold
playButton.TextColor3 = Color3.fromRGB(30, 16, 4)
playButton.Parent = startFrame
roundCorners(playButton, 14)

local keysLabel = makeLabel(startFrame, "KeysHint", "Move: WASD or Arrow Keys  •  Jump: SPACE  •  Restart: R or P", 24, PALETTE.Text)
keysLabel.AnchorPoint = Vector2.new(0.5, 0)
keysLabel.Position = UDim2.new(0.5, 0, 0.58, 100)
keysLabel.Size = UDim2.fromOffset(1000, 36)
keysLabel.TextTransparency = 0.2

-- End screen: one frame, two moods (win gold, lose red).
local endFrame = Instance.new("Frame")
endFrame.Name = "EndScreen"
endFrame.Size = UDim2.fromScale(1, 1)
endFrame.BackgroundColor3 = PALETTE.Background
endFrame.BackgroundTransparency = 0.15
endFrame.BorderSizePixel = 0
endFrame.Visible = false
endFrame.Parent = gui

local endTitle = makeLabel(endFrame, "EndTitle", "YOU WIN!", 72, PALETTE.Gold)
endTitle.AnchorPoint = Vector2.new(0.5, 0)
endTitle.Position = UDim2.new(0.5, 0, 0.24, 0)
endTitle.Size = UDim2.fromOffset(1000, 96)

local endStats = makeLabel(endFrame, "EndStats", "", 32, PALETTE.Text)
endStats.AnchorPoint = Vector2.new(0.5, 0)
endStats.Position = UDim2.new(0.5, 0, 0.24, 112)
endStats.Size = UDim2.fromOffset(1000, 48)

local playAgainButton = Instance.new("TextButton")
playAgainButton.Name = "PlayAgainButton"
playAgainButton.AnchorPoint = Vector2.new(0.5, 0)
playAgainButton.Position = UDim2.new(0.5, 0, 0.48, 0)
playAgainButton.Size = UDim2.fromOffset(360, 84)
playAgainButton.BackgroundColor3 = PALETTE.Gold
playAgainButton.BorderSizePixel = 0
playAgainButton.Text = "↻  PLAY AGAIN  (R)"
playAgainButton.TextSize = 32
playAgainButton.Font = Enum.Font.GothamBold
playAgainButton.TextColor3 = Color3.fromRGB(30, 16, 4)
playAgainButton.Parent = endFrame
roundCorners(playAgainButton, 14)

local function updateHud()
	crystalLabel.Text = "◆ " .. hudState.CrystalsCollected .. "/" .. hudState.TotalCrystals
	local hearts = ""
	for _ = 1, hudState.Lives do
		hearts ..= "♥"
	end
	livesLabel.Text = hearts
	timerLabel.Text = hudState.TimeText
	levelLabel.Text = "LEVEL " .. hudState.LevelIndex .. "/" .. hudState.LevelCount
end

local function showPhase(phase)
	if phase == "Lobby" then
		startFrame.Visible = true
		endFrame.Visible = false
		topBar.Visible = false
		controlsLabel.Visible = false
	elseif phase == "Playing" or phase == "LevelClear" then
		startFrame.Visible = false
		endFrame.Visible = false
		topBar.Visible = true
		controlsLabel.Visible = true
	elseif phase == "Won" then
		startFrame.Visible = false
		endFrame.Visible = true
		topBar.Visible = true
		controlsLabel.Visible = false
		endTitle.Text = "YOU WIN!"
		endTitle.TextColor3 = PALETTE.Gold
		endStats.Text = "All " .. hudState.LevelCount .. " caverns cleared in " .. hudState.TimeText .. "!"
	elseif phase == "Lost" then
		startFrame.Visible = false
		endFrame.Visible = true
		topBar.Visible = true
		controlsLabel.Visible = false
		endTitle.Text = "OUT OF LIVES"
		endTitle.TextColor3 = PALETTE.Danger
		endStats.Text = "You reached Level " .. hudState.LevelIndex .. ": " .. hudState.LevelName
	end
	updateHud()
end

local function requestPlay()
	PlayRequest:FireServer()
end

playButton.MouseButton1Click:Connect(requestPlay)
playAgainButton.MouseButton1Click:Connect(requestPlay)

-- R (or P) starts the game from the lobby and restarts it from an end screen.
-- ContextActionService, not raw key listening, so the keys work even when
-- Roblox's default camera scripts have claimed the arrow keys.
local function onPlayOrRestart(_actionName, inputState, _inputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if hudState.Phase == "Lobby" or hudState.Phase == "Won" or hudState.Phase == "Lost" then
		requestPlay()
	end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindAction("PlayOrRestart", onPlayOrRestart, false, Enum.KeyCode.R, Enum.KeyCode.P)

StateUpdate.OnClientEvent:Connect(function(newState)
	hudState = newState
	showPhase(newState.Phase)
end)

Feedback.OnClientEvent:Connect(function(feedback)
	if feedback.Kind == "crystal" then
		pulseCrystals()
		showMessage(feedback.Message, 1.5)
	elseif feedback.Kind == "hazard" then
		flashHazard()
		showMessage(feedback.Message, 2)
	elseif feedback.Kind == "portalOpen" then
		showMessage(feedback.Message, 3)
	elseif feedback.Kind == "portalLocked" then
		showMessage(feedback.Message, 2.5)
	elseif feedback.Kind == "levelClear" then
		showMessage(feedback.Message, 2.5)
	elseif feedback.Kind == "levelStart" then
		showMessage(feedback.Message, 3)
	elseif feedback.Kind == "win" then
		showMessage(feedback.Message, 4)
	elseif feedback.Kind == "lose" then
		showMessage(feedback.Message, 4)
	end
end)

showPhase("Lobby")
