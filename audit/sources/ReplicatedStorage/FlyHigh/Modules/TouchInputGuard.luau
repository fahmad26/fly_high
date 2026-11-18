--!strict
-- Guards GuiObject.InputBegan handlers so active touch drags started elsewhere on screen
-- (such as camera orbit or another UI surface) cannot trigger buttons when slid over.
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local TouchInputGuard = {}

type TouchRecord = {
	gpe: boolean,
	moved: boolean,
	startedAt: number,
	claimed: GuiObject?,
}

local touches: { [InputObject]: TouchRecord } = setmetatable({}, { __mode = "k" }) :: any
local pendingClaims: { [InputObject]: GuiObject } = setmetatable({}, { __mode = "k" }) :: any
local connected = false

local function registerTouch(input: InputObject, gpe: boolean)
	if input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local claimed = pendingClaims[input]
	local existing = touches[input]
	if existing then
		if gpe or claimed ~= nil then
			existing.gpe = true
		end
		if claimed and not existing.claimed then
			existing.claimed = claimed
		end
		return
	end
	touches[input] = {
		gpe = gpe or (claimed ~= nil),
		moved = false,
		startedAt = os.clock(),
		claimed = claimed,
	}
end

local function clearTouch(input: InputObject)
	touches[input] = nil
	pendingClaims[input] = nil
end

local function ensureConnected()
	if connected or not RunService:IsClient() then
		return
	end
	connected = true

	UserInputService.TouchStarted:Connect(registerTouch)
	UserInputService.InputBegan:Connect(registerTouch)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local record = touches[input]
		if record and input.Delta.Magnitude > 0 then
			record.moved = true
		end
	end)
	UserInputService.TouchEnded:Connect(clearTouch)
	UserInputService.InputEnded:Connect(clearTouch)
	UserInputService.WindowFocusReleased:Connect(function()
		table.clear(touches)
		table.clear(pendingClaims)
	end)
end

ensureConnected()

function TouchInputGuard.IsDirectBegin(guiObject: GuiObject?, input: InputObject?): boolean
	ensureConnected()
	if not input then
		return false
	end
	local inputType = input.UserInputType
	if inputType ~= Enum.UserInputType.Touch and inputType ~= Enum.UserInputType.MouseButton1 then
		return false
	end
	if input.UserInputState ~= Enum.UserInputState.Begin then
		return false
	end
	if inputType == Enum.UserInputType.MouseButton1 then
		return true
	end

	local record = touches[input]
	if record then
		if record.gpe == false or record.moved then
			return false
		end
		if guiObject and record.claimed and record.claimed ~= guiObject then
			return false
		end
		if os.clock() - record.startedAt > 0.08 then
			return false
		end
	elseif guiObject then
		local existingClaim = pendingClaims[input]
		if existingClaim and existingClaim ~= guiObject then
			return false
		end
	end

	if guiObject then
		pendingClaims[input] = pendingClaims[input] or guiObject
		if record then
			record.claimed = record.claimed or guiObject
		end
	end
	return true
end

return TouchInputGuard
