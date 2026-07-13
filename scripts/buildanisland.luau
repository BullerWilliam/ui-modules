local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/BullerWilliam/ui-modules/refs/heads/main/default.luau"))()
local decompilescript = loadstring(game:HttpGet("https://raw.githubusercontent.com/BullerWilliam/ui-modules/refs/heads/main/decompiler.luau"))()
local trigger, copy, xenoobject, executoridentifier, read, set = loadstring(game:HttpGet("https://raw.githubusercontent.com/BullerWilliam/ui-modules/refs/heads/main/utils.luau"))()
local tabs = {}
local values = {}
local threads = {}
local version = 1.1
local breakwaiting = 0
local toolsupgrade = {
	"Pickaxe",
	"Axe",
	"FishingRod"
}
local landmarks = {
	"Big Ben",
	"Statue of Liberty",
	"Eiffel Tower",
	"Burj Khalifa"
}
local doublecrafters = {
	"S134",
	"S281",
	"S106",
	"S23",
	"S214",
	"S78"
}
local crafters = {
	"S13",
	"S178",
	"S24",
	"S72",
	"S54",
	"S23",
	"S106",
	"S281",
	"S108",
	"S134",
	"S164",
	"S214"
}
local recipes = {
	["Plank"] = {
		Items = {
			{Name="Log",Amount=3},
		},
		Crafter="S13"
	},
	["Haybale"] = {
		Items = {
			{Name="Wheat",Amount=4},
		},
		Crafter="S178"
	},
	["Brick"] = {
		Items = {
			{Name="Stone",Amount=3},
		},
		Crafter="S24"
	},
	["Bamboo Plank"] = {
		Items = {
			{Name="Bamboo",Amount=5},
		},
		Crafter="S72"
	},
	["Cactus Fiber"] = {
		Items = {
			{Name="Cactus",Amount=5},
		},
		Crafter="S54"
	},
	["Iron Bar"] = {
		Items = {
			{Name="Log",Amount=5},
			{Name="Iron Ore",Amount=10},
		},
		Crafter="S23"
	},
	["Magmite"] = {
		Items = {
			{Name="Magma Crystal",Amount=5},
			{Name="Iron Bar",Amount=3},
		},
		Crafter="S106"
	},
	["Cement"] = {
		Items = {
			{Name="Sand",Amount=10},
			{Name="Stone",Amount=20},
		},
		Crafter="S281"
	},
	["Magma Plank"] = {
		Items = {
			{Name="Magma Log",Amount=10},
		},
		Crafter="S108"
	},
	["Obsidian Glass"] = {
		Items = {
			{Name="Obsidian",Amount=15},
			{Name="Magma Plank",Amount=1},
		},
		Crafter="S134"
	},
	["Mushroom Plank"] = {
		Items = {
			{Name="Mushroom",Amount=15},
		},
		Crafter="S164"
	},
	["Salt Bag"] = {
		Items = {
			{Name="Salt",Amount=20},
			{Name="Mushroom Plank",Amount=3},
		},
		Crafter="S214"
	},
}
local targetexpand = nil
local shopitems = {
	"Corn Seeds",
	"Coal Crate",
	"Honey Bee",
	"Busy Bee Potion",
	"Growth Potion",
	"Strawberry Seeds",
	"Autochopper Mk 1",
	"Autominer Mk 1",
	"Tomato Seeds",
	"Blueberry Seeds",
	"Apple Seeds",
	"Watermelon Seeds",
	"Strength Potion",
	"Resource Potion",
	"Multicast Potion",
	"Magic Durian Seeds",
	"Magma Bee",
	"Galaxy Potion",
	"Peach Seeds",
	"Pumpking Seeds",
	"Cherry Seeds",
	"Starfruit Seeds",
	"Mango Seeds",
	"Goji Berry Seeds",
	"Dragonfruit Seeds",
	"Coconut Seeds",
	"Pineapple Seeds"
}
local goldupgrades = {
	"CraftingTime",
	"RegrowthTime",
	"SpeedBoost",
	"CropGrowth",
	"GoldenChance",
	"OfflineEarnings",
	"BeeHiveSpeed",
	"CollectorTime",
	"FishCrateCapacity",
}
local neededgoldupgrades = {
	1,
	6,
	5,
	7,
	4,
	3,
	8,
	9,
	2,
}
local potionshops = {
	["Resource Potion"] = {
		Items = {
			{Name="Magmite",Amount=30},
			{Name="Watermelon",Amount=1},
		},
		Crafter="S134"
	},
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = game.Players.LocalPlayer

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

if xenoobject then
	local executorname, executorversion = executoridentifier()
	window = ui:CreateWindow("Build an island🏝️  ("..executorname.." "..executorversion..")")
else
	window = ui:CreateWindow("Build an island🏝️")
end

local window_frame = window.frame
tabs.Main = window:CreateTab("Main")
tabs.Fish = window:CreateTab("Fish")
tabs.Craft = window:CreateTab("Craft")
tabs.Workers = window:CreateTab("Workers")
tabs.Buy_Sell = window:CreateTab("Buy/Sell")
tabs.Monitoring = window:CreateTab("Monitoring")
tabs.Other = window:CreateTab("Other")

values.AutoCollectFish = true
values.AutoSellWhenFull = true
values.FishAmount = 100
values.WorkersLumbers = {"Log", "Log", "Log", "Log", "Log"}
values.WorkersMiners = {"Stone", "Stone", "Stone", "Stone"}
values.WorkersCrafters = {"Plank", "Plank", "Plank", "Plank"}
values.WorkersZookeepers = {"Poop", "Poop", "Poop"}
values.AutoRessource = false
values.AutoBuyShop = reversetable(shopitems)
values.Save = ""

values.Automate = {}
values.Automate.RandomizeExpand = false
values.Automate.Potions = true

local expands = workspace.Plots:findFirstChild(player.Name).Expand:GetChildren()

local function hasfishingtile()
	if workspace.Plots:findFirstChild(player.Name).Land:findFirstChild("S252") then
		return true
	else
		return false
	end
end
local function collectfish()
	ReplicatedStorage.Communication.CollectFishCrateContents:FireServer()
end
local function getfishamount()
	local text = workspace.Plots:findFirstChild(player.Name).Land.S252.FISHCRATE.PromptPart.Top.BillboardGui.Amount.Text
	local current, max = string.match(text, "(%d+)%s*/%s*(%d+)")
	return tonumber(current)
end
local function getfishmaxamount()
	local text = workspace.Plots:findFirstChild(player.Name).Land.S252.FISHCRATE.PromptPart.Top.BillboardGui.Amount.Text
	local current, max = string.match(text, "(%d+)%s*/%s*(%d+)")
	return tonumber(max)
end
local function gotofishingspot()
	if workspace.Plots:findFirstChild(player.Name).Land:findFirstChild("S252") then
		local fishingspot = workspace.Plots:findFirstChild(player.Name).Land.S252:findFirstChild("FishingRegion")
		local char:Model = player.Character or player.ChildAdded:Wait()
		char:PivotTo(fishingspot.CFrame)
	end
end
local function getplayerpos(plr)
	local char:Model = game
	if plr then
		char = plr.Character or plr.CharacterAdded:Wait()
	else
		char = player.Character or player.CharacterAdded:Wait()
	end
	local pos = char:WaitForChild("HumanoidRootPart").Position
	return pos
end
local function fish_spawnfish(pos, nr, waitthing)
	local remote = ReplicatedStorage:WaitForChild("Communication"):WaitForChild("Fish")
	if waitthing then
		remote:InvokeServer(pos, nr)
	else
		task.spawn(function()
			remote:InvokeServer(pos, nr)
		end)
	end
end
local function sellall()
	local remote = game:GetService("ReplicatedStorage").Communication.SellToMerchant
	remote:FireServer(1)
end
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
local function spawnafishdrop(plr)
	local mainpos = getplayerpos(plr)
	local pos = mainpos + Vector3.new(math.random(-30, 30), 20, math.random(-10, 10))
	fish_spawnfish(pos, 1)
end
local function fishrain(plr)
	table.insert(threads, task.spawn(function()
		for i = 1, 300 do
			spawnafishdrop(plr)
		end
	end))
end
local function fishrainall()
	local pos = getplayerpos(player)
	local char = player.Character or player.CharacterAdded:Wait()
	for _, newplr in ipairs(game.Players:GetPlayers()) do
		if player ~= newplr then
			local newchar = newplr.Character or newplr.CharacterAdded:Wait()
			local newpos = newchar:GetPivot()
			if true then
				char:PivotTo(newpos)
				task.wait(1)
				fishrain(newplr)
				task.wait(1)
			end
		end
	end
	char:PivotTo(CFrame.new(pos))
end
local function isbackpackoverflowing()
	for _, noti:Frame in ipairs(game:GetService("Players").LocalPlayer.PlayerGui.Main.NotificationHold:GetChildren()) do
		if noti.Name == "Example" then
			if noti:FindFirstChild("TextLabel") then
				if string.find(noti.TextLabel.Text, "Backpack overflowing!") then
					return true
				end
			end
		end
	end
	return false
end
local function collectfriendgold()
	local remote = game:GetService("ReplicatedStorage").Communication.CollectFriendGold
	remote:FireServer()
end
local function getfriendgoldamount()
	local realtext = game:GetService("Players").LocalPlayer.PlayerGui.SurfaceGuis.ChestUI.Main.GoldCount.Text
	local text = string.sub(realtext, 1, string.len(realtext) -1)
	local current, max = string.match(text, "(%d+)%s*/%s*(%d+)")
	return tonumber(current)
end
local function getfriendgoldmaxamount()
	local realtext = game:GetService("Players").LocalPlayer.PlayerGui.SurfaceGuis.ChestUI.Main.GoldCount.Text
	local text = string.sub(realtext, 1, string.len(realtext) -1)
	local current, max = string.match(text, "(%d+)%s*/%s*(%d+)")
	return tonumber(max)
end
local function harvestall()
	local remote = game:GetService("ReplicatedStorage").Communication.Harvest
	for _, plant in ipairs(workspace.Plots:findFirstChild(player.Name).Plants:GetChildren()) do
		remote:FireServer(plant.Name)
	end
end
local function breakressource(plant:Part)
	task.spawn(function()
		local hp = plant:GetAttribute("HP")
		if hp then
			if hp > 0 then
				repeat
					game:GetService("ReplicatedStorage").Communication.HitResource:FireServer(plant)
					task.wait(0.5)
					hp = plant:GetAttribute("HP")
				until hp == 0
			end
		end
		breakwaiting -= 1
	end)
end
local function harvestallclovers()
	for _, plant in ipairs(workspace.RainbowIsland.Resources:GetChildren()) do
		breakressource(plant)
	end
end
local function hasrainbowisland()
	if workspace:FindFirstChild("RainbowIsland") then
		return true
	else
		return false
	end
end
local function buyrainbowchest()
	local prompt:ProximityPrompt = workspace.RainbowIsland.FloatingIsland.RewardChest.Hitbox.Attachment.ProximityPrompt
end
local function makeallboatsmine()
	for _, boat:Part in ipairs(workspace.Boats:GetChildren()) do
		if boat:IsA("Model") then
			boat.Owner.Value = player
		end
	end
end
local function getallressources()
	for _, ressource in ipairs(workspace.Plots:findFirstChild(player.Name).Resources:GetChildren()) do
		breakwaiting += 1
		breakressource(ressource)
	end
	if #workspace.GlobalResources:GetChildren() > 0 then
		for _, ressource in ipairs(workspace.GlobalResources:GetChildren()) do
			breakwaiting += 1
			breakressource(ressource)
		end
	end
	repeat
		task.wait()
	until breakwaiting <= 15
end
local function getlistofmaterialsfortarget(targetexpand2)
	local list = {}
	if targetexpand2:findFirstChild("Top") then
		for _, child:Frame in ipairs(targetexpand2.Top.BillboardGui:GetChildren()) do
			if child:IsA("Frame") then
				if child.Name ~= "Example" then
					local text = child.Amount.Text
					local current, max = string.match(text, "(%d+)%s*/%s*(%d+)")
					table.insert(list, {Name=child.Name, Amount=math.clamp(tonumber(max) - tonumber(current), 0, 1000000)})
				end
			end
		end
	end
	return list
end
local function getlistofmaterialsforlandmark(landmark)
	local ui:BillboardGui
	for _, uis in ipairs(player.PlayerGui.SurfaceGuis:GetChildren()) do
		if uis.Name == "LandmarkUI" then
			if uis.Main.Title.Text == landmark.Parent.LandmarkName.Value then
				ui = uis
				break
			end
		end
	end
	if ui then
		local list = {}
		if ui:FindFirstChild("Main") then
			if ui:FindFirstChild("Main"):FindFirstChild("Hold") then
				for _, child:Frame in ipairs(ui:FindFirstChild("Main"):FindFirstChild("Hold"):GetChildren()) do
					if child:IsA("ImageLabel") then
						if child.Name ~= "Example" then
							local text = child.Title.Text
							local current, max = string.match(text, "(%d+)%s*/%s*(%d+)")
							table.insert(list, {Name=child.Name, Amount=tonumber(max)})
						end
					end
				end
			end
		end
		return list
	else
		return {}
	end
end
local function getlistofmaterialsfortoolupgrade(upgradename)
	local ui:BillboardGui
	for _, uis in ipairs(player.PlayerGui.SurfaceGuis:GetChildren()) do
		if uis.Name == "UpgradeUI" then
			if uis.Main.Title.Text == "Upgrade "..upgradename then
				ui = uis
				break
			end
		end
	end
	if ui then
		local list = {}
		if ui:FindFirstChild("Main") then
			if ui:FindFirstChild("Main"):FindFirstChild("Hold") then
				for _, child:Frame in ipairs(ui:FindFirstChild("Main"):FindFirstChild("Hold"):GetChildren()) do
					if child:IsA("ImageLabel") then
						if child.Name ~= "Example" then
							local text = child.Title.Text
							local current, max = string.match(text, "(%d+)%s*/%s*(%d+)")
							table.insert(list, {Name=child.Name, Amount=math.clamp(tonumber(max) - tonumber(current), 0, 1000000)})
						end
					end
				end
			end
		end
		return list
	else
		return {}
	end
end
local function stringtonumber(text)
	text = tostring(text):upper():gsub("%s+", "")
	local multipliers = {
		K = 1000,
		M = 1000000,
		B = 1000000000,
		T = 1000000000000,
		QD = 1000000000000000,
		QN = 1000000000000000000
	}
	local numberPart, suffix = text:match("^([%d%.]+)(%a*)$")
	local number = tonumber(numberPart)
	if not number then
		return nil
	end
	if suffix == "" then
		return number
	end
	local multiplier = multipliers[suffix]
	if not multiplier then
		return nil
	end
	return number * multiplier
end
local function getcurrentressources()
	local list = {}
	for _, ressource in ipairs(game:GetService("Players").LocalPlayer.PlayerGui.Main.Left.Currencies:GetChildren()) do
		if ressource:findFirstChild("Display") then
			list[ressource.Name] = tonumber(stringtonumber(ressource.Display.Text))
		end
	end
	for _, ressource in ipairs(game:GetService("Players").LocalPlayer.PlayerGui.Main.Left.Currencies2.Hold:GetChildren()) do
		if ressource:findFirstChild("Display") then
			list[ressource.Name] = tonumber(stringtonumber(ressource.Display.Text))
		end
	end
	return list
end
local function craft(crafter)
	local attatch = workspace.Plots:findFirstChild(player.Name):FindFirstChild("Land"):FindFirstChild(crafter):FindFirstChild("Crafter"):FindFirstChild("Attachment")
	if table.find(doublecrafters, crafter) then
		game:GetService("ReplicatedStorage").Communication.DoubleCraft:FireServer(attatch)
	else
		game:GetService("ReplicatedStorage").Communication.Craft:FireServer(attatch)
	end
end
local function getressourceamount(ressource, amount)
	if recipes[ressource] then
		local enough = true
		local newitemslist = recipes[ressource]["Items"]
		for _, newitem in ipairs(newitemslist) do
			if not ((getcurrentressources()[newitem["Name"]] or 0) >= newitem["Amount"]) then
				enough = false
			end
		end
		if enough then
			craft(recipes[ressource]["Crafter"])
		else
			for _, item in ipairs(newitemslist) do
				getressourceamount(item["Name"], item["Amount"])
			end
		end
	else
		repeat
			getallressources()
			task.wait()
		until (getcurrentressources()[ressource] or 0) >= amount
	end
	return true
end
local function completetarget(targetexpand2)
	local list = getlistofmaterialsfortarget(targetexpand2)
	local need = #list
	for _, item in ipairs(list or {}) do
		getressourceamount(item.Name, item.Amount)
		local char = player.Character or player.CharacterAdded:Wait()
		need -= 1
	end
	return true
end
local function hasfriendgoldchest()
	if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("SurfaceGuis"):FindFirstChild("ChestUI") then
		return true
	else
		return false
	end
end
local function givecoaltomine(mine)
	local remote = game:GetService("ReplicatedStorage").Communication.Goldmine
	remote:FireServer(mine.Name, 1)
end
local function collectcoinfrommine(mine)
	local remote = game:GetService("ReplicatedStorage").Communication.Goldmine
	remote:FireServer(mine.Name, 2)
end
local function collectallcoinsfrommines()
	local mines = {
		workspace.Plots:findFirstChild(player.Name):findFirstChild("Land"):findFirstChild("S8"),
		workspace.Plots:findFirstChild(player.Name):findFirstChild("Land"):findFirstChild("S90"),
	}
	for _, mine in ipairs(mines) do
		collectcoinfrommine(mine)
	end
end
local function givecoaltoallmines()
	local mines = {
		workspace.Plots:findFirstChild(player.Name):findFirstChild("Land"):findFirstChild("S8"),
		workspace.Plots:findFirstChild(player.Name):findFirstChild("Land"):findFirstChild("S90"),
	}
	for i = 1, 10 do
		for _, mine in ipairs(mines) do
			givecoaltomine(mine)
		end
	end
end
local function setworkerressource(category, worker, ressource)
	local categories = {"Lumberjack", "Miner", "Crafter", "Zookeeper", "Fisherman"}
	local remote = game:GetService("ReplicatedStorage").Communication.SetWorkerResource
	remote:FireServer(categories[category], worker, ressource)
end
local function setworkersincate(cate)
	local list = {}
	if cate == 1 then
		list = values.WorkersLumbers
	elseif cate == 2 then
		list = values.WorkersMiners
	elseif cate == 3 then
		list = values.WorkersCrafters
	else
		list = values.WorkersZookeepers
	end
	for worker, ressource in ipairs(list) do
		setworkerressource(cate, worker, ressource)
	end
end
local function collectdailyreward()
	for i = 1, 25 do
		local remote = game:GetService("ReplicatedStorage").Communication.ClaimDailyReward
		remote:FireServer(i)
	end
end
local function claimtimedreward(id)
	local ids = {
		"rewardOne",
		"rewardTwo",
		"rewardThree",
		"rewardFour",
		"rewardFive",
		"rewardSix",
		"rewardSeven",
		"rewardEight",
		"rewardNine",
		"rewardTen",
		"rewardEleven",
		"rewardTwelve"
	}
	game:GetService("ReplicatedStorage").Communication.ClaimTimedReward:InvokeServer(ids[id])
end
local function claimalltimesrewards()
	for i = 1, 12 do
		claimtimedreward(i)
	end
end
local function hireworker(category, worker)
	local categories = {"Lumberjack", "Miner", "Crafter", "Zookeeper", "Fisherman"}
	local remote = game:GetService("ReplicatedStorage").Communication.HireWorker
	remote:FireServer(categories[category], worker)
end
local function hireallworkers()
	for i = 1, 5 do
		hireworker(1, i)
	end
	for i = 1, 4 do
		hireworker(2, i)
	end
	for i = 1, 4 do
		hireworker(3, i)
	end
	for i = 1, 3 do
		hireworker(4, i)
	end
	for i = 1, 3 do
		hireworker(5, i)
	end
	task.wait(0.5)
	for i = 1, 4 do
		task.spawn(function()
			setworkersincate(i)
		end)
	end
end
local function setlockitem(item:Tool, locked)
	local itemkey = item:GetAttribute("Hash")
	local remote = game:GetService("ReplicatedStorage").Communication.SetLockItem
	remote:FireServer(tostring(itemkey), locked)
end
local function lockneededitems()
	for i = 1, 2 do
		for _, tool in ipairs(player.Backpack:GetChildren()) do
			local lock = false
			if string.find(tool:GetAttribute("ITEM"), "Potion") then
				lock = true
			elseif string.find(tool:GetAttribute("ITEM"), "Seeds") then
				lock = true
			elseif string.find(tool:GetAttribute("ITEM"), "Watermelon") then
				lock = true
			elseif tool:GetAttribute("Category") == "Animal" then
				lock = true
			end
			if lock then
				setlockitem(tool, true)
			end
		end
		task.wait(2)
	end
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		local lock = false
		if string.find(tool:GetAttribute("ITEM"), "Potion") then
			lock = true
		elseif string.find(tool:GetAttribute("ITEM"), "Seeds") then
			lock = true
		elseif tool:GetAttribute("Category") == "Animal" then
			lock = true
		end
		if lock and (not string.find(tool.Name, "_Locked_true")) then
			tool:Destroy()
		end
	end
end
local function lockallitems()
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		setlockitem(tool, true)
	end
end
local function buyitem(item)
	local remote = game:GetService("ReplicatedStorage").Communication.BuyFromMerchant
	remote:FireServer(item)
end
local function completeexpand(part)
	local remote = game:GetService("ReplicatedStorage").Communication.ContributeToExpand
	local items = {}
	for _, item:Frame in ipairs((part:findFirstChild("Top"):findFirstChild("BillboardGui"):GetChildren()) or {}) do
		if item:IsA("Frame") and item.Name ~= "Example" then
			local text = item:findFirstChild("Amount").Text
			local numbertext = string.sub(text, string.find(text, "/") + 1, string.len(text))
			local numbertextcurrent = string.sub(text, 1, string.find(text, "/") - 1)
			local number = tonumber(numbertext)
			local numbercurrent = tonumber(numbertextcurrent)
			local itemname = item.Name
			local amount = number
			table.insert(items, {
				["Name"] = itemname,
				["Amount"] = amount,
				["Current"] = numbercurrent
			})
		end
	end
	for _, item in ipairs(items) do
		local itemname = item["Name"]
		local amount = item["Amount"]
		local current = item["Current"]
		local give = math.clamp(amount - current, 0, (getcurrentressources()[itemname] or 0))
		remote:FireServer(part.Name, itemname, give)
	end
end
local function doallexpand()
	local list = workspace.Plots:findFirstChild(player.Name):findFirstChild("Expand"):GetChildren()
	if values.Automate.RandomizeExpand then
		list = randomizetable(list)
	end
	if targetexpand then
		list = moveparttotop(list, targetexpand)
	end
	for _, expand in ipairs(list) do
		task.spawn(function()
			completeexpand(expand)
		end)
	end
end
local function copysave()
	copy(window:Save())
end
local function saveasdefault()
	set("BuildAnIsland/save.txt", window:Save())
end
local function loadsave()
	window:Load(values.Save)
end
local function teleporttotarget()
	player.Character:PivotTo(CFrame.new(targetexpand.Position + Vector3.new(0, 2, 0)))
end
local function getcraftercrafting(crafter)
	local craftermodel = workspace.Plots:findFirstChild(player.Name):findFirstChild("Land"):findFirstChild(crafter)
	local ui = craftermodel.Crafter.Attachment.UI.Value
	local currentmaking = tonumber(ui.Progress.Title.Text)
	return currentmaking
end
local function craftall()
	for _, crafter in ipairs(crafters) do
		local currentmaking = getcraftercrafting(crafter)
		if currentmaking < 30 then
			for i = 1, 3 do
				task.spawn(function()
					craft(crafter)
				end)
			end
		end
	end
end
local function handleworldtree()
	if workspace.GlobalResources:findFirstChild("World Tree") then
		if workspace.GlobalResources["World Tree"]["1"].Part50 then
			breakressource(workspace.GlobalResources["World Tree"])
		end
	end
end
local function buildalllandmarks()
	for _, landmark in ipairs(landmarks) do
		game:GetService("ReplicatedStorage").Communication.BuildLandmark:FireServer(landmark)
	end
end
local function redeemallcodes()
	local codes = {
		"SKY",
		"SWAMP",
		"SAKURA",
		"100MVISITS",
		"MOUNTAIN",
		"ANIMALS",
		"VOLCANO",
		"2000Follows",
		"FreeGold",
		"Autochoppers",
		"Hype"
	}
	for _, code in ipairs(codes) do
		local remotefunction = game:GetService("ReplicatedStorage").Communication.RedeemCode
		local result = remotefunction:InvokeServer(code)
	end
end
local function buygoldupgrade(nr)
	local upgrade = goldupgrades[nr]
	local remote = game:GetService("ReplicatedStorage").Communication.DoGoldUpgrade
	remote:FireServer(upgrade)
end
local function buyneededgoldupgrades()
	for _, upgrade in pairs(neededgoldupgrades) do
		for i = 1, 15 do
			buygoldupgrade(upgrade)
		end
	end
end
local function getattatchmentforlandmark(landmark):Attachment
	local plot = workspace.Plots:findFirstChild(player.Name):findFirstChild("Land"):findFirstChild(landmark)
	local attatch
	if plot then
		for _, part:Part in ipairs(plot:GetChildren()) do
			if part:IsA("BasePart") then
				if part:FindFirstChildWhichIsA("Attachment") then
					attatch = part:FindFirstChildWhichIsA("Attachment")
					break
				end
			end
		end
	end
	return attatch
end
local function islandmarkbuildable(attatchment)
	local ui:BillboardGui
	for _, uis in ipairs(player.PlayerGui.SurfaceGuis:GetChildren()) do
		if uis.Name == "LandmarkUI" then
			if uis.Main.Title.Text == attatchment.Parent.LandmarkName.Value then
				ui = uis
				break
			end
		end
	end
	if ui then
		if ui.Main.Collect.TextLabel.Visible then
			return true
		else
			return false
		end
	else
		return false
	end
end
local function upgradetool(tool)
	local remote = game:GetService("ReplicatedStorage").Communication.Upgrade
	remote:FireServer(tool)
end
local function upgradealltools()
	for _, tool in ipairs(toolsupgrade) do
		for i = 1, 5 do
			upgradetool(tool)
		end
	end
end
local function craftallneeded()
	local plot = workspace.Plots:findFirstChild(player.Name)
	if not plot then return end
	local expandfolder = plot:findFirstChild("Expand")
	local current = getcurrentressources()
	local craftingcache = {}
	local needed = {}
	local reserved = {}
	local visiting = {}
	local hasbuildablelandmark = false
	local hasneededtoolupgrade = false
	local function getcrafting(itemname)
		local recipe = recipes[itemname]
		if not recipe then return 0 end
		local crafter = recipe["Crafter"]
		if craftingcache[crafter] == nil then
			craftingcache[crafter] = getcraftercrafting(crafter) or 0
		end
		return craftingcache[crafter]
	end
	local function getavailable(itemname)
		return (current[itemname] or 0) + getcrafting(itemname) - (reserved[itemname] or 0)
	end
	local function addneed(itemname, amount)
		if not itemname then return end
		amount = amount or 1
		if amount <= 0 then return end
		needed[itemname] = (needed[itemname] or 0) + amount
	end
	if expandfolder then
		for _, expand in ipairs(expandfolder:GetChildren()) do
			local list = getlistofmaterialsfortarget(expand)
			for _, item in ipairs(list) do
				addneed(item["Name"], item["Amount"] or 1)
			end
		end
	end
	for _, landmark in ipairs(landmarks) do
		local attatchment = getattatchmentforlandmark(landmark)
		if attatchment and islandmarkbuildable(attatchment) then
			hasbuildablelandmark = true
			local list = getlistofmaterialsforlandmark(attatchment)
			for _, item in ipairs(list) do
				addneed(item["Name"], item["Amount"] or 1)
			end
		end
	end
	for _, upgradename in ipairs(toolsupgrade) do
		local list = getlistofmaterialsfortoolupgrade(upgradename)
		if list and #list > 0 then
			hasneededtoolupgrade = true
			for _, item in ipairs(list) do
				addneed(item["Name"], item["Amount"] or 1)
			end
		end
	end
	addneed("Magmite", 40)
	local function getcanmake(itemname)
		local recipe = recipes[itemname]
		if not recipe then return 0 end
		local lowest
		for _, item in ipairs(recipe["Items"]) do
			local ingredientname = item["Name"]
			local ingredientamount = item["Amount"] or 1
			local has = current[ingredientname] or 0
			local can = math.floor(has / ingredientamount)
			if lowest == nil or can < lowest then
				lowest = can
			end
		end
		return lowest or 0
	end
	local function craftmissing(itemname, amount)
		if amount <= 0 then return end
		local recipe = recipes[itemname]
		if not recipe then return end
		if visiting[itemname] then return end
		local available = getavailable(itemname)
		if available >= amount then
			reserved[itemname] = (reserved[itemname] or 0) + amount
			return
		end
		local left = amount - available
		visiting[itemname] = true
		for _, item in ipairs(recipe["Items"]) do
			local ingredientname = item["Name"]
			local ingredientamount = item["Amount"] or 1
			local needamount = ingredientamount * left
			if getavailable(ingredientname) < needamount then
				craftmissing(ingredientname, needamount)
			end
		end
		local amounttocraft = math.clamp(left, 0, getcanmake(itemname))
		for i = 1, amounttocraft do
			local cancraft = true
			for _, item in ipairs(recipe["Items"]) do
				if (current[item["Name"]] or 0) < (item["Amount"] or 1) then
					cancraft = false
					break
				end
			end
			if not cancraft then break end
			for _, item in ipairs(recipe["Items"]) do
				current[item["Name"]] = (current[item["Name"]] or 0) - (item["Amount"] or 1)
			end
			current[itemname] = (current[itemname] or 0) + 1
			reserved[itemname] = (reserved[itemname] or 0) + 1
			craft(recipe["Crafter"])
		end
		visiting[itemname] = nil
	end
	for itemname, itemamount in pairs(needed) do
		if recipes[itemname] then
			craftmissing(itemname, itemamount)
		end
	end
	if hasbuildablelandmark then
		buildalllandmarks()
	end
	if hasneededtoolupgrade then
		upgradealltools()
	end
end
local function usepotions()
	local char = player.Character or player.CharacterAdded:Wait()
	local backpack = player.Backpack
	local remote = game:GetService("ReplicatedStorage").Communication.DrinkPotion
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Parent = backpack
		end
	end
	local potion
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:GetAttribute("ITEM") == "Resource Potion" then
			potion = tool
			break
		end
	end
	if potion then
		potion.Parent = char
		task.wait(0.1)
		remote:FireServer()
	end
end
local debounce = true
local function settarget()
	if debounce then
		debounce = false
		tabs.Other:SetLabelText("Target Label", "Press On A Expand To Make It The Target")
		local newtarget = nil
		repeat
			local pressed = false
			game:GetService("UserInputService").InputBegan:Once(function(input, gpe)
				if not gpe then
					newtarget = player:GetMouse().Target
					pressed = true
				end
			end)
			repeat
				task.wait()
			until pressed
		until newtarget and newtarget.Parent and newtarget.Parent == workspace.Plots:findFirstChild(player.Name):findFirstChild("Expand")
		targetexpand = newtarget
		debounce = true
		tabs.Other:SetLabelText("Target Label", "New Target Expand Set")
	end
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
else
	tabs.Main:Label("Publisher", "Unknown Publisher")
	tabs.Main:Label("Name", "Unknown Executor")
	tabs.Main:Label("Discord", "No Discord Found")
	tabs.Main:Label("Website", "No Website Found")
	tabs.Main:Label("Version", "Unknown Version")
end


tabs.Fish:Divider("Collect From Fishers")
tabs.Fish:Button("Collect",function() collectfish() end)
tabs.Fish:Toggle("Auto Collect",true,function(v) values.AutoCollectFish = v end)
tabs.Fish:Dropdown("Auto Collect Mode",{"When contains fish","When crate full"},"When contains fish",function(v) values.AutoCollectFishMode = v end)

tabs.Fish:Divider("Spawn Fish")
tabs.Fish:Button("Spawn Fish",function() for i = 1, (values.FishAmount or 1) do
		task.spawn(function()
			fish_spawnfish(getplayerpos(), 1)
		end)
	end
end)
tabs.Fish:NumberInput("Fish Amount",100,function(t) values.FishAmount = tonumber(t) end)

tabs.Fish:Divider("Rain Fish")
tabs.Fish:Button("Fish Rain",function() fishrain(player) end)
tabs.Fish:Button("Fish Rain Others",function() fishrainall() end)

tabs.Fish:Divider("Other")
tabs.Fish:Button("Goto Fishing Spot",function() gotofishingspot() end)


tabs.Buy_Sell:Divider("Sell")
tabs.Buy_Sell:Button("Sell All",function() sellall() end)
tabs.Buy_Sell:Toggle("Sell Everything When Backpack Is Full",true,function(v) values.AutoSellWhenFull = v end)
tabs.Buy_Sell:Button("Lock All Important Items",function() lockneededitems() end)
tabs.Buy_Sell:Button("Lock All Items",function() lockallitems() end)
tabs.Buy_Sell:DropdownList("Auto Buy", 0, #shopitems, reversetable(shopitems), shopitems, shopitems[1], function(v) values.AutoBuyShop = v end)


tabs.Other:Divider("Automating Everything")
tabs.Other:Toggle("Automate Everything",false,function(v) values.AutomateGame = v end)
tabs.Other:Toggle("Randomize Expand",true,function(v) values.Automate.RandomizeExpand = v end)
tabs.Other:Toggle("Auto Craft Resource Potions And Use",true,function(v) values.Automate.Potions = v end)
tabs.Other:Button("Set Target",function() settarget() end)
tabs.Other:Label("Target Label","Press The Button To Set The Target Expand")

tabs.Other:Divider("Automating")
tabs.Other:Toggle("Auto Break All Ressources",false,function(v) values.AutoRessource = v end)

tabs.Other:Divider("Handle Something")
tabs.Other:Button("Harvest All",function() harvestall() end)
tabs.Other:Button("Collect From Friend Chest",function() collectfriendgold() end)
tabs.Other:Button("Make All Boats Mine",function() makeallboatsmine() end)
tabs.Other:Button("Get All Ressources",function() getallressources() end)
tabs.Other:Button("Give Coal To Mines",function() givecoaltoallmines() end)
tabs.Other:Button("Collect Money From Mines",function() collectallcoinsfrommines() end)
tabs.Other:Button("Claim All Timed Rewards",function() claimalltimesrewards() end)
tabs.Other:Button("Exapand Island",function() doallexpand() end)
tabs.Other:Button("Buy Gold Upgrades",function() buyneededgoldupgrades() end)

tabs.Monitoring:Label("materials_unlocked","Unlocked Materials:\n")


tabs.Workers:Button("Hire All Workers",function() hireallworkers() end)
tabs.Workers:DropdownList("Lumberjacks", 5, 5, table.create(5, "Log"), {"Log", "Bamboo", "Wheat", "Cactus", "Magma Log", "Mushroom"}[[, "Wheat", "Cactus", "FireLog", "Mushroom"}]], "Log", function(v) values.WorkersLumbers = v setworkersincate(1) end)
tabs.Workers:DropdownList("Miners", 4, 4, table.create(4, "Stone"), {"Stone", "Iron Ore", "Sand", "Magma Crystal", "Obsidian", "Salt"}, "Stone", function(v) values.WorkersMiners = v setworkersincate(2) end)
tabs.Workers:DropdownList("Crafters", 4, 4, table.create(4, "Plank"), {"None", "Plank", "Brick", "Bamboo Plank", "Iron Bar", "Haybale", "Cactus Fiber", "Cement", "Magmite", "Magma Plank", "Obsidian Glass", "Mushroom Plank", "Salt Bag", "Banana Crate"}, "Plank", function(v) values.WorkersCrafters = v setworkersincate(3) end)
tabs.Workers:DropdownList("Zookeepers", 3, 3, table.create(3, "Poop"), {"Poop", "Honeycomb"}, "Poop", function(v) values.WorkersZookeepers = v setworkersincate(4) end)

collectdailyreward()
redeemallcodes()
lockneededitems()
if read("BuildAnIsland/save.txt") then
	window:Load(read("BuildAnIsland/save.txt"))
end

table.insert(threads, task.spawn(function()
	while true do
		if values.AutoCollectFish then
			if hasfishingtile() then
				if values.AutoCollectFishMode == "When contains fish" then
					if getfishamount() > 0 then
						collectfish()
						task.wait(1)
					end
				else
					if getfishamount() == getfishmaxamount() then
						collectfish()
						task.wait(1)
					end
				end
			end
		end
		task.wait(0.1)
	end
end))

table.insert(threads, task.spawn(function()
	while true do
		if values.AutoSellWhenFull then
			if isbackpackoverflowing() then
				sellall()
			end
		end
		task.wait(0.1)
	end
end))

table.insert(threads, task.spawn(function()
	while true do
		local itemstext = ""
		local items = {}
		for itemname, itemamount in pairs(getcurrentressources()) do
			if not table.find(items, itemname) then
				table.insert(items, itemname)
				itemstext = itemstext.."\n"..itemname..": "..itemamount
			end
		end
		tabs.Monitoring:SetLabelText("materials_unlocked", "Unlocked Materials:"..itemstext)
		task.wait(1)
	end
end))

local function automategamefully()
	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				for i = 1, 20 do
					fish_spawnfish(getplayerpos() - Vector3.new(0, 30, 0), 1, true)
				end
				sellall()
				task.wait(1)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				hireallworkers()
				for i = 1, 4 do
					setworkersincate(i)
				end
				task.wait(15)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				buyneededgoldupgrades()
				task.wait(15)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				buildalllandmarks()
				task.wait(15)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				craftallneeded()
				task.wait(6)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				if hasfriendgoldchest() then
					if getfriendgoldamount() > 0 then
						collectfriendgold()
					end
				end
				task.wait(15)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				harvestall()
				lockneededitems()
				task.wait(10)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				doallexpand()
				task.wait(5)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				if hasrainbowisland() then
					harvestallclovers()
				end
				task.wait(10)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				claimalltimesrewards()
				lockneededitems()
				task.wait(15)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				givecoaltoallmines()
				collectallcoinsfrommines()
				task.wait(15)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				handleworldtree()
				task.wait(10)
			end
			task.wait()
		end
	end))

	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				getallressources()
				upgradealltools()
				task.wait(5)
			end
			task.wait()
		end
	end))
	
	table.insert(threads, task.spawn(function()
		while true do
			if values.AutomateGame then
				if values.Automate.Potions then
					craft("S78")
					usepotions()
					task.wait(5)
				end
			end
			task.wait()
		end
	end))
end

automategamefully()

table.insert(threads, task.spawn(function()
	while true do
		if values.AutoRessource then
			getallressources()
			task.wait(5)
		end
		task.wait(0.1)
	end
end))

table.insert(threads, task.spawn(function()
	while true do
		if #values.AutoBuyShop > 0 then
			for _, item in ipairs(values.AutoBuyShop) do
				buyitem(item)
			end
			task.wait(1)
		end
		task.wait(0.1)
	end
end))