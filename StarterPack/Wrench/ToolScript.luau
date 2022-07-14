---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services

local PPS = game:GetService('ProximityPromptService')

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables

local tool = script.Parent
local held = false

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Functions

tool.Equipped:Connect(function()
	held = true
end)

tool.Unequipped:Connect(function()
	held = false
end)

PPS.PromptShown:Connect(function(prompt)
	if prompt.Name == 'BuildPrompt' or prompt.Name == 'DestroyPrompt' then
		if held then
			prompt.Style = 'Default'
		end
	end
end)

PPS.PromptHidden:Connect(function(prompt)
	if prompt.Name == 'BuildPrompt' or prompt.Name == 'DestroyPrompt' then
		prompt.Style = 'Custom'
	end
end)