-- Edit-time recipe; does not publish. Refuse to overwrite an existing emblem.
local modules = game:GetService("ReplicatedStorage").FlyHigh.Modules
local architecture = workspace.CloudPalace.CustomArchitecture
assert(not architecture:FindFirstChild("PhoenixGateEmblem"), "Review existing emblem before replacing it")
local art = require(modules.SceneryHabitatArt)
local emblem = art.Clone("CelestialPhoenix", architecture,
	CFrame.new(0, 2613.5, -3.65) * CFrame.Angles(math.pi / 2, 0, 0),
	1.4, Color3.fromRGB(243, 188, 83))
assert(emblem, "Missing original phoenix template")
emblem.Name = "PhoenixGateEmblem"
