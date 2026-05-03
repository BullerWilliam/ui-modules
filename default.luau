local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local uis = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

print("------------------------loaded ui module-------------------------")
print("---------------------------Version:1.1---------------------------")
print("-----------------------------------------------------------------")

local gui = Instance.new("ScreenGui")
gui.Name = "UiModules"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = plr:WaitForChild("PlayerGui")

local guiScale = Instance.new("UIScale")
guiScale.Parent = gui

local ui = {}
ui.__index = ui
ui.windows = {}
ui.windowCount = 0
ui.dragWindow = nil
ui.dragStart = nil
ui.startPos = nil
ui.theme = {
	bg = Color3.fromRGB(24, 25, 30),
	panel = Color3.fromRGB(35, 37, 44),
	panelLight = Color3.fromRGB(47, 50, 59),
	control = Color3.fromRGB(55, 59, 69),
	controlHover = Color3.fromRGB(67, 72, 84),
	accent = Color3.fromRGB(75, 139, 255),
	accentDark = Color3.fromRGB(45, 92, 184),
	text = Color3.fromRGB(245, 247, 250),
	muted = Color3.fromRGB(176, 184, 196),
	border = Color3.fromRGB(70, 75, 88),
}

local windowClass = {}
windowClass.__index = windowClass

local tabClass = {}
tabClass.__index = tabClass

local labelClass = {}
labelClass.__index = labelClass

local dropdownClass = {}
dropdownClass.__index = dropdownClass

local multiDropdownClass = {}
multiDropdownClass.__index = multiDropdownClass

local function clamp(value, minValue, maxValue)
	return math.max(minValue, math.min(maxValue, value))
end

local function updateScale()
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	guiScale.Scale = clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.78, 1.12)
end

updateScale()
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function stroke(parent, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or ui.theme.border
	s.Transparency = transparency or 0
	s.Thickness = 1
	s.Parent = parent
	return s
end

local function padding(parent, left, top, right, bottom)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, left or 0)
	p.PaddingTop = UDim.new(0, top or 0)
	p.PaddingRight = UDim.new(0, right or left or 0)
	p.PaddingBottom = UDim.new(0, bottom or top or 0)
	p.Parent = parent
	return p
end

local function textLimit(parent, minSize, maxSize)
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = minSize or 12
	limit.MaxTextSize = maxSize or 16
	limit.Parent = parent
	return limit
end

local function setControlHover(control, normalColor)
	control.MouseEnter:Connect(function()
		control.BackgroundColor3 = ui.theme.controlHover
	end)

	control.MouseLeave:Connect(function()
		control.BackgroundColor3 = normalColor
	end)
end

local function makeControlFrame(parent, height)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, height or 42)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	return frame
end

local function makeLabel(parent, text, width)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, width or 110, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = ui.theme.muted
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent
	return label
end

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
	main.Size = UDim2.new(0, 380, 0, 500)
	main.Position = UDim2.new(0.5, -190 + (ui.windowCount * 28), 0.5, -250 + (ui.windowCount * 28))
	main.BackgroundColor3 = ui.theme.bg
	main.BorderSizePixel = 0
	main.Parent = gui
	corner(main, 8)
	stroke(main, ui.theme.border, 0.2)

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(300, 340)
	sizeConstraint.MaxSize = Vector2.new(620, 720)
	sizeConstraint.Parent = main

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 44)
	title.BackgroundColor3 = ui.theme.panel
	title.BorderSizePixel = 0
	title.Text = titleText
	title.TextColor3 = ui.theme.text
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Parent = main
	corner(title, 8)
	padding(title, 12, 0, 12, 0)
	textLimit(title, 14, 20)

	local tabsBar = Instance.new("ScrollingFrame")
	tabsBar.Size = UDim2.new(1, 0, 0, 40)
	tabsBar.Position = UDim2.new(0, 0, 0, 44)
	tabsBar.BackgroundColor3 = ui.theme.panel
	tabsBar.BorderSizePixel = 0
	tabsBar.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabsBar.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabsBar.ScrollingDirection = Enum.ScrollingDirection.X
	tabsBar.ScrollBarThickness = 3
	tabsBar.ScrollBarImageColor3 = ui.theme.accent
	tabsBar.Parent = main
	padding(tabsBar, 8, 5, 8, 5)

	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabsLayout.Padding = UDim.new(0, 6)
	tabsLayout.Parent = tabsBar

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -20, 1, -98)
	content.Position = UDim2.new(0, 10, 0, 90)
	content.BackgroundTransparency = 1
	content.ClipsDescendants = true
	content.Parent = main

	title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and ui.dragWindow == nil then
			ui.dragWindow = main
			ui.dragStart = input.Position
			ui.startPos = main.Position
		end
	end)

	local win = setmetatable({}, windowClass)
	win.frame = main
	win.tabsBar = tabsBar
	win.content = content
	win.tabs = {}
	win.tabButtons = {}
	win.currentTab = nil
	win.title = title

	table.insert(self.windows, win)

	return win
end

function windowClass:ChangeTitle(newtitle)
	self.title.Text = newtitle
end

function windowClass:SelectTab(tab)
	for _, t in pairs(self.tabs) do
		t.frame.Visible = false
		if t.button then
			t.button.BackgroundColor3 = ui.theme.control
			t.button.TextColor3 = ui.theme.muted
		end
	end

	tab.frame.Visible = true
	if tab.button then
		tab.button.BackgroundColor3 = ui.theme.accent
		tab.button.TextColor3 = ui.theme.text
	end
	self.currentTab = tab
end

function windowClass:CreateTab(name)
	local tab

	local tabBtn = Instance.new("TextButton")
	tabBtn.Size = UDim2.new(0, math.max(82, string.len(name) * 9 + 26), 1, -10)
	tabBtn.BackgroundColor3 = ui.theme.control
	tabBtn.BorderSizePixel = 0
	tabBtn.TextColor3 = ui.theme.muted
	tabBtn.Font = Enum.Font.GothamSemibold
	tabBtn.TextSize = 14
	tabBtn.Text = name
	tabBtn.AutoButtonColor = false
	tabBtn.Parent = self.tabsBar
	corner(tabBtn, 6)

	tabBtn.MouseEnter:Connect(function()
		if self.currentTab ~= tab then
			tabBtn.BackgroundColor3 = ui.theme.controlHover
		end
	end)

	tabBtn.MouseLeave:Connect(function()
		if self.currentTab ~= tab then
			tabBtn.BackgroundColor3 = ui.theme.control
		end
	end)

	local frame = Instance.new("ScrollingFrame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ScrollBarThickness = 6
	frame.ScrollBarImageColor3 = ui.theme.accent
	frame.CanvasSize = UDim2.new(0, 0, 0, 0)
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.Parent = self.content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	padding(frame, 0, 0, 8, 8)

	tab = setmetatable({}, tabClass)
	tab.frame = frame
	tab.button = tabBtn

	table.insert(self.tabs, tab)
	table.insert(self.tabButtons, tabBtn)

	tabBtn.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	if not self.currentTab then
		self:SelectTab(tab)
	end

	return tab
end

function tabClass:Button(text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 42)
	btn.BackgroundColor3 = ui.theme.control
	btn.BorderSizePixel = 0
	btn.TextColor3 = ui.theme.text
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 15
	btn.Text = text
	btn.AutoButtonColor = false
	btn.Parent = self.frame
	corner(btn, 6)
	stroke(btn, ui.theme.border, 0.45)
	setControlHover(btn, ui.theme.control)

	btn.MouseButton1Click:Connect(function()
		if callback then
			callback()
		end
	end)

	return btn
end

function tabClass:Toggle(text, startvalue, callback)
	local state = startvalue == true

	local row = makeControlFrame(self.frame, 42)

	local label = makeLabel(row, text)
	label.Size = UDim2.new(1, -76, 1, 0)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 66, 0, 30)
	btn.Position = UDim2.new(1, -66, 0.5, -15)
	btn.BackgroundColor3 = state and ui.theme.accent or ui.theme.control
	btn.BorderSizePixel = 0
	btn.TextColor3 = ui.theme.text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = state and "ON" or "OFF"
	btn.AutoButtonColor = false
	btn.Parent = row
	corner(btn, 6)
	stroke(btn, ui.theme.border, 0.5)

	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.Text = state and "ON" or "OFF"
		btn.BackgroundColor3 = state and ui.theme.accent or ui.theme.control

		if callback then
			callback(state)
		end
	end)

	return {
		SetValue = function(_, value)
			state = value == true
			btn.Text = state and "ON" or "OFF"
			btn.BackgroundColor3 = state and ui.theme.accent or ui.theme.control
		end,
		GetValue = function()
			return state
		end,
	}
end

function tabClass:Input(labelText, placeholder, callback)
	if type(placeholder) == "function" then
		callback = placeholder
		placeholder = labelText
		labelText = "Input"
	end

	local row = makeControlFrame(self.frame, 44)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = row

	makeLabel(row, labelText, 110)

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -118, 1, 0)
	box.BackgroundColor3 = ui.theme.control
	box.BorderSizePixel = 0
	box.TextColor3 = ui.theme.text
	box.PlaceholderColor3 = ui.theme.muted
	box.PlaceholderText = placeholder or ""
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Parent = row
	corner(box, 6)
	stroke(box, ui.theme.border, 0.5)
	padding(box, 10, 0, 10, 0)

	box.FocusLost:Connect(function()
		if callback then
			callback(box.Text)
		end
	end)

	return box
end

function labelClass:SetText(text)
	self.text = text
	self.label.Text = text
end

function labelClass:GetText()
	return self.text
end

function tabClass:Label(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 36)
	label.BackgroundColor3 = ui.theme.panel
	label.BorderSizePixel = 0
	label.Text = text or ""
	label.TextColor3 = ui.theme.text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = self.frame
	corner(label, 6)
	stroke(label, ui.theme.border, 0.5)
	padding(label, 10, 0, 10, 0)

	local item = setmetatable({}, labelClass)
	item.label = label
	item.text = text or ""
	return item
end

function dropdownClass:SetValue(value)
	self.value = value
	self.button.Text = self.title .. ": " .. tostring(value)

	if self.callback then
		self.callback(value)
	end
end

function dropdownClass:SetOpen(isOpen)
	self.open = isOpen
	self.menu.Visible = isOpen
	self.container.Size = UDim2.new(1, 0, 0, isOpen and 178 or 44)
	self.button.Text = self.value and (self.title .. ": " .. tostring(self.value)) or (self.title .. (isOpen and " ^" or " v"))
end

function dropdownClass:SetOptions(options)
	self.options = options or {}

	for _, c in pairs(self.list:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end

	for _, option in pairs(self.options) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.BackgroundColor3 = ui.theme.panelLight
		btn.BorderSizePixel = 0
		btn.TextColor3 = ui.theme.text
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 14
		btn.Text = tostring(option)
		btn.AutoButtonColor = false
		btn.Parent = self.list
		setControlHover(btn, ui.theme.panelLight)

		btn.MouseButton1Click:Connect(function()
			self:SetValue(option)
			self:SetOpen(false)
		end)
	end
end

function tabClass:Dropdown(title, options, default, callback)
	local container = makeControlFrame(self.frame, 44)

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 44)
	button.BackgroundColor3 = ui.theme.control
	button.BorderSizePixel = 0
	button.TextColor3 = ui.theme.text
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 14
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.AutoButtonColor = false
	button.Parent = container
	corner(button, 6)
	stroke(button, ui.theme.border, 0.5)
	padding(button, 10, 0, 10, 0)
	setControlHover(button, ui.theme.control)

	local menu = Instance.new("Frame")
	menu.Size = UDim2.new(1, 0, 0, 126)
	menu.Position = UDim2.new(0, 0, 0, 50)
	menu.BackgroundColor3 = ui.theme.panel
	menu.BorderSizePixel = 0
	menu.Visible = false
	menu.Parent = container
	corner(menu, 6)
	stroke(menu, ui.theme.border, 0.35)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -8, 1, -8)
	scroll.Position = UDim2.new(0, 4, 0, 4)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = ui.theme.accent
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Parent = menu

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = scroll

	local drop = setmetatable({}, dropdownClass)
	drop.button = button
	drop.menu = menu
	drop.list = scroll
	drop.title = title
	drop.callback = callback
	drop.container = container
	drop.open = false

	button.MouseButton1Click:Connect(function()
		drop:SetOpen(not drop.open)
	end)

	drop:SetOptions(options)

	if default then
		drop:SetValue(default)
	else
		button.Text = title .. " v"
	end

	return drop
end

function multiDropdownClass:_selectedText()
	local selected = {}

	for _, option in pairs(self.options) do
		if self.values[option] then
			table.insert(selected, tostring(option))
		end
	end

	if #selected == 0 then
		return self.title .. ": None"
	end

	return self.title .. ": " .. table.concat(selected, ", ")
end

function multiDropdownClass:_emit()
	if self.callback then
		local selected = {}
		for _, option in pairs(self.options) do
			if self.values[option] then
				table.insert(selected, option)
			end
		end
		self.callback(selected)
	end
end

function multiDropdownClass:SetOpen(isOpen)
	self.open = isOpen
	self.menu.Visible = isOpen
	self.container.Size = UDim2.new(1, 0, 0, isOpen and 210 or 44)
	self.button.Text = self:_selectedText()
end

function multiDropdownClass:SetValue(values)
	self.values = {}

	for _, value in pairs(values or {}) do
		self.values[value] = true
	end

	self:Refresh()
	self:_emit()
end

function multiDropdownClass:Refresh()
	for _, c in pairs(self.list:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end

	for _, option in pairs(self.options) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.BackgroundColor3 = self.values[option] and ui.theme.accentDark or ui.theme.panelLight
		btn.BorderSizePixel = 0
		btn.TextColor3 = ui.theme.text
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 14
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Text = (self.values[option] and "[x] " or "[ ] ") .. tostring(option)
		btn.AutoButtonColor = false
		btn.Parent = self.list
		corner(btn, 5)
		padding(btn, 8, 0, 8, 0)

		btn.MouseButton1Click:Connect(function()
			self.values[option] = not self.values[option]
			if self.values[option] == false then
				self.values[option] = nil
			end
			self.button.Text = self:_selectedText()
			self:Refresh()
			self:_emit()
		end)
	end

	self.button.Text = self:_selectedText()
end

function multiDropdownClass:SetOptions(options)
	self.options = options or {}
	self:Refresh()
end

function tabClass:MultiDropdown(title, options, defaults, callback)
	local container = makeControlFrame(self.frame, 44)

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 44)
	button.BackgroundColor3 = ui.theme.control
	button.BorderSizePixel = 0
	button.TextColor3 = ui.theme.text
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 14
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.TextTruncate = Enum.TextTruncate.AtEnd
	button.AutoButtonColor = false
	button.Parent = container
	corner(button, 6)
	stroke(button, ui.theme.border, 0.5)
	padding(button, 10, 0, 10, 0)
	setControlHover(button, ui.theme.control)

	local menu = Instance.new("Frame")
	menu.Size = UDim2.new(1, 0, 0, 158)
	menu.Position = UDim2.new(0, 0, 0, 50)
	menu.BackgroundColor3 = ui.theme.panel
	menu.BorderSizePixel = 0
	menu.Visible = false
	menu.Parent = container
	corner(menu, 6)
	stroke(menu, ui.theme.border, 0.35)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -8, 1, -8)
	scroll.Position = UDim2.new(0, 4, 0, 4)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = ui.theme.accent
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Parent = menu

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = scroll

	local drop = setmetatable({}, multiDropdownClass)
	drop.button = button
	drop.menu = menu
	drop.list = scroll
	drop.title = title
	drop.callback = callback
	drop.container = container
	drop.open = false
	drop.options = options or {}
	drop.values = {}

	button.MouseButton1Click:Connect(function()
		drop:SetOpen(not drop.open)
	end)

	drop:SetValue(defaults or {})

	return drop
end

return ui
