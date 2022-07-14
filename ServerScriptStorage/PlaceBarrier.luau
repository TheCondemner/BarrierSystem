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

local holdDurationB = 1.5
local holdDurationD = 6
local maxDistance = 4


---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Functions

local function buildBarrier(prompt, player)
	if prompt.Name == 'BuildPrompt' and prompt.Parent.Name == 'Unfinished Barrier' and player.Character:FindFirstChild('Wrench') then
		prompt.Parent:SetAttribute('BuildProgress', prompt.Parent:GetAttribute('BuildProgress') + 1)
	end	
end

local function destroyBarrier(prompt, player)
	if prompt.Name == 'DestroyPrompt' and prompt.Parent.Name == 'Barrier' and player.Character:FindFirstChild('Wrench') then
		--prompt.Parent:SetAttribute('BuildProgress', 0)
		local index = table.find(barrierList, prompt.Parent)
		table.remove(barrierList, index)
		prompt.Parent:Destroy()
	end
end

-- Remove barrier after 5 minutes
local function decayBarrier(barrier)
	wait(60*5)
	barrier:Destroy()
end

local function createPrompt(barrier, preset)
	local buildUI = Instance.new('ProximityPrompt')
	buildUI.Style = 'Custom'
	buildUI.MaxActivationDistance = maxDistance
	
	if preset == 'b' then
		buildUI.Name = 'BuildPrompt'
		buildUI.ObjectText = 'Build Barrier'
		buildUI.HoldDuration = holdDurationB
		buildUI.ActionText = barrier:GetAttribute('BuildProgress')..' / '..barrier:GetAttribute('Cost')
		
	elseif preset == 'd' then
		buildUI.Name = 'DestroyPrompt'		
		buildUI.ObjectText = 'Destroy Barrier'
		buildUI.HoldDuration = holdDurationD
		buildUI.ActionText = '8sec'
	end
	
	buildUI.Parent = barrier
	--return buildUI
end

-- Update The Barrier Status
local function updateBarrier(barrier)
	if barrier:GetAttribute('BuildProgress') >= barrier:GetAttribute('Cost') then
		barrier.Name = 'Barrier'
		barrier.Transparency = 0
		barrier.CanCollide = true
		barrier:FindFirstChild('BuildPrompt'):Destroy()
		
		createPrompt(barrier, 'd')
		
	else -- Allows barrier to regress in progress if damage system implemented
		if barrier.Name == 'Barrier' then
			barrier.Name = 'Unfinished Barrier'
			barrier.Transparency = 0.6
			barrier.CanCollide = false

			createPrompt(barrier, 'b')
			
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

	createPrompt(barrier, 'b')

	barrier:GetAttributeChangedSignal('BuildProgress'):Connect(function() updateBarrier(barrier) end)
	
	return barrier
end



PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == 'BuildPrompt' then buildBarrier(prompt, player)
	elseif prompt.Name == 'DestroyPrompt' then destroyBarrier(prompt, player) end
end)

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
	
	decayBarrier(barrierList[player][-1])
end)