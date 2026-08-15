--setup
local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/BullerWilliam/ui-modules/refs/heads/main/default.luau"))()
local decompilescript = loadstring(game:HttpGet("https://raw.githubusercontent.com/BullerWilliam/ui-modules/refs/heads/main/decompiler.luau"))()
local trigger, copy, xenoobject, executoridentifier, read, set = loadstring(game:HttpGet("https://raw.githubusercontent.com/BullerWilliam/ui-modules/refs/heads/main/utils.luau"))()
local tabs = {}
local values = {}
local threads = {}
local version = 1.1
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local plr = game.Players.LocalPlayer






--global vars





--main functions
local function reversetable(originaltable)
	local reversed = {}
	for i = #originaltable, 1, -1 do
		table.insert(reversed, originaltable[i])
	end
	return reversed
end

local function randomizetable(originaltable)
	local newtable = table.clone(originaltable)
	for i = #newtable, 2, -1 do
		local random = math.random(1, i)
		newtable[i], newtable[random] = newtable[random], newtable[i]
	end
	return newtable
end

local function moveparttotop(parts, targetpart)
	local newparts = {}
	if targetpart then
		table.insert(newparts, targetpart)
	end
	for _, part in ipairs(parts) do
		if part ~= targetpart then
			table.insert(newparts, part)
		end
	end
	return newparts
end






--window setup
local window
if executoridentifier then
	local executorname, executorversion = executoridentifier()
	window = ui:CreateWindow("Chameleon  ("..executorname.." "..executorversion..")")
else
	window = ui:CreateWindow("Chameleon")
end
local window_frame = window.frame





--tabs setup
tabs.Main = window:CreateTab("Main")
tabs.Other = window:CreateTab("Other")





--window values setup. example: (values.Automate = false)
values.Esp = true




--core functions
local function stopall()
	window_frame:Destroy()
	for _,thread in threads do
		task.cancel(thread)
	end
	script:Destroy()
end
window:setclosefunction(function()
	stopall()
end)
local function copysave()
	copy(window:Save())
end
local function saveasdefault()
	set("Chameleon/save.txt", window:Save())
end
local function loadsave()
	window:Load(values.Save)
end






--all functions
local function getroles()
	local roles = {}
	roles["seekers"] = {}
	roles["hiders"] = {}
	local frame:Frame = plr.PlayerGui.FullHUD.GameState.Participants
	for _, image:ImageLabel in ipairs(frame:GetDescendants()) do
		if image:IsA("ImageLabel") then
			if image.Parent.Name == "Seekers" then
				table.insert(roles["seekers"], game.Players:GetPlayerByUserId(image.Name))
			else
				table.insert(roles["hiders"], game.Players:GetPlayerByUserId(image.Name))
			end
		end
	end
	return roles
end
local function removeesp(player:Player)
	if player ~= plr then
		local character = player.Character
		if character then
			if character:FindFirstChild("esp") then
				character:FindFirstChild("esp"):Destroy()
			end
		end
	end
end
local function addesp(player:Player)
	if player ~= plr then
		local character = player.Character
		if character then
			removeesp(player)
			local highlight = Instance.new("Highlight")
			highlight.Parent = character
			highlight.FillColor = Color3.new(1, 0, 0)
			highlight.FillTransparency = 0
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		end
	end
end
local function addallesp()
	local roles = getroles()
	for _, player in ipairs(roles["hiders"]) do
		addesp(player)
	end
	for _, player in ipairs(roles["seekers"]) do
		removeesp(player)
	end
end
local function removeallesp()
	for _, player in ipairs(game.Players:GetPlayers()) do
		removeesp(player)
	end
end





--main tab
tabs.Main:Divider("Main Functions")
tabs.Main:Button("Close",function() stopall() end)

tabs.Main:Divider("Saves")
tabs.Main:Button("Save As Default",function() saveasdefault() end)
tabs.Main:Button("Save To Clipboard",function() copysave() end)
tabs.Main:Input("Save-String","Enter A Save-String Here",function(v) values.Save = v end)
tabs.Main:Button("Load Save From Save-String",function() loadsave() end)

tabs.Main:Divider("Executor Info")
if xenoobject then
	local info = xenoobject.about
	for k, v in pairs(xenoobject.about) do
		print(k, v)
	end
	tabs.Main:Label("Publisher", "Publisher: "..info["Publisher"])
	tabs.Main:Label("Name", "Name: "..info["Name"])
	tabs.Main:Label("Discord", "Discord: "..info["Discord"])
	tabs.Main:Label("Website", "Website: "..info["Website"])
	tabs.Main:Label("Version", "Version: "..info["Version"])
	tabs.Main:Label("Roblox Version", "Roblox Version: "..info["RobloxGameClientVersionHash"])
else
	tabs.Main:Label("Publisher", "Unknown Publisher")
	tabs.Main:Label("Name", "Unknown Executor")
	tabs.Main:Label("Discord", "No Discord Found")
	tabs.Main:Label("Website", "No Website Found")
	tabs.Main:Label("Version", "Unknown Version")
	tabs.Main:Label("Roblox Version", "Unknown Roblox Version")
end

--tabs
tabs.Other:Toggle("Esp", true, function(v) values.Esp = v end)
--tabs.Other:Input("Name", "Placeholder", test)
--tabs.Other:NumberInput("Amount", 10, test, 0, 100, 5)
--tabs.Other:PasswordInput("Password", "Secret", test)
--tabs.Other:TextArea("Notes", "Write more text", test)
--tabs.Other:SearchInput("Search", "Find something", test)
--tabs.Other:Slider("Volume", 0, 100, 50, test)
--tabs.Other:Keybind("Menu Key", Enum.KeyCode.RightShift, test)
--tabs.Other:ColorInput("Accent", Color3.fromRGB(75, 139, 255), test)
--tabs.Other:ThemePicker("Theme", Color3.fromRGB(255, 90, 120))
--tabs.Other:Label("status", "Ready")
--tabs.Other:SetLabelText("status", "Running")
--tabs.Other:Divider()
--tabs.Other:Divider("Section")
--tabs.Other:PlayerInput("Target", game.Players.LocalPlayer, test)
--tabs.Other:MultiPlayerInput("Targets", { game.Players.LocalPlayer }, test)




--startup code
if read("Chameleon/save.txt") then
	if read("Chameleon/save.txt") ~= "" then
		window:Load(read("Chameleon/save.txt"))
	end
end







--loops
table.insert(threads, task.spawn(function()
	while true do
		if values.Esp then
			addallesp()
		else
			removeallesp()
		end
		task.wait(1)
	end
end))