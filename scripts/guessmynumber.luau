--if game.Players.LocalPlayer.Character.State.Value == "Guess" then
--	game.Players.LocalPlayer.Table.Value.Configuration.Events.Guess:FireServer(script.Parent.Name)
--else
--	game.Players.LocalPlayer.Table.Value.Configuration.Events.Choose:FireServer(script.Parent.Name)
--end
--script.Parent.Parent.Parent.Visible = false
local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/BullerWilliam/ui-modules/refs/heads/main/default.luau"))()


local auto_guess = false
local auto_choose = false
local auto_choose_value = 80

local function canguess()
	if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("GameGui") then
		if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("GameGui").Guess.Visible then
			return true
		else
			return false
		end
	else
		return nil
	end
end

local function isingame()
	if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("GameGui") then
		return true
	else
		return false
	end
end

local function gethighest()
	local higest = 1
	for i = 1, 100 do 
		if not game:GetService("Players").LocalPlayer.PlayerGui.GameGui.Guess.ScrollingFrame[tostring(i)].Wrong.Visible then
			higest = i
			break
		end
	end
	return higest
end

local function getlowest()
	local lowest = 1
	for i = 100, 1, -1 do 
		if not game:GetService("Players").LocalPlayer.PlayerGui.GameGui.Guess.ScrollingFrame[tostring(i)].Wrong.Visible then
			lowest = i
			break
		end
	end
	return lowest
end

local function guess(num)
	game.Players.LocalPlayer.Table.Value.Configuration.Events.Guess:FireServer(tostring(num))
end

local function choose(num)
	game.Players.LocalPlayer.Table.Value.Configuration.Events.Choose:FireServer(tostring(num))
end

local function getbestguess()
	local mid = math.round((gethighest() + getlowest()) / 2)
	return mid
end
local thread = task.spawn(function()
	while true do
		repeat
			task.wait()
		until isingame()
		local time2 = 1
		repeat
			if canguess() then
				if time2 == 1 and auto_choose then
					choose(auto_choose_value)
				elseif time2 > 1 then
					if auto_guess then
						print("my guess: "..getbestguess())
						guess(getbestguess())
					end
				end
				time2 += 1
			end
			task.wait()
		until not isingame()
	end
end)
local win = ui:CreateWindow("Guess My Number")
local tab = win:CreateTab("Main")
local function stopall()
	task.cancel(thread)
	win.frame:Destroy()
end
win:setclosefunction(function()
	stopall()
end)


tab:Divider("Main Functions")
tab:Button("Close",function() stopall() end)

tab:Divider("Automate")
tab:Toggle("Auto Guess",false,function(v) auto_guess = v end)
tab:Toggle("Auto Choose",false,function(v) auto_choose = v end)
tab:Input("Auto Choose Value",function(t) auto_choose_value = tonumber(t) or 1 end)
