-- Crystal Caverns: every tunable number and colour in one place.
-- GameServer reads this; GameClient reads the palette through StateUpdate.
-- Nothing here talks to a Roblox service, so it is safe to share.

local GameConfig = {}

GameConfig.GAME_NAME = "Crystal Caverns"
GameConfig.START_LIVES = 3
GameConfig.LEVEL_CLEAR_PAUSE = 2.5
GameConfig.HAZARD_INVULNERABLE_SECONDS = 1.5
GameConfig.CRUMBLE_DELAY = 0.8
GameConfig.CRUMBLE_GONE_SECONDS = 2.0
GameConfig.JUMP_PAD_POWER = 95
GameConfig.TIMER_PUSH_INTERVAL = 0.5
GameConfig.FALL_KILL_Y = -20
GameConfig.CRYSTAL_SPIN_SPEED = 1.5

GameConfig.Palette = {
	Background = Color3.fromRGB(24, 12, 48),
	Panel = Color3.fromRGB(38, 22, 74),
	PanelBorder = Color3.fromRGB(94, 68, 160),
	Text = Color3.fromRGB(245, 240, 255),
	Accent = Color3.fromRGB(45, 225, 194),
	Gold = Color3.fromRGB(255, 201, 60),
	Lava = Color3.fromRGB(255, 90, 42),
	Stone = Color3.fromRGB(74, 62, 110),
	StoneTop = Color3.fromRGB(96, 82, 138),
	Crumble = Color3.fromRGB(150, 104, 58),
	Spike = Color3.fromRGB(255, 64, 64),
	JumpPad = Color3.fromRGB(80, 255, 120),
	PortalLocked = Color3.fromRGB(255, 80, 80),
	PortalOpen = Color3.fromRGB(60, 255, 140),
	Crystal = Color3.fromRGB(45, 225, 194),
}

return GameConfig
