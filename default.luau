local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local uis = game:GetService("UserInputService")

print("------------------------loaded ui module-------------------------")

local gui = Instance.new("ScreenGui")
gui.Parent = plr:WaitForChild("PlayerGui")

local ui = {}
ui.__index = ui
ui.windows = {}
ui.windowCount = 0
ui.dragWindow = nil
ui.dragStart = nil
ui.startPos = nil

local windowClass = {}
windowClass.__index = windowClass

local tabClass = {}
tabClass.__index = tabClass

local dropdownClass = {}
dropdownClass.__index = dropdownClass

uis.InputChanged:Connect(function(input)

	if ui.dragWindow and input.UserInputType == Enum.UserInputType.MouseMovement then

		local delta = input.Position - ui.dragStart
		local main = ui.dragWindow

		main.Position = UDim2.new(
			ui.startPos.X.Scale,
			ui.startPos.X.Offset + delta.X,
			ui.startPos.Y.Scale,
			ui.startPos.Y.Offset + delta.Y
		)

	end

end)

uis.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		ui.dragWindow = nil
	end

end)

function ui:CreateWindow(titleText)

	ui.windowCount += 1

	local main = Instance.new("Frame")
	main.Size = UDim2.new(0,300,0,420)
	main.Position = UDim2.new(0.5,-150 + (ui.windowCount*30),0.5,-210 + (ui.windowCount*30))
	main.BackgroundColor3 = Color3.fromRGB(35,35,35)
	main.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,0,0,40)
	title.BackgroundColor3 = Color3.fromRGB(25,25,25)
	title.Text = titleText
	title.TextColor3 = Color3.new(1,1,1)
	title.TextScaled = true
	title.Parent = main

	local tabsBar = Instance.new("Frame")
	tabsBar.Size = UDim2.new(1,0,0,30)
	tabsBar.Position = UDim2.new(0,0,0,40)
	tabsBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
	tabsBar.Parent = main

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1,0,1,-70)
	content.Position = UDim2.new(0,0,0,70)
	content.BackgroundTransparency = 1
	content.Parent = main

	title.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1 and ui.dragWindow == nil then

			ui.dragWindow = main
			ui.dragStart = input.Position
			ui.startPos = main.Position

		end

	end)

	local win = setmetatable({},windowClass)
	win.frame = main
	win.tabsBar = tabsBar
	win.content = content
	win.tabs = {}
	win.tabButtons = {}
	win.currentTab = nil

	table.insert(self.windows,win)

	return win
end

function windowClass:SelectTab(tab)

	for _,t in pairs(self.tabs) do
		t.frame.Visible = false
	end

	tab.frame.Visible = true
	self.currentTab = tab

end

function windowClass:CreateTab(name)

	local tabBtn = Instance.new("TextButton")
	tabBtn.Size = UDim2.new(0,90,1,0)
	tabBtn.Position = UDim2.new(0,#self.tabButtons*90,0,0)
	tabBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	tabBtn.TextColor3 = Color3.new(1,1,1)
	tabBtn.Text = name
	tabBtn.Parent = self.tabsBar

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,0,1,0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = self.content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,6)
	layout.Parent = frame

	local tab = setmetatable({},tabClass)
	tab.frame = frame

	table.insert(self.tabs,tab)
	table.insert(self.tabButtons,tabBtn)

	tabBtn.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	if not self.currentTab then
		self:SelectTab(tab)
	end

	return tab
end

function tabClass:Button(text,callback)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,-10,0,40)
	btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Text = text
	btn.Parent = self.frame

	btn.MouseButton1Click:Connect(function()
		if callback then
			callback()
		end
	end)

end

function tabClass:Toggle(text,callback)

	local state = false

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,-10,0,40)
	btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Text = text.." : OFF"
	btn.Parent = self.frame

	btn.MouseButton1Click:Connect(function()

		state = not state

		if state then
			btn.Text = text.." : ON"
		else
			btn.Text = text.." : OFF"
		end

		if callback then
			callback(state)
		end

	end)

end

function tabClass:Input(placeholder,callback)

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1,-10,0,40)
	box.BackgroundColor3 = Color3.fromRGB(60,60,60)
	box.TextColor3 = Color3.new(1,1,1)
	box.PlaceholderText = placeholder
	box.Text = ""
	box.Parent = self.frame

	box.FocusLost:Connect(function()

		if callback then
			callback(box.Text)
		end

	end)

end

function dropdownClass:SetValue(value)

	self.value = value
	self.button.Text = self.title..": "..value

	if self.callback then
		self.callback(value)
	end

end

function dropdownClass:SetOptions(options)

	self.options = options

	for _,c in pairs(self.list:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end

	for _,option in pairs(options) do

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1,0,0,30)
		btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
		btn.TextColor3 = Color3.new(1,1,1)
		btn.Text = option
		btn.Parent = self.list

		btn.MouseButton1Click:Connect(function()

			self:SetValue(option)
			self.menu.Visible = false

		end)

	end

end

function tabClass:Dropdown(title,options,default,callback)

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1,-10,0,40)
	container.BackgroundTransparency = 1
	container.Parent = self.frame

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1,0,1,0)
	button.BackgroundColor3 = Color3.fromRGB(60,60,60)
	button.TextColor3 = Color3.new(1,1,1)
	button.Parent = container

	local menu = Instance.new("Frame")
	menu.Size = UDim2.new(1,0,0,120)
	menu.Position = UDim2.new(0,0,1,0)
	menu.BackgroundColor3 = Color3.fromRGB(50,50,50)
	menu.Visible = false
	menu.Parent = container

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1,0,1,0)
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.ScrollBarThickness = 6
	scroll.BackgroundTransparency = 1
	scroll.Parent = menu

	local layout = Instance.new("UIListLayout")
	layout.Parent = scroll

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
	end)

	local drop = setmetatable({},dropdownClass)
	drop.button = button
	drop.menu = menu
	drop.list = scroll
	drop.title = title
	drop.callback = callback

	button.MouseButton1Click:Connect(function()
		menu.Visible = not menu.Visible
	end)

	drop:SetOptions(options)

	if default then
		drop:SetValue(default)
	else
		button.Text = title
	end

	return drop
end

return ui