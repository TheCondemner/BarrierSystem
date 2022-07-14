---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services

local RS = game:GetService('ReplicatedStorage')
local UIS = game:GetService('UserInputService')

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables

local player = game:GetService('Players').LocalPlayer
local mouse = player:GetMouse()

local tool = script.Parent

local placeBarrierEvent = RS:WaitForChild('PlaceBarrier')
local preBarrier = nil

local hitbox = nil
local hitboxB = {}

local margins = {
	['x'] = 2,
	['y'] = 4,
	['y-'] = 0.2,
	['z'] = 2
}

local rotationAngle = 5 
local curRotation = 0
local rHeld = false

local enabled = false
local valid = true

local debounceM = false
local debounceR = false

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Functions

local function createHitBox(size, name)
	local part = Instance.new('Part')
	part.Name = name
	part.Transparency = 1
	part.Size = size
	part.CanCollide = false
	part.CanTouch = true
	part.Anchored = true
	part.Parent = preBarrier

	return part
end

local function initialize()
	preBarrier = RS:FindFirstChild('BarrierPreview'):Clone()
	preBarrier.Parent = workspace

	-- Create Hitboxes
	hitbox = createHitBox(Vector3.new(preBarrier.Size.X+margins['x'], preBarrier.Size.Y+margins['y'], preBarrier.Size.Z+margins['z']), 'MainHitBox')
	for i = 0, 3 do hitboxB[i] = createHitBox(Vector3.new(1, margins['y-'], 1), 'BottomHitBox_'..(i+1)) end -- Hitbox for 4 bottom corners to ensure that it is grounded

	-- Get a TouchInterest object for :GetTouchingParts()
	hitbox.Touched:Connect(function() end)
	for i = 0, 3 do hitboxB[i].Touched:Connect(function() end) end
end

local function mouseMoved() 
	if enabled and not debounceM then
		debounceM = true		
		
		
		mouse.TargetFilter = preBarrier

		local touchedPartsU = #hitbox:GetTouchingParts() == 0
		local touchedPartsB = #hitboxB[0]:GetTouchingParts() > 0; for i = 1, 3 do touchedPartsB = touchedPartsB and (#hitboxB[i]:GetTouchingParts() > 0) end -- Ensure that all 4 corner points are touching
		
		-- Validate Hitbox Detection
		valid = touchedPartsU and touchedPartsB

		-- Position All Hitboxes
		hitbox.Position = mouse.Hit.p + Vector3.new(0, 0.5*hitbox.Size.Y, 0)
		for z = 0, 1 do for x = 0, 1 do hitboxB[x+(z*2)].Position = mouse.Hit.p + Vector3.new((-1+(2*x))*0.5*preBarrier.Size.X, -0.5*hitboxB[x+(z*2)].Size.Y, (-0.5+z)*preBarrier.Size.Z) end end

		-- Only move preview if its valid
		if valid then
			preBarrier.BrickColor = BrickColor.new('Gold')
			preBarrier.Position = mouse.Hit.p + Vector3.new(0, 0.5*preBarrier.Size.Y, 0)
		else preBarrier.BrickColor = BrickColor.new('Really red') end
		
		
		debounceM = false
	end
end

mouse.Move:Connect(mouseMoved)

UIS.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.R and enabled and not debounceR then
		rHeld = true
		
		while rHeld  do
			debounceR = true
			
			preBarrier.CFrame *= CFrame.Angles(0, math.rad(rotationAngle), 0)
			hitbox.CFrame *= CFrame.Angles(0, math.rad(rotationAngle), 0)
			
			debounceR = false
			
			wait(1/15)
		end
	end 
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.R then
		rHeld = false
	end
end)

mouse.Button1Down:Connect(function()
	if enabled and valid then
		-- Possibly add functionality of sending Hitbox positions to server for extra validation?
		placeBarrierEvent:FireServer(preBarrier.CFrame, player.UserId)
	end
end)

tool.Equipped:Connect(function() 
	initialize()
	enabled = true	
	mouseMoved()
end)

tool.Unequipped:Connect(function()
	enabled = false
	if preBarrier then
		preBarrier:Destroy()
		preBarrier = nil
	end
end)