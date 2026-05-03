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
ui.defaultAccent = Color3.fromRGB(75, 139, 255)
ui.theme = {
	bg = Color3.fromRGB(24, 25, 30),
	panel = Color3.fromRGB(35, 37, 44),
	panelLight = Color3.fromRGB(47, 50, 59),
	control = Color3.fromRGB(55, 59, 69),
	controlHover = Color3.fromRGB(67, 72, 84),
	accent = ui.defaultAccent,
	accentDark = Color3.fromRGB(45, 92, 184),
	text = Color3.fromRGB(245, 247, 250),
	muted = Color3.fromRGB(176, 184, 196),
	border = Color3.fromRGB(70, 75, 88),
}
ui.themeBindings = {}

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

local function darkenColor(color, amount)
	amount = amount or 0.68
	return Color3.new(color.R * amount, color.G * amount, color.B * amount)
end

local function normalizeNumber(text, fallback)
	local value = tonumber(text)
	if value == nil then
		return fallback
	end
	return value
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

function ui:_bindTheme(instance, property, activeKey, inactiveKey, predicate)
	table.insert(self.themeBindings, {
		instance = instance,
		property = property,
		activeKey = activeKey,
		inactiveKey = inactiveKey,
		predicate = predicate,
	})
	self:_applyThemeBinding(self.themeBindings[#self.themeBindings])
end

function ui:_applyThemeBinding(binding)
	if not binding.instance or not binding.instance.Parent then
		return
	end

	local key = binding.activeKey
	if binding.predicate and not binding.predicate() then
		key = binding.inactiveKey or binding.activeKey
	end

	binding.instance[binding.property] = self.theme[key]
end

function ui:RefreshTheme()
	for _, binding in pairs(self.themeBindings) do
		self:_applyThemeBinding(binding)
	end

	for _, window in pairs(self.windows) do
		if window.currentTab then
			window:SelectTab(window.currentTab)
		end
	end
end

function ui:SetTheme(theme)
	if theme == nil or theme == "default" or theme == "blue" then
		self.theme.accent = self.defaultAccent
	elseif typeof(theme) == "Color3" then
		self.theme.accent = theme
	elseif type(theme) == "table" and typeof(theme.accent) == "Color3" then
		self.theme.accent = theme.accent
	else
		warn("ui:SetTheme expected \"default\", \"blue\", a Color3, or { accent = Color3 }")
		return
	end

	self.theme.accentDark = darkenColor(self.theme.accent)
	self:RefreshTheme()
end

function ui:SetAccentColor(color)
	self:SetTheme(color)
end

function ui:UseDefaultTheme()
	self:SetTheme("default")
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
	ui:_bindTheme(tabsBar, "ScrollBarImageColor3", "accent")
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
	ui:_bindTheme(frame, "ScrollBarImageColor3", "accent")

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
	ui:_bindTheme(btn, "BackgroundColor3", "accent", "control", function()
		return state
	end)

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
			ui:RefreshTheme()
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

function tabClass:NumberInput(labelText, defaultValue, callback, minValue, maxValue)
	local box
	box = self:Input(labelText, tostring(defaultValue or 0), function(text)
		local value = normalizeNumber(text, defaultValue or 0)
		if minValue then
			value = math.max(minValue, value)
		end
		if maxValue then
			value = math.min(maxValue, value)
		end
		box.Text = tostring(value)

		if callback then
			callback(value)
		end
	end)

	box.Text = defaultValue ~= nil and tostring(defaultValue) or ""
	return box
end

function tabClass:PasswordInput(labelText, placeholder, callback)
	local realText = ""
	local box = self:Input(labelText, placeholder or "Password")

	box.FocusLost:Connect(function()
		if callback then
			callback(realText)
		end
	end)

	box:GetPropertyChangedSignal("Text"):Connect(function()
		if not box:IsFocused() then
			return
		end

		local text = box.Text
		if text == string.rep("*", string.len(realText)) then
			return
		end

		if string.len(text) < string.len(realText) then
			realText = string.sub(realText, 1, string.len(text))
		elseif string.len(text) > string.len(realText) then
			realText ..= string.sub(text, string.len(realText) + 1)
		end

		box.Text = string.rep("*", string.len(realText))
	end)

	return {
		box = box,
		GetValue = function()
			return realText
		end,
		SetValue = function(_, value)
			realText = tostring(value or "")
			box.Text = string.rep("*", string.len(realText))
		end,
	}
end

function tabClass:TextArea(labelText, placeholder, callback)
	local row = makeControlFrame(self.frame, 96)

	local title = makeLabel(row, labelText, 110)
	title.Size = UDim2.new(1, 0, 0, 22)

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 1, -28)
	box.Position = UDim2.new(0, 0, 0, 28)
	box.BackgroundColor3 = ui.theme.control
	box.BorderSizePixel = 0
	box.TextColor3 = ui.theme.text
	box.PlaceholderColor3 = ui.theme.muted
	box.PlaceholderText = placeholder or ""
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.TextWrapped = true
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Top
	box.MultiLine = true
	box.Parent = row
	corner(box, 6)
	stroke(box, ui.theme.border, 0.5)
	padding(box, 10, 8, 10, 8)

	box.FocusLost:Connect(function()
		if callback then
			callback(box.Text)
		end
	end)

	return box
end

function tabClass:SearchInput(labelText, placeholder, callback)
	local box = self:Input(labelText, placeholder or "Search", callback)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if callback then
			callback(box.Text)
		end
	end)
	return box
end

function tabClass:Slider(labelText, minValue, maxValue, defaultValue, callback)
	minValue = minValue or 0
	maxValue = maxValue or 100
	defaultValue = clamp(defaultValue or minValue, minValue, maxValue)

	local value = defaultValue
	local row = makeControlFrame(self.frame, 54)
	local label = makeLabel(row, labelText, 110)
	label.Size = UDim2.new(1, -72, 0, 22)

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0, 64, 0, 22)
	valueLabel.Position = UDim2.new(1, -64, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(value)
	valueLabel.TextColor3 = ui.theme.text
	valueLabel.Font = Enum.Font.GothamSemibold
	valueLabel.TextSize = 13
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = row

	local track = Instance.new("TextButton")
	track.Size = UDim2.new(1, 0, 0, 18)
	track.Position = UDim2.new(0, 0, 0, 30)
	track.BackgroundColor3 = ui.theme.control
	track.BorderSizePixel = 0
	track.Text = ""
	track.AutoButtonColor = false
	track.Parent = row
	corner(track, 6)
	stroke(track, ui.theme.border, 0.5)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = ui.theme.accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 6)
	ui:_bindTheme(fill, "BackgroundColor3", "accent")

	local function setValue(newValue, emit)
		value = clamp(newValue, minValue, maxValue)
		local range = maxValue - minValue
		local percent = range == 0 and 0 or (value - minValue) / range
		fill.Size = UDim2.new(percent, 0, 1, 0)
		valueLabel.Text = tostring(math.floor(value * 100 + 0.5) / 100)

		if emit and callback then
			callback(value)
		end
	end

	local function setFromInput(input)
		local x = clamp(input.Position.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
		local percent = track.AbsoluteSize.X == 0 and 0 or x / track.AbsoluteSize.X
		setValue(minValue + ((maxValue - minValue) * percent), true)
	end

	track.MouseButton1Down:Connect(function(x)
		local trackWidth = track.AbsoluteSize.X
		local percent = trackWidth == 0 and 0 or clamp(x - track.AbsolutePosition.X, 0, trackWidth) / trackWidth
		setValue(minValue + ((maxValue - minValue) * percent), true)
	end)

	track.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			setFromInput(input)
		end
	end)

	setValue(value, false)

	return {
		SetValue = function(_, newValue)
			setValue(newValue, true)
		end,
		GetValue = function()
			return value
		end,
	}
end

function tabClass:Keybind(labelText, defaultKey, callback)
	local currentKey = defaultKey or Enum.KeyCode.Unknown
	local waiting = false
	local row = makeControlFrame(self.frame, 44)
	makeLabel(row, labelText, 110)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -118, 1, 0)
	btn.Position = UDim2.new(0, 118, 0, 0)
	btn.BackgroundColor3 = ui.theme.control
	btn.BorderSizePixel = 0
	btn.TextColor3 = ui.theme.text
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 14
	btn.Text = currentKey.Name
	btn.AutoButtonColor = false
	btn.Parent = row
	corner(btn, 6)
	stroke(btn, ui.theme.border, 0.5)
	setControlHover(btn, ui.theme.control)

	btn.MouseButton1Click:Connect(function()
		waiting = true
		btn.Text = "Press a key..."
	end)

	uis.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not waiting or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		waiting = false
		currentKey = input.KeyCode
		btn.Text = currentKey.Name

		if callback then
			callback(currentKey)
		end
	end)

	return {
		SetValue = function(_, keyCode)
			currentKey = keyCode
			btn.Text = currentKey.Name
		end,
		GetValue = function()
			return currentKey
		end,
	}
end

function tabClass:ColorInput(labelText, defaultColor, callback)
	local color = defaultColor or ui.theme.accent
	local hue, saturation, value = color:ToHSV()
	local expanded = false
	local draggingSquare = false
	local draggingHue = false
	local lastMeaningfulHue = hue
	local syncVisuals

	local row = makeControlFrame(self.frame, 44)
	makeLabel(row, labelText, 110)

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(1, -168, 1, 0)
	toggle.Position = UDim2.new(0, 118, 0, 0)
	toggle.BackgroundColor3 = ui.theme.control
	toggle.BorderSizePixel = 0
	toggle.TextColor3 = ui.theme.text
	toggle.Font = Enum.Font.GothamSemibold
	toggle.TextSize = 14
	toggle.TextXAlignment = Enum.TextXAlignment.Left
	toggle.AutoButtonColor = false
	toggle.Parent = row
	corner(toggle, 6)
	stroke(toggle, ui.theme.border, 0.5)
	padding(toggle, 10, 0, 10, 0)
	setControlHover(toggle, ui.theme.control)

	local preview = Instance.new("Frame")
	preview.Size = UDim2.new(0, 42, 1, 0)
	preview.Position = UDim2.new(1, -42, 0, 0)
	preview.BackgroundColor3 = color
	preview.BorderSizePixel = 0
	preview.Parent = row
	corner(preview, 6)
	stroke(preview, ui.theme.border, 0.5)

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(1, -118, 0, 148)
	panel.Position = UDim2.new(0, 118, 0, 50)
	panel.BackgroundColor3 = ui.theme.panel
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = row
	corner(panel, 6)
	stroke(panel, ui.theme.border, 0.35)
	padding(panel, 8, 8, 8, 8)

	local picker = Instance.new("Frame")
	picker.Size = UDim2.new(1, 0, 0, 80)
	picker.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
	picker.BorderSizePixel = 0
	picker.Parent = panel
	corner(picker, 6)

	local whiteGradient = Instance.new("Frame")
	whiteGradient.Size = UDim2.new(1, 0, 1, 0)
	whiteGradient.BackgroundColor3 = Color3.new(1, 1, 1)
	whiteGradient.BorderSizePixel = 0
	whiteGradient.Parent = picker
	corner(whiteGradient, 6)

	local whiteOverlay = Instance.new("UIGradient")
	whiteOverlay.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, 1, 1)),
	})
	whiteOverlay.Parent = whiteGradient

	local blackGradient = Instance.new("Frame")
	blackGradient.Size = UDim2.new(1, 0, 1, 0)
	blackGradient.BackgroundColor3 = Color3.new(0, 0, 0)
	blackGradient.BackgroundTransparency = 1
	blackGradient.BorderSizePixel = 0
	blackGradient.Parent = picker
	corner(blackGradient, 6)

	local blackOverlay = Instance.new("UIGradient")
	blackOverlay.Rotation = 90
	blackOverlay.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	blackOverlay.Parent = blackGradient

	local pickerCursor = Instance.new("Frame")
	pickerCursor.Size = UDim2.new(0, 10, 0, 10)
	pickerCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	pickerCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	pickerCursor.BorderSizePixel = 0
	pickerCursor.Parent = picker
	corner(pickerCursor, 999)
	stroke(pickerCursor, Color3.new(0, 0, 0), 0.2)

	local hueBar = Instance.new("Frame")
	hueBar.Size = UDim2.new(1, 0, 0, 14)
	hueBar.Position = UDim2.new(0, 0, 0, 92)
	hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
	hueBar.BorderSizePixel = 0
	hueBar.Parent = panel
	corner(hueBar, 999)

	local hueGradient = Instance.new("UIGradient")
	hueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
		ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
		ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
		ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
		ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
	})
	hueGradient.Parent = hueBar

	local hueCursor = Instance.new("Frame")
	hueCursor.Size = UDim2.new(0, 8, 1, 6)
	hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
	hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	hueCursor.BorderSizePixel = 0
	hueCursor.Parent = hueBar
	corner(hueCursor, 999)
	stroke(hueCursor, Color3.new(0, 0, 0), 0.2)

	local rgbBox = Instance.new("TextBox")
	rgbBox.Size = UDim2.new(1, 0, 0, 30)
	rgbBox.Position = UDim2.new(0, 0, 0, 114)
	rgbBox.BackgroundColor3 = ui.theme.control
	rgbBox.BorderSizePixel = 0
	rgbBox.TextColor3 = ui.theme.text
	rgbBox.PlaceholderColor3 = ui.theme.muted
	rgbBox.PlaceholderText = "R,G,B"
	rgbBox.ClearTextOnFocus = false
	rgbBox.Font = Enum.Font.Gotham
	rgbBox.TextSize = 14
	rgbBox.TextXAlignment = Enum.TextXAlignment.Left
	rgbBox.Parent = panel
	corner(rgbBox, 6)
	stroke(rgbBox, ui.theme.border, 0.5)
	padding(rgbBox, 10, 0, 10, 0)

	local function colorToText(nextColor)
		return tostring(math.floor(nextColor.R * 255 + 0.5)) .. "," .. tostring(math.floor(nextColor.G * 255 + 0.5)) .. "," .. tostring(math.floor(nextColor.B * 255 + 0.5))
	end

	local function setExpanded(isExpanded)
		expanded = isExpanded
		panel.Visible = isExpanded
		row.Size = UDim2.new(1, 0, 0, isExpanded and 198 or 44)
	end

	local function emit()
		if callback then
			callback(color)
		end
	end

	local function setFromColor(nextColor, shouldEmit)
		local nextHue, nextSaturation, nextValue = nextColor:ToHSV()

		if nextSaturation > 0.001 and nextValue > 0.001 then
			lastMeaningfulHue = nextHue
		end

		hue = (nextSaturation <= 0.001 or nextValue <= 0.001) and lastMeaningfulHue or nextHue
		saturation = nextSaturation
		value = nextValue
		color = nextColor

		syncVisuals(shouldEmit)
	end

	syncVisuals = function(shouldEmit)
		color = Color3.fromHSV(hue, saturation, value)
		preview.BackgroundColor3 = color
		picker.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		whiteOverlay.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, 1, 1)),
		})
		pickerCursor.Position = UDim2.new(saturation, 0, 1 - value, 0)
		hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
		rgbBox.Text = colorToText(color)
		toggle.Text = colorToText(color)

		if shouldEmit then
			emit()
		end
	end

	local function parseColor(text)
		local r, g, b = string.match(text, "^(%d+)%s*,%s*(%d+)%s*,%s*(%d+)$")
		if not r then
			return nil
		end

		return Color3.fromRGB(clamp(tonumber(r), 0, 255), clamp(tonumber(g), 0, 255), clamp(tonumber(b), 0, 255))
	end

	local function updateFromSquare(input)
		local x = clamp(input.Position.X - picker.AbsolutePosition.X, 0, picker.AbsoluteSize.X)
		local y = clamp(input.Position.Y - picker.AbsolutePosition.Y, 0, picker.AbsoluteSize.Y)
		saturation = picker.AbsoluteSize.X == 0 and 0 or x / picker.AbsoluteSize.X
		value = 1 - (picker.AbsoluteSize.Y == 0 and 0 or y / picker.AbsoluteSize.Y)
		syncVisuals(false)
	end

	local function updateFromHue(input)
		local x = clamp(input.Position.X - hueBar.AbsolutePosition.X, 0, hueBar.AbsoluteSize.X)
		hue = hueBar.AbsoluteSize.X == 0 and 0 or x / hueBar.AbsoluteSize.X
		syncVisuals(false)
	end

	toggle.MouseButton1Click:Connect(function()
		setExpanded(not expanded)
	end)

	picker.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSquare = true
			updateFromSquare(input)
		end
	end)

	hueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingHue = true
			updateFromHue(input)
		end
	end)

	uis.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		if draggingSquare then
			updateFromSquare(input)
		elseif draggingHue then
			updateFromHue(input)
		end
	end)

	uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local shouldEmit = draggingSquare or draggingHue
			draggingSquare = false
			draggingHue = false
			if shouldEmit then
				emit()
			end
		end
	end)

	rgbBox.FocusLost:Connect(function()
		local nextColor = parseColor(rgbBox.Text)
		if not nextColor then
			rgbBox.Text = colorToText(color)
			return
		end

		setFromColor(nextColor, true)
	end)

	setFromColor(color, false)

	return {
		button = toggle,
		box = rgbBox,
		panel = panel,
		GetValue = function()
			return color
		end,
		SetValue = function(_, newColor)
			if typeof(newColor) ~= "Color3" then
				return
			end
			setFromColor(newColor, false)
		end,
		SetOpen = function(_, isOpen)
			setExpanded(isOpen == true)
		end,
	}
end

function tabClass:ThemePicker(labelText, customColor)
	customColor = customColor or ui.theme.accent

	local mode = self:Dropdown(labelText or "Theme", { "Default Blue", "Custom Color" }, "Default Blue", function(value)
		if value == "Default Blue" then
			ui:SetTheme("default")
		else
			ui:SetTheme(customColor)
		end
	end)

	local colorInput
	colorInput = self:ColorInput("Custom Color", customColor, function(color)
		local wasOpen = colorInput and colorInput.panel and colorInput.panel.Visible
		customColor = color
		mode:SetValue("Custom Color")
		ui:SetTheme(color)
		if wasOpen and colorInput then
			colorInput:SetOpen(true)
		end
	end)

	return {
		mode = mode,
		colorInput = colorInput,
		SetDefault = function()
			mode:SetValue("Default Blue")
			ui:SetTheme("default")
		end,
		SetCustom = function(_, color)
			local wasOpen = colorInput and colorInput.panel and colorInput.panel.Visible
			if typeof(color) == "Color3" then
				customColor = color
				colorInput:SetValue(color)
			end
			mode:SetValue("Custom Color")
			ui:SetTheme(customColor)
			if wasOpen then
				colorInput:SetOpen(true)
			end
		end,
	}
end

function tabClass:Divider(text)
	local row = makeControlFrame(self.frame, text and 28 or 14)
	row.BackgroundTransparency = 1

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, 1)
	line.Position = UDim2.new(0, 0, 0.5, 0)
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.BackgroundColor3 = ui.theme.border
	line.BorderSizePixel = 0
	line.Parent = row

	if text and text ~= "" then
		local label = Instance.new("TextLabel")
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.new(0, 0, 0, 18)
		label.Position = UDim2.new(0, 12, 0.5, 0)
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.BackgroundColor3 = ui.theme.bg
		label.BorderSizePixel = 0
		label.Text = text
		label.TextColor3 = ui.theme.muted
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.Parent = row
		padding(label, 6, 0, 6, 0)
	end

	return row
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
	ui:_bindTheme(scroll, "ScrollBarImageColor3", "accent")

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
		ui:_bindTheme(btn, "BackgroundColor3", "accentDark", "panelLight", function()
			return self.values[option] == true
		end)

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
	ui:_bindTheme(scroll, "ScrollBarImageColor3", "accent")

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
