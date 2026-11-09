--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local cast = RaycastParams.new()
cast.FilterType = Enum.RaycastFilterType.Exclude
cast.RespectCanCollide = true

local effect = Instance.new("Part")
effect.Name = "LocalCloudFootsteps"
effect.Size = Vector3.one
effect.Transparency = 1
effect.Anchored = true
effect.CanCollide = false
effect.CanTouch = false
effect.CanQuery = false
effect.CastShadow = false
effect.Parent = workspace

local source = Instance.new("Attachment")
source.Parent = effect

local puff = Instance.new("ParticleEmitter")
puff.Texture = "rbxasset://textures/particles/smoke_main.dds"
puff.Color = ColorSequence.new(Color3.fromRGB(255, 250, 238), Color3.fromRGB(204, 225, 251))
puff.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.25),
	NumberSequenceKeypoint.new(0.4, 0.45),
	NumberSequenceKeypoint.new(1, 1),
})
puff.Size = NumberSequence.new(0.27, 0.95)
puff.Lifetime = NumberRange.new(0.28, 0.56)
puff.Speed = NumberRange.new(1, 3)
puff.SpreadAngle = Vector2.new(67, 67)
puff.Acceleration = Vector3.new(0, 1.5, 0)
puff.RotSpeed = NumberRange.new(-90, 90)
puff.LightInfluence = 0.15
puff.Rate = 0
puff.Enabled = false
puff.Parent = source

local flakes = Instance.new("ParticleEmitter")
flakes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
flakes.Color = ColorSequence.new(Color3.fromRGB(244, 249, 255))
flakes.Size = NumberSequence.new(0.16, 0)
flakes.Transparency = NumberSequence.new(0.15, 1)
flakes.Lifetime = NumberRange.new(0.18, 0.36)
flakes.Speed = NumberRange.new(1.4, 3.2)
flakes.SpreadAngle = Vector2.new(74, 74)
flakes.Acceleration = Vector3.new(0, -7, 0)
flakes.LightEmission = 0.25
flakes.Rate = 0
flakes.Enabled = false
flakes.Parent = source

local character: Model? = nil
local nextStep = 0
local side = 1

RunService.Heartbeat:Connect(function()
	local current = player.Character
	local root = current and current:FindFirstChild("HumanoidRootPart")
	if not current or not root or not root:IsA("BasePart") or root.Position.Y < 2500 then return end
	local now = os.clock()
	if now < nextStep then return end
	nextStep = now + 0.08
	local humanoid = current:FindFirstChildOfClass("Humanoid")
	local velocity = root.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	if not humanoid or humanoid.Health <= 0 or humanoid.FloorMaterial == Enum.Material.Air
		or humanoid.MoveDirection.Magnitude < 0.1 or speed < 2 then return end
	if current ~= character then
		character = current
		cast.FilterDescendantsInstances = {current}
		side = 1
	end
	local stride = root.CFrame.RightVector * (side * 0.45)
	local foot = workspace:Raycast(root.Position + stride, Vector3.new(0, -math.max(5, humanoid.HipHeight + root.Size.Y + 2), 0), cast)
	if not foot or not CollectionService:HasTag(foot.Instance, "PalaceWalkableCloud") then return end
	source.WorldPosition = foot.Position + Vector3.new(0, 0.08, 0)
	puff:Emit(5)
	flakes:Emit(3)
	nextStep = now + math.clamp(3.3 / speed, 0.17, 0.38)
	side = -side
end)

player:GetAttributeChangedSignal("PalaceArrival"):Connect(function()
	local arrival = player:GetAttribute("PalaceArrival")
	if typeof(arrival) ~= "Vector3" then return end
	local deadline = os.clock() + 2
	while os.clock() < deadline and player:GetAttribute("PalaceArrival") == arrival do
		local current = player.Character
		local root = current and current:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera
		if root and root:IsA("BasePart") and not root.Anchored and camera
			and camera.CameraType == Enum.CameraType.Custom and (root.Position - arrival).Magnitude < 10 then
			local focus = root.Position + Vector3.new(0, 2, 0)
			camera.Focus = CFrame.new(focus)
			camera.CFrame = CFrame.lookAt(focus + Vector3.new(0, -2, 13), focus)
			return
		end
		RunService.Heartbeat:Wait()
	end
end)
