---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services

local RS = game:GetService('ReplicatedStorage')
local PPS = game:GetService('ProximityPromptService')

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables

local placeBarrierEvent = RS:WaitForChild('PlaceBarrier')

local barrierLimit = 2
local barrierCost = 4
local barrierList = {}

local holdDuration = 1.5
local maxDistance = 6

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Functions

local function buildBarrier(prompt, player)
	if prompt.Name == 'BuildPrompt' and prompt.Parent.Name == 'Unfinished Barrier' then
		prompt.Parent:SetAttribute('BuildProgress', prompt.Parent:GetAttribute('BuildProgress') + 1)
	end	
end

local function decayBarrier(barrier)
    wait(60*5)
    if barrier.Name == 'Barrier' then barrier:Destroy() end
end

-- Update The Barrier Status
local function updateBarrier(barrier)
	if barrier:GetAttribute('BuildProgress') >= barrier:GetAttribute('Cost') then
		barrier.Name = 'Barrier'
		barrier.Transparency = 0
		barrier.CanCollide = true
		barrier:FindFirstChild('BuildPrompt'):Destroy()
        decayBarrier(barrier)
	else -- Allows barrier to regress in progress if damage system implemented
		if barrier.Name == 'Barrier' then
            barrier.Name = 'Unfinished Barrier'
            barrier.Transparency = 0.6
            barrier.CanCollide = false
            
			local buildUI = Instance.new('ProximityPrompt')
			buildUI.Name = 'BuildPrompt'
			buildUI.HoldDuration = holdDuration
			buildUI.MaxActivationDistance = maxDistance
			buildUI.ObjectText = 'Build Barrier'
			buildUI.ActionText = barrier:GetAttribute('BuildProgress')..' / '..barrier:GetAttribute('Cost')
			buildUI.Parent = barrier
		else -- Update Barrier Text
			local buildUI = barrier:FindFirstChild('BuildPrompt')
			buildUI.ActionText = barrier:GetAttribute('BuildProgress')..' / '..barrier:GetAttribute('Cost')
		end
	end
end

local function placeBarrier(pos) 
	local barrier = RS:FindFirstChild('Barrier'):Clone()
	barrier.Name = 'Unfinished Barrier'
	barrier.CFrame = pos
	barrier.Transparency = 0.6
	barrier.CanCollide = false
	barrier:SetAttribute('Cost', barrierCost)
	barrier:SetAttribute('BuildProgress', 0)
	barrier.Parent = workspace
	
	local buildUI = Instance.new('ProximityPrompt')
	buildUI.Name = 'BuildPrompt'
	buildUI.HoldDuration = holdDuration
	buildUI.MaxActivationDistance = maxDistance
	buildUI.ObjectText = 'Build Barrier'
	buildUI.ActionText = barrier:GetAttribute('BuildProgress')..' / '..barrier:GetAttribute('Cost')
	buildUI.Parent = barrier
	
	barrier:GetAttributeChangedSignal('BuildProgress'):Connect(function() updateBarrier(barrier) end)
	
	return barrier
end



PPS.PromptTriggered:Connect(buildBarrier)

placeBarrierEvent.OnServerEvent:Connect(function(player, position)
	-- Track number of barriers per player and remove excess ones
	if not barrierList[player] then 
		barrierList[player] = {}
		table.insert(barrierList[player], placeBarrier(position))
	elseif #barrierList[player] < barrierLimit then 
		table.insert(barrierList[player], placeBarrier(position))
	else 
		barrierList[player][1]:Destroy()
		table.remove(barrierList[player], 1)
		table.insert(barrierList[player], placeBarrier(position)) 
	end
end)