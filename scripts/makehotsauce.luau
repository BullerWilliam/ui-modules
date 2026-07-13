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
local player = game.Players.LocalPlayer






local dirtupgrades = {
	"UnlockSprinkler",
	"UnlockWaterTank",
	"UnlockSprinklerAddOn1",
	"UnlockSprinklerAddOn2",
	"UnlockGrass",
	"UnlockEnhancer1",
	"UnlockEnhancer2",
	"UnlockPortal",
	"UnlockSun",
	"UnlockLuckTotem"
}
local LuckUpgrades = require(game:GetService("ReplicatedStorage").Modules.Upgrades.LuckUpgrades)
local CustomerChanceUpgrades = require(game:GetService("ReplicatedStorage").Modules.Upgrades.CustomerChanceUpgrades)
local SeedAnimUpgrades = require(game:GetService("ReplicatedStorage").Modules.Upgrades.SeedAnimUpgrades)
local plotupgrades = {
	{
		remoteevent = game:GetService("ReplicatedStorage").Events.Upgrades.BuyLuck,
		getprice = function(current)
			local _, data = LuckUpgrades.GetLevelForLuck(current)
			return data and data.price or math.huge
		end,
		field = "LuckMultiplier"
	},
	{
		remoteevent = game:GetService("ReplicatedStorage").Events.Upgrades.BuyCustomerChance,
		getprice = function(current)
			return CustomerChanceUpgrades.PriceFor(current) or math.huge
		end,
		field = "CustomerChanceLevel"
	},
	{
		remoteevent = game:GetService("ReplicatedStorage").Events.Upgrades.BuySeedAnimTime,
		getprice = function(current)
			local _, data = SeedAnimUpgrades.GetLevelForTime(current)
			return data and data.price or math.huge
		end,
		field = "SeedAnimTime"
	},
}
local seedwaiting = false
local seedprice = 0
local seedpriceminimum = 5000
local fovConnection
local fovTween






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







local window

if executoridentifier then
	local executorname, executorversion = executoridentifier()
	window = ui:CreateWindow("🌶️ Make Hotsauce  ("..executorname.." "..executorversion..")")
else
	window = ui:CreateWindow("🌶️ Make Hotsauce")
end

local window_frame = window.frame
tabs.Main = window:CreateTab("Main")
tabs.Other = window:CreateTab("Other")






values.Automate = false





local function lockFOV(fov)
	if fovConnection then
		fovConnection:Disconnect()
	end
	fovConnection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera

		if not camera then
			return
		end
		if fovTween then
			fovTween:Cancel()
			fovTween:Destroy()
		end
		fovTween = TweenService:Create(
			camera,
			TweenInfo.new(0),
			{FieldOfView = fov}
		)
		fovTween:Play()
	end)
end
local function unlockFOV()
	if fovConnection then
		fovConnection:Disconnect()
		fovConnection = nil
	end
	if fovTween then
		fovTween:Cancel()
		fovTween:Destroy()
		fovTween = nil
	end
end
local function stopall()
	window_frame:Destroy()
	unlockFOV()
	for _,thread in threads do
		task.cancel(thread)
	end
	script:Destroy()
end
local function copysave()
	copy(window:Save())
end
local function saveasdefault()
	set("MakeHotSauce/save.txt", window:Save())
end
local function loadsave()
	window:Load(values.Save)
end
local function collectpepper(pepper)
	local remote = game:GetService("ReplicatedStorage").Events.Pepper.PickupPepper
	remote:InvokeServer(pepper)
end
local function collectcrop(crop:Model)
	for _, child in ipairs(crop:GetChildren()) do
		if child.Name == "Pepper" then
			collectpepper(child)
		end
	end
end
local function collectall()
	for _, child in ipairs(workspace.PlayerLots:FindFirstChild(player.Name):GetChildren()) do
		if child.Name == "Crop" then
			collectcrop(child)
		end
	end
end
local function droppepper(pepper)
	local uuid = pepper:GetAttribute("PepperUid")
	local valid = typeof(uuid) == "string"
	local name = valid and uuid or (pepper:GetAttribute("PepperName") or pepper.Name:gsub("^%s*%[[^%]]*%]%s*", ""))
	game.ReplicatedStorage.Events.Brewing.AddPepper:InvokeServer(valid, name)
end
local function getpepperamount(pepper)
	return pepper.Count.Value
end
local function lowerpepperamount(pepper:Tool)
	if pepper:FindFirstChild("Count") then
		pepper.Count.Value -= 1
	end
end
local function dropallpeppers()
	local peppers = {}
	for _, child in ipairs(player.Backpack:GetChildren()) do
		if child:GetAttribute("ItemType") == "Pepper" then
			table.insert(peppers, child)
		end
	end
	local char = player.Character or player.CharacterAdded:Wait()
	for _, child in ipairs(char:GetChildren()) do
		if child:GetAttribute("ItemType") == "Pepper" then
			table.insert(peppers, child)
		end
	end
	for _, pepper in ipairs(peppers) do
		task.spawn(function()
			for i = 1, getpepperamount(pepper) do
				task.spawn(function()
					droppepper(pepper)
					lowerpepperamount(pepper)
				end)
			end
		end)
	end
end
local function getmoney()
	return player.leaderstats.Money:GetAttribute("Amount")
end
local function getdirtid(dirt)
	local DirtLocks = require(game:GetService("ReplicatedStorage").Modules.DirtLocks)
	local Dirt = workspace.PlayerLots[player.Name].Dirt
	local layout = DirtLocks.BuildLayout(Dirt)
	local info = layout[dirt]
	local dirtId = info.id
	return dirtId
end
local function getdirtrow(dirt)
	local DirtLocks = require(game:GetService("ReplicatedStorage").Modules.DirtLocks)
	local Dirt = game.Workspace.PlayerLots[player.Name].Dirt
	local layout = DirtLocks.BuildLayout(Dirt)
	local info = layout[dirt]
	if info then
		local dirtId = info.row
		return dirtId
	else
		return nil
	end
end
local function getdirtprice(dirt)
	local lot = workspace.PlayerLots[player.Name]
	local Dirt = lot:WaitForChild("Dirt")
	local dirtlocks = require(game:GetService("ReplicatedStorage").Modules.DirtLocks)
	local layout = dirtlocks.BuildLayout(Dirt)
	local info = layout[dirt]
	if not info then
		return math.huge
	end
	return dirtlocks.PriceForRow(info.row)
end
local function getdirtprice2(dirt)
	return math.huge
end
local function getdirtpartfromid(dirtid)
	local lot = workspace.PlayerLots[player.Name]
	local Dirt = lot:WaitForChild("Dirt")
	local dirtlocks = require(game:GetService("ReplicatedStorage").Modules.DirtLocks)
	local layout = dirtlocks.BuildLayout(Dirt)
	for part, info in pairs(layout) do
		if info.id == dirtid then
			return part
		end
	end
	return nil
end
local function getdirtupgradeprice(upgradename, row)
	local Buttons = game:GetService("ReplicatedStorage").MiscModels.Buttons
	local upgradeModel = Buttons:FindFirstChild(upgradename)
	if not upgradeModel then
		return math.huge
	end
	local priceObj = upgradeModel:FindFirstChild("Price")
	local basePrice = priceObj and priceObj.Value or 0
	local dirtlocks = require(game:GetService("ReplicatedStorage").Modules.DirtLocks)
	local success, result = pcall(function()
		return dirtlocks.UpgradePrice(basePrice, row)
	end)
	if success then
		return result
	else
		return math.huge
	end
end
local function unlockdirt(dirt)
	local price = getdirtprice(dirt)
	if getmoney() >= price then
		local remote:RemoteFunction = game:GetService("ReplicatedStorage").Events.Plot.UnlockDirt
		remote:InvokeServer(dirt)
	end
end
local function unlockdirt2(dirt)
	local price = getdirtprice2(dirt)
	if getmoney() >= price then
		local remote:RemoteFunction = game:GetService("ReplicatedStorage").Events.Plot.BuyRow2Dirt
		remote:InvokeServer(dirt)
	end
end
local function unlockall()
	for _, child in ipairs(game.Workspace.PlayerLots:FindFirstChild(player.Name).Dirt:GetChildren()) do
		if child.Name == "Part" then
			unlockdirt(child)
		elseif string.find(child.Name, "Row2") then
			unlockdirt2(child)
		end
	end
end
local function upgradedirt(dirt)
	local remote:RemoteFunction = game:GetService("ReplicatedStorage").Events.Plot.BuyDirtUpgrade
	for _, upgrade in ipairs(dirtupgrades) do
		local price = getdirtupgradeprice(upgrade, getdirtrow(dirt))
		if getmoney() >= price then
			remote:InvokeServer(getdirtid(dirt), upgrade)
		end
	end
end
local function upgradealldirt()
	local dirts = {}
	for _, child in ipairs(game.Workspace:GetChildren()) do
		if string.find(child.Name, "DirtUpgrade") then
			local name = child.Name
			local dirtid = string.split(name, "_")[2]
			local dirtpart = getdirtpartfromid(dirtid)
			if dirtpart then
				table.insert(dirts, dirtpart)
			end
		end
	end
	for _, dirt in ipairs(dirts) do
		upgradedirt(dirt)
	end
end
local function upgradeplant(plant)
	local remote:RemoteFunction = game:GetService("ReplicatedStorage").Events.Upgrades.BuyPlantUpgrade
	remote:InvokeServer(plant)
end
local function getplantlevel(crop)
	if crop then
		return crop:GetAttribute("PeppersLevel")
	else
		return 100
	end
end
local function getplantupgradeprice(level)
	local PlantUpgrades = require(game:GetService("ReplicatedStorage").Modules.Upgrades.PlantUpgrades)
	return PlantUpgrades.PriceFor(level) or math.huge
end
local function getcropfromdirtid(dirtid)
	for _, inst in ipairs(game.Workspace.PlayerLots[player.Name]:GetDescendants()) do
		if inst:IsA("Model") and inst.Name == "Crop" then
			if inst:GetAttribute("DirtId") == dirtid then
				return inst
			end
		end
	end
	return nil
end
local function upgradeallplants()
	for _, child in ipairs(game.Workspace.PlayerLots:FindFirstChild(player.Name).Dirt:GetChildren()) do
		if child.Name == "Part" then
			if child:GetAttribute("Locked") ~= true then
				local price = getplantupgradeprice(getplantlevel(getcropfromdirtid(getdirtid(child))))
				if getmoney() >= price then
					local id = getdirtid(child)
					upgradeplant(id)
					task.wait(0.5)
				end
			end
		end
	end
end
local function promptseed()
	if not seedwaiting then
		local prompt:RemoteEvent = game:GetService("ReplicatedStorage").Events.SeedMachine.SpawnSeed
		local got:RemoteEvent = game:GetService("ReplicatedStorage").Events.SeedMachine.SeedSpawned
		seedwaiting = true
		prompt:FireServer()
		local info = got.OnClientEvent:wait()
		seedprice = info.Price
		seedwaiting = false
	end
end
local function buyseed()
	if getmoney() > seedprice then
		if seedprice >= seedpriceminimum then
			local remote:RemoteEvent = game:GetService("ReplicatedStorage").Events.SeedMachine.PickupSeed
			remote:FireServer()
		end
	end
end
local function getplotupgradeprice(id, currentValue)
	if id == 1 then
		-- Luck upgrades
		local LuckUpgrades = require(game:GetService("ReplicatedStorage").Modules.Upgrades.LuckUpgrades)
		local _, data = LuckUpgrades.GetLevelForLuck(currentValue)
		return data and data.price or math.huge

	elseif id == 2 then
		-- Customer chance upgrades
		local CustomerChanceUpgrades = require(game:GetService("ReplicatedStorage").Modules.Upgrades.CustomerChanceUpgrades)
		return CustomerChanceUpgrades.PriceFor(currentValue) or math.huge

	elseif id == 3 then
		-- Seed animation time upgrades
		local SeedAnimUpgrades = require(game:GetService("ReplicatedStorage").Modules.Upgrades.SeedAnimUpgrades)
		local _, data = SeedAnimUpgrades.GetLevelForTime(currentValue)
		return data and data.price or math.huge
	end
	return math.huge
end
local function buyallupgrades()
	local ok, data = pcall(function()
		return game:GetService("ReplicatedStorage").Events.UI.GetData:InvokeServer()
	end)

	if not ok or typeof(data) ~= "table" then
		return
	end

	while true do
		local money = getmoney()
		local boughtSomething = false

		for id, info in ipairs(plotupgrades) do
			local currentValue = data[info.field]
			if typeof(currentValue) ~= "number" then
				continue
			end

			local price = info.getprice(currentValue)
			if typeof(price) ~= "number" then
				continue
			end

			if money >= price then
				info.remoteevent:FireServer()
				boughtSomething = true

				-- refresh data after buying
				local ok2, newdata = pcall(function()
					return game:GetService("ReplicatedStorage").Events.UI.GetData:InvokeServer()
				end)
				if ok2 and typeof(newdata) == "table" then
					data = newdata
				end

				break
			end
		end

		if not boughtSomething then
			break
		end
	end
end
local function countemptysellingplates()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RemoteEvents = require(ReplicatedStorage.Modules.RemoteEvents)
	local SellingPlates = require(ReplicatedStorage.Modules.SellingPlates)
	local lot = workspace.PlayerLots[game.Players.LocalPlayer.Name]
	local plates = SellingPlates.GetPlates(lot)
	local empty = 0
	for _, data in ipairs(plates) do
		local plate = data.plate
		if plate and not plate:FindFirstChild("PlacedHotsauce") then
			empty += 1
		end
	end
	return empty
end
local function findfirsthotsauce()
	local backpack = game.Players.LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return nil end
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:GetAttribute("Hotsauce") == true then
			return tool
		end
	end
	return nil
end
local function placehotsauceonrandomplate()
	local player = game.Players.LocalPlayer
	local lot = workspace.PlayerLots[player.Name]
	local plates = require(game:GetService("ReplicatedStorage").Modules.SellingPlates).GetPlates(lot)
	local empty = {}
	for _, data in ipairs(plates) do
		local plate = data.plate
		if plate and not plate:FindFirstChild("PlacedHotsauce") then
			table.insert(empty, plate)
		end
	end
	if #empty == 0 then
		return false, "No empty plates"
	end
	local sauce = findfirsthotsauce()
	if not sauce then
		return false, "No hotsauce in backpack"
	end
	local sauceId = sauce:GetAttribute("HotsauceId")
	if typeof(sauceId) ~= "string" then
		return false, "Invalid hotsauceId"
	end
	local plate = empty[math.random(1, #empty)]
	game:GetService("ReplicatedStorage").Events.Selling.PlaceHotsauce:InvokeServer(plate, sauceId)
	return true, "Placed"
end
local function crafthotsauce()
	local ok, result = pcall(function()
		return game:GetService("ReplicatedStorage").Events.Brewing.Brew:InvokeServer()
	end)
	if result.ok then
		game:GetService("ReplicatedStorage").Events.Brewing.ClaimHotsauce:FireServer()
	end
end
local function getpricepfmultiplier()
	
end
local function upgrademultiplier()
	
	local remote = game:GetService("ReplicatedStorage").Events.Upgrades.BuySpicierSauce
	remote:FireServer()
	task.wait(0.3)
end






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

tabs.Other:Divider("Automating")
tabs.Other:Toggle("Automate The Game",false,function(v) values.Automate = v end)
tabs.Other:NumberInput("Minimum Price", 5000,function(v) seedpriceminimum = v end)

tabs.Other:Divider("Handle Something")
tabs.Other:Button("Collect All",function() collectall() end)









if read("MakeHotSauce/save.txt") then
	if read("MakeHotSauce/save.txt") ~= "" then
		window:Load(read("MakeHotSauce/save.txt"))
	end
end
lockFOV(70)








table.insert(threads, task.spawn(function()
	while true do
		if values.Automate then
			collectall()
			dropallpeppers()
			buyallupgrades()
			upgradealldirt()
			unlockall()
			buyseed()
			promptseed()
			task.wait(1)
		end
		task.wait(0.1)
	end
end))
table.insert(threads, task.spawn(function()
	while true do
		if values.Automate then
			upgradeallplants()
		end
		task.wait(0.1)
	end
end))
table.insert(threads, task.spawn(function()
	while true do
		if values.Automate then
			repeat
				task.wait()
			until countemptysellingplates() > 0
			crafthotsauce()
			task.wait(1)
			placehotsauceonrandomplate()
		end
		task.wait(0.1)
	end
end))