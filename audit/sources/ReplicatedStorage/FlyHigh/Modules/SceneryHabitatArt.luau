--!strict
-- Cosmetic copies of the game's original obstacle meshes. No obstacle scripts or targeting flags.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Art = {}
local rgb = Color3.fromRGB
local STONE = rgb(208, 194, 164)
local GOLD = rgb(243, 188, 83)

export type Wing = { part: BasePart, rest: CFrame, hinge: Vector3, side: number }
export type Pose = { model: Model, wings: { Wing }, phase: number, speed: number, amplitude: number }

function Art.Clone(name: string, parent: Instance, cf: CFrame, scale: number, tint: Color3?): Model?
	local gameAssets = ReplicatedStorage:FindFirstChild("FlyHigh")
	local templates = gameAssets and gameAssets:FindFirstChild("Templates")
	local meshes = templates and templates:FindFirstChild("ObstacleMeshes")
	local template = meshes and meshes:FindFirstChild(name)
	if not template or not template:IsA("Model") then return nil end
	local copy = Instance.new("Model")
	copy.Name = "Scenery" .. name
	copy:SetAttribute("SceneryOnly", true)
	copy:SetAttribute("SharedArtFamily", name)
	copy:SetAttribute("ArtRevision", 1)
	for _, original in template:GetDescendants() do
		if original:IsA("BasePart") then
			local piece = original:Clone()
			-- Copy visual data only; never inherit scripts, prompts, constraints, lights or effects.
			for _, child in piece:GetDescendants() do
				if not (child:IsA("SurfaceAppearance") or child:IsA("SpecialMesh")) then child:Destroy() end
			end
			for attribute in piece:GetAttributes() do
				if attribute ~= "SourceComponent" then piece:SetAttribute(attribute, nil) end
			end
			piece.CFrame = template:GetPivot():ToObjectSpace(original.CFrame)
			piece.Anchored = true
			piece.CanCollide, piece.CanTouch, piece.CanQuery = false, false, false
			piece.CastShadow = false
			piece:SetAttribute("SceneryOnly", true)
			if original.Name == "Core" then
				piece.Transparency = 1
			elseif tint then
				if piece:IsA("MeshPart") then piece.TextureID = "" end
				-- PBR feather maps would override the tint; gilded statues read as polished metal instead.
				local pbr = piece:FindFirstChildOfClass("SurfaceAppearance")
				if pbr then pbr:Destroy() end
				piece.Color = tint
				piece.Material = Enum.Material.Metal
			end
			piece.Parent = copy
			if original.Name == "Core" then copy.PrimaryPart = piece end
		end
	end
	copy:ScaleTo(scale)
	copy:PivotTo(cf)
	copy.Parent = parent
	return copy
end

function Art.RestOn(copy: Model, surface: CFrame)
	copy:PivotTo(surface)
	local bottom = math.huge
	for _, piece in copy:GetDescendants() do
		if piece:IsA("BasePart") and piece ~= copy.PrimaryPart then
			local half = piece.Size / 2
			for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
				bottom = math.min(bottom, piece.CFrame:PointToWorldSpace(half * Vector3.new(x, y, z)).Y)
			end end end
		end
	end
	if bottom < math.huge then copy:PivotTo(copy:GetPivot() + Vector3.new(0, surface.Y - bottom - 0.08, 0)) end
end

function Art.Pose(copy: Model, phase: number, speed: number, amplitude: number): Pose
	local pose: Pose = {model = copy, wings = {}, phase = phase, speed = speed, amplitude = amplitude}
	local origin = copy:GetPivot()
	for _, piece in copy:GetDescendants() do
		if piece:IsA("BasePart") and (piece.Name == "Wing" or piece.Name == "WingTip") then
			local rest = origin:ToObjectSpace(piece.CFrame)
			local side = if rest.X < 0 then -1 else 1
			table.insert(pose.wings, {part = piece, rest = rest, side = side,
				hinge = Vector3.new(side * copy:GetScale() * 0.75, rest.Y, 0)})
		end
	end
	return pose
end

function Art.Animate(pose: Pose, time: number)
	local wave = math.sin(time * pose.speed + pose.phase) * pose.amplitude
	local origin = pose.model:GetPivot()
	for _, wing in pose.wings do
		wing.part.CFrame = origin * CFrame.new(wing.hinge)
			* CFrame.Angles(0, 0, wave * wing.side) * CFrame.new(-wing.hinge) * wing.rest
	end
end

local function plinth(parent: Instance, cf: CFrame, size: Vector3, color: Color3): BasePart
	local part = Instance.new("Part")
	part.Name = "HabitatPlinth"
	part.Size, part.CFrame, part.Color = size, cf, color
	part.Material = Enum.Material.Limestone
	part.Anchored = true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.CastShadow = false
	part:SetAttribute("SceneryOnly", true)
	part.Parent = parent
	return part
end

function Art.Ruins(parent: Instance, cf: CFrame, scale: number, index: number)
	local position = cf * CFrame.new(-20 * scale, 13.5 * scale, 14 * scale)
	local ruin = Art.Clone("Ruin" .. ((index - 1) % 3 + 1), parent, position, scale * 1.75)
	if ruin then Art.RestOn(ruin, position) end
	if index == 2 or index == 4 then
		local base = cf * CFrame.new(24 * scale, 13.5 * scale, 21 * scale)
		plinth(parent, base * CFrame.new(0, 0.8 * scale, 0), Vector3.new(10, 1.6, 8) * scale, STONE)
		local guardian = Art.Clone("GuardianDrone", parent, base * CFrame.new(0, 1.6 * scale, 0), scale * 1.4)
		if guardian then
			guardian.Name = "DormantGuardianEffigy"
			Art.RestOn(guardian, base * CFrame.new(0, 1.6 * scale, 0))
		end
	end
end

function Art.Frost(parent: Instance, cf: CFrame, scale: number)
	for i = 1, 3 do
		local frost = Art.Clone(if i == 1 then "Hailstone" else "Hailstone" .. i, parent,
			cf * CFrame.new((i - 2) * 4.2 * scale, 0, (i % 2) * 2.2 * scale)
				* CFrame.Angles(0.12, i * 1.9, 0.25), (0.75 + i * 0.12) * scale)
		if frost then frost.Name = "EmbeddedHailIce" end
	end
end

function Art.Crystals(parent: Instance, surface: CFrame, scale: number, count: number)
	for i = 1, count do
		local angle = (i - 1) * math.pi * 2 / count
		local pose = surface * CFrame.new(math.cos(angle) * 6 * scale, 0, math.sin(angle) * 5 * scale)
			* CFrame.Angles(0, angle, math.cos(angle) * 0.12)
		local crystal = Art.Clone("ChargedCrystal", parent, pose, (0.72 + (i % 2) * 0.25) * scale)
		if crystal then Art.RestOn(crystal, pose) end
	end
end

function Art.PhoenixCrest(parent: Instance, surface: CFrame, scale: number)
	plinth(parent, surface * CFrame.new(0, scale, 0), Vector3.new(14, 2, 11) * scale, STONE)
	local crest = Art.Clone("CelestialPhoenix", parent, surface * CFrame.new(0, 2 * scale, 0), scale, GOLD)
	if crest then
		crest.Name = "GildedPhoenixCrest"
		Art.RestOn(crest, surface * CFrame.new(0, 2 * scale, 0))
	end
end

function Art.PhantomMonument(parent: Instance, surface: CFrame, scale: number)
	plinth(parent, surface * CFrame.new(0, 0.6 * scale, 0), Vector3.new(8, 1.2, 7) * scale, rgb(99, 92, 137))
	local figure = Art.Clone("ShadowPhantom", parent, surface, scale * 1.7, rgb(147, 133, 177))
	if figure then Art.RestOn(figure, surface * CFrame.new(0, 1.2 * scale, 0)) end
end

return Art


