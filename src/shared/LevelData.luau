-- Crystal Caverns: the three levels, as pure data.
-- WorldBuilder turns each level into parts; GameServer turns it into a game.
-- Platforms are listed by centre; every platform is 2 studs thick with its top at y = 0.
-- Crystals float 2 studs above the platform they sit on. Spikes and jump pads sit on
-- platforms too. The lava sea is sized from the course automatically.

local LevelData = {}

LevelData.LEVELS = {
	{
		Name = "Emerald Hollow",
		Platforms = {
			{ Center = Vector3.new(0, -1, 0), Size = Vector3.new(14, 2, 14), Kind = "stone" },
			{ Center = Vector3.new(0, -1, 16), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(10, -1, 28), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(-6, -1, 40), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(6, -1, 52), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(0, -1, 66), Size = Vector3.new(12, 2, 12), Kind = "stone" },
		},
		Crystals = {
			Vector3.new(0, 2, 16),
			Vector3.new(10, 2, 28),
			Vector3.new(-6, 2, 40),
			Vector3.new(6, 2, 52),
			Vector3.new(0, 2, 58),
		},
		Spikes = {},
		JumpPads = {},
		Portal = Vector3.new(0, 0, 66),
		Spawn = Vector3.new(0, 3, 0),
	},
	{
		Name = "Spike Ridge",
		Platforms = {
			{ Center = Vector3.new(0, -1, 0), Size = Vector3.new(14, 2, 14), Kind = "stone" },
			{ Center = Vector3.new(0, -1, 16), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(12, -1, 28), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(-10, -1, 40), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(0, -1, 52), Size = Vector3.new(6, 2, 6), Kind = "stone" },
			{ Center = Vector3.new(12, -1, 64), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(-8, -1, 76), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(0, -1, 90), Size = Vector3.new(12, 2, 12), Kind = "stone" },
		},
		Crystals = {
			Vector3.new(0, 2, 16),
			Vector3.new(12, 2, 26),
			Vector3.new(-10, 2, 40),
			Vector3.new(0, 2, 52),
			Vector3.new(12, 2, 62),
			Vector3.new(-8, 2, 76),
			Vector3.new(0, 2, 82),
		},
		Spikes = {
			Vector3.new(12, 1, 30),
			Vector3.new(12, 1, 66),
		},
		JumpPads = {
			Vector3.new(0, 0.5, 16),
			Vector3.new(-8, 0.5, 76),
		},
		Portal = Vector3.new(0, 0, 90),
		Spawn = Vector3.new(0, 3, 0),
	},
	{
		Name = "Crumble Deep",
		Platforms = {
			{ Center = Vector3.new(0, -1, 0), Size = Vector3.new(14, 2, 14), Kind = "stone" },
			{ Center = Vector3.new(0, -1, 16), Size = Vector3.new(6, 2, 6), Kind = "crumble" },
			{ Center = Vector3.new(-12, -1, 28), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(0, -1, 40), Size = Vector3.new(6, 2, 6), Kind = "crumble" },
			{ Center = Vector3.new(12, -1, 52), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(0, -1, 64), Size = Vector3.new(6, 2, 6), Kind = "crumble" },
			{ Center = Vector3.new(-12, -1, 76), Size = Vector3.new(8, 2, 8), Kind = "stone" },
			{ Center = Vector3.new(10, -1, 88), Size = Vector3.new(6, 2, 6), Kind = "crumble" },
			{ Center = Vector3.new(0, -1, 102), Size = Vector3.new(12, 2, 12), Kind = "stone" },
		},
		Crystals = {
			Vector3.new(0, 2, 0),
			Vector3.new(0, 2, 16),
			Vector3.new(-12, 2, 28),
			Vector3.new(0, 2, 40),
			Vector3.new(12, 2, 52),
			Vector3.new(0, 2, 64),
			Vector3.new(-12, 2, 76),
			Vector3.new(10, 2, 88),
			Vector3.new(0, 2, 95),
		},
		Spikes = {
			Vector3.new(12, 1, 54),
			Vector3.new(-12, 1, 78),
		},
		JumpPads = {
			Vector3.new(0, 0.5, 40),
		},
		Portal = Vector3.new(0, 0, 102),
		Spawn = Vector3.new(0, 3, 0),
	},
}

return LevelData
