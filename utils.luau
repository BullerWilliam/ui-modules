local function trigger(prox:ProximityPrompt, proxpos)
	local char = player.Character
	local settings2 = task.spawn(function()
		while true do
			prox.HoldDuration = 0
			prox.MaxActivationDistance = 1000000
			prox.MaxIndicatorDistance = 1000000
			prox.RequiresLineOfSight = false
			prox.Enabled = true
			task.wait()
		end
	end)
	print("before cam")
	local beforetype = game.Workspace.CurrentCamera.CameraType
	game.Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	if not char then
		print("no char")
	else
		print("char")
	end
	print("-2")
	if char then
		if not char.PrimaryPart then
			print("No primary")
			char.PrimaryPart = char.HumanoidRootPart
		end
		local pos = char:GetPivot()
		print("-1")
		char:PivotTo(CFrame.new(proxpos + Vector3.new(0, 8, 0)))
		print("1")
		task.wait(0.1)
		game.Workspace.CurrentCamera.CFrame = CFrame.lookAt(proxpos + Vector3.new(0, 4, 5), proxpos)
		print("2")
		task.wait(0.1)
		prox:InputHoldBegin()
		print("3")
		task.wait(0.1)
		prox:InputHoldEnd()
		print("4")
		task.wait(0.1)
		char:PivotTo(pos)
		print("5")
	end
	game.Workspace.CurrentCamera.CameraType = beforetype
	task.cancel(settings2)
end

local function trigger2(prox:ProximityPrompt, proxpos)
    prox.HoldDuration = 0
    prox.MaxActivationDistance = 1000000
    prox.MaxIndicatorDistance = 1000000
    prox.RequiresLineOfSight = false
    prox.Enabled = true
    task.wait(0.1)
    prox:InputHoldBegin()
    task.wait(0.1)
    prox:InputHoldEnd()
end

local function copy(text)
    setclipboard(text)

end

return trigger2, copy