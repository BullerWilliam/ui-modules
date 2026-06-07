local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/BullerWilliam/ui-modules/refs/heads/main/default.luau"))()
local tabs = {}
local values = {}
local threads = {}

local plr = game.Players.LocalPlayer

local window = ui:CreateWindow("Protect The House From Monsters")
local window_frame = window.frame
tabs.Main = window:CreateTab("Main")

local function findallweapons()
	local character = plr.Character or plr.CharacterAdded:Wait()

	local weapons = game.Workspace.HiddenWeaponBoxes:GetChildren()

	for _, weapon in ipairs(weapons) do
		character:PivotTo(weapon.CFrame)
		task.wait(0.4)
	end
end

local function stopall()
	for _, th in ipairs(threads) do
		task.cancel(th)
	end
	window_frame:Destroy()
	script:Destroy()
end

local function shoot(targetPosition)
	local tool = plr.Backpack:FindFirstChild("Revolver") or plr.Character:FindFirstChild("Revolver")
	local plrs = game:GetService("Players")
	local workspace = game:GetService("Workspace")
	local mouse = plr:GetMouse()
	local camera = workspace.CurrentCamera
	local shootRemote = tool:WaitForChild("ShootRemote")
	local canShoot = true
	local fireDelay = 0.15
	local range = 10500
	local function getShootPosition()
		if mouse and mouse.Hit then
			return mouse.Hit.Position
		end
		return camera.CFrame.Position + camera.CFrame.LookVector * range
	end
	if not canShoot then
		return false
	end
	local character = plr.Character
	if not character then
		return false
	end
	if tool.Parent ~= character then
		return false
	end
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return false
	end
	local muzzle = handle:FindFirstChild("Muzzle")
	local origin = muzzle and muzzle.WorldPosition or handle.Position
	local finalTargetPosition = targetPosition or getShootPosition()
	local direction = finalTargetPosition - origin
	if direction.Magnitude <= 0 then
		return false
	end
	canShoot = false
	shootRemote:FireServer(origin, direction.Unit, range)
	task.delay(fireDelay, function()
		canShoot = true
	end)
	return true
end

local function throwgrenade(monster)
	local tool = plr.Backpack:FindFirstChild("Grenade") or plr.Character:FindFirstChild("Grenade")
	local event:RemoteEvent = tool:FindFirstChild("ThrowGrenade")
	event:FireServer(monster.PrimaryPart.CFrame)
end

tabs.Main:Divider("Main Functions")
tabs.Main:Button("Close",function() stopall() end)

tabs.Main:Divider("Actions")
tabs.Main:Button("Find All Weapons",function() findallweapons() end)
tabs.Main:Button("Shoot",function() shoot(Vector3.new(0, 0, 0)) end)
tabs.Main:Button("Throw Grenade",function() throwgrenade(Vector3.new(0, 0, 0)) end)