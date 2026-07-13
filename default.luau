local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local uis = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local http = game:GetService("HttpService")
local tweenService = game:GetService("TweenService")

print("------------------------loaded ui module-------------------------")
print("---------------------------Version:1.2---------------------------")
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
ui.openDropdowns = {}
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

local dropdownListClass = {}
dropdownListClass.__index = dropdownListClass

local windowCollapseTweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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

local function cloneArray(values)
	local copy = {}
	for _, value in ipairs(values or {}) do
		table.insert(copy, value)
	end
	return copy
end

local function valueExists(values, target)
	for _, value in ipairs(values or {}) do
		if value == target then
			return true
		end
	end
	return false
end

local function getSortedPlayers()
	local players = plrs:GetPlayers()
	table.sort(players, function(a, b)
		return string.lower(a.Name) < string.lower(b.Name)
	end)
	return players
end

local function getPlayerNames()
	local names = {}
	for _, player in ipairs(getSortedPlayers()) do
		table.insert(names, player.Name)
	end
	return names
end

local function resolvePlayer(value)
	if typeof(value) == "Instance" and value:IsA("Player") then
		return value
	end

	if type(value) == "string" then
		return plrs:FindFirstChild(value)
	end

	return nil
end

local function colorToData(color)
	return {
		r = math.floor(color.R * 255 + 0.5),
		g = math.floor(color.G * 255 + 0.5),
		b = math.floor(color.B * 255 + 0.5),
	}
end

local function dataToColor(data, fallback)
	if type(data) ~= "table" then
		return fallback
	end

	local r = tonumber(data.r)
	local g = tonumber(data.g)
	local b = tonumber(data.b)
	if r == nil or g == nil or b == nil then
		return fallback
	end

	return Color3.fromRGB(clamp(r, 0, 255), clamp(g, 0, 255), clamp(b, 0, 255))
end

local function bufferToHex(buf)
	local parts = table.create(buffer.len(buf))
	for index = 0, buffer.len(buf) - 1 do
		parts[index + 1] = string.format("%02X", buffer.readu8(buf, index))
	end
	return table.concat(parts)
end

local function hexToBuffer(hex)
	if type(hex) ~= "string" or (#hex % 2) ~= 0 then
		return nil
	end

	local out = buffer.create(#hex / 2)
	for index = 1, #hex, 2 do
		local byte = tonumber(string.sub(hex, index, index + 1), 16)
		if byte == nil then
			return nil
		end
		buffer.writeu8(out, (index - 1) / 2, byte)
	end

	return out
end

local function encodeSavePayload(payload)
	if buffer and buffer.fromstring and buffer.compress then
		local ok, encoded = pcall(function()
			local raw = buffer.fromstring(payload)
			return "C1:" .. bufferToHex(buffer.compress(raw))
		end)
		if ok and encoded then
			return encoded
		end
	end

	return "J1:" .. payload
end

local function decodeSavePayload(data)
	if type(data) ~= "string" then
		return nil, "Save data must be a string"
	end

	local mode, payload = string.match(data, "^(%u%d):(.*)$")
	if mode == "C1" then
		if not (buffer and buffer.decompress and buffer.tostring) then
			return nil, "Compressed save data is not supported in this Luau runtime"
		end

		local compressed = hexToBuffer(payload)
		if not compressed then
			return nil, "Compressed save data is malformed"
		end

		local ok, decoded = pcall(function()
			return buffer.tostring(buffer.decompress(compressed))
		end)
		if not ok then
			return nil, "Compressed save data could not be decoded"
		end

		return decoded
	end

	if mode == "J1" then
		return payload
	end

	return nil, "Unknown save data format"
end

local function registerSavableControl(tab, kind, getter, loader)
	if not tab or not tab.window or (tab._suspendSaveRegistration or 0) > 0 then
		return
	end

	table.insert(tab.window._saveControls, {
		kind = kind,
		get = getter,
		load = loader,
	})
end

local function updateScale()
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	guiScale.Scale = clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.78, 1.12)
end

updateScale()
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		updateScale()
		ui:RefreshOpenDropdownPositions()
	end)
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

local function normalizeLabelText(text)
	if text == nil then
		return ""
	end

	local textValue = tostring(text)
	return string.gsub(textValue, "\\n", "\n")
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
	label.Text = normalizeLabelText(text)
	label.TextColor3 = ui.theme.muted
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	textLimit(label, 10, 14)
	return label
end

local function setZIndexRecursive(root, zIndex)
	if root:IsA("GuiObject") then
		root.ZIndex = zIndex
	end

	for _, child in ipairs(root:GetChildren()) do
		setZIndexRecursive(child, zIndex)
	end
end

local function getViewportSize()
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function getVisibleVerticalBounds(guiObject)
	local top = 0
	local bottom = getViewportSize().Y
	local current = guiObject

	while current and current ~= gui do
		if current:IsA("GuiObject") and (current.ClipsDescendants or current:IsA("ScrollingFrame")) then
			local currentTop = current.AbsolutePosition.Y
			local currentBottom = currentTop + current.AbsoluteSize.Y
			top = math.max(top, currentTop)
			bottom = math.min(bottom, currentBottom)
		end

		current = current.Parent
	end

	return top, bottom
end

local function positionDropdownMenu(dropdown)
	if not dropdown or not dropdown.button or not dropdown.button.Parent or not dropdown.menu then
		return
	end

	local buttonTop = dropdown.button.AbsolutePosition.Y
	local buttonBottom = buttonTop + dropdown.button.AbsoluteSize.Y
	local menuHeight = dropdown.menu.AbsoluteSize.Y

	if menuHeight <= 0 then
		menuHeight = dropdown.menu.Size.Y.Offset
	end

	local visibleTop, visibleBottom = getVisibleVerticalBounds(dropdown.button)
	local gap = 6
	local spaceAbove = buttonTop - visibleTop - gap
	local spaceBelow = visibleBottom - buttonBottom - gap
	local openAbove = false

	if spaceBelow < menuHeight and spaceAbove > spaceBelow then
		openAbove = true
	end

	if openAbove then
		dropdown.menu.Position = UDim2.new(0, 0, 0, -(menuHeight + gap))
	else
		dropdown.menu.Position = UDim2.new(0, 0, 0, 44 + gap)
	end
end

function ui:RefreshOpenDropdownPositions()
	for dropdown in pairs(self.openDropdowns) do
		if dropdown.open and dropdown.button and dropdown.button.Parent and dropdown.menu and dropdown.menu.Parent then
			positionDropdownMenu(dropdown)
		else
			self.openDropdowns[dropdown] = nil
		end
	end
end

local function connectDropdownPositionTracking(dropdown)
	local function refreshIfOpen()
		if dropdown.open then
			positionDropdownMenu(dropdown)
		end
	end

	dropdown._positionConnections = dropdown._positionConnections or {}

	local function watch(instance, property)
		table.insert(dropdown._positionConnections, instance:GetPropertyChangedSignal(property):Connect(refreshIfOpen))
	end

	watch(dropdown.button, "AbsolutePosition")
	watch(dropdown.button, "AbsoluteSize")
	watch(dropdown.menu, "AbsoluteSize")

	local current = dropdown.container
	while current and current ~= gui do
		if current:IsA("GuiObject") then
			if current.ClipsDescendants or current:IsA("ScrollingFrame") then
				watch(current, "AbsolutePosition")
				watch(current, "AbsoluteSize")
			end

			if current:IsA("ScrollingFrame") then
				watch(current, "CanvasPosition")
			end
		end

		current = current.Parent
	end
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
		ui:RefreshOpenDropdownPositions()
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

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 44)
	topBar.BackgroundColor3 = ui.theme.panel
	topBar.BorderSizePixel = 0
	topBar.Active = true
	topBar.Parent = main
	corner(topBar, 8)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -76, 1, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = ui.theme.text
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = topBar
	padding(title, 12, 0, 0, 0)
	textLimit(title, 14, 20)

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Size = UDim2.new(0, 24, 0, 24)
	minimizeButton.Position = UDim2.new(1, -56, 0.5, -12)
	minimizeButton.BackgroundColor3 = ui.theme.control
	minimizeButton.BorderSizePixel = 0
	minimizeButton.Text = "-"
	minimizeButton.TextColor3 = ui.theme.text
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.TextSize = 14
	minimizeButton.AutoButtonColor = false
	minimizeButton.Parent = topBar
	corner(minimizeButton, 6)
	stroke(minimizeButton, ui.theme.border, 0.5)
	setControlHover(minimizeButton, ui.theme.control)

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 24, 0, 24)
	closeButton.Position = UDim2.new(1, -28, 0.5, -12)
	closeButton.BackgroundColor3 = ui.theme.control
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = ui.theme.text
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 12
	closeButton.AutoButtonColor = false
	closeButton.Parent = topBar
	corner(closeButton, 6)
	stroke(closeButton, ui.theme.border, 0.5)
	setControlHover(closeButton, ui.theme.control)

	local bodyClip = Instance.new("Frame")
	bodyClip.Size = UDim2.new(1, 0, 1, -44)
	bodyClip.Position = UDim2.new(0, 0, 0, 44)
	bodyClip.BackgroundTransparency = 1
	bodyClip.BorderSizePixel = 0
	bodyClip.ClipsDescendants = true
	bodyClip.Parent = main

	local bodyContent = Instance.new("Frame")
	bodyContent.Size = UDim2.new(1, 0, 1, 0)
	bodyContent.BackgroundTransparency = 1
	bodyContent.BorderSizePixel = 0
	bodyContent.Parent = bodyClip

	local tabsBar = Instance.new("ScrollingFrame")
	tabsBar.Size = UDim2.new(1, 0, 0, 40)
	tabsBar.Position = UDim2.new(0, 0, 0, 0)
	tabsBar.BackgroundColor3 = ui.theme.panel
	tabsBar.BorderSizePixel = 0
	tabsBar.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabsBar.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabsBar.ScrollingDirection = Enum.ScrollingDirection.X
	tabsBar.ScrollBarThickness = 3
	tabsBar.ScrollBarImageColor3 = ui.theme.accent
	tabsBar.Parent = bodyContent
	ui:_bindTheme(tabsBar, "ScrollBarImageColor3", "accent")
	padding(tabsBar, 8, 5, 8, 5)

	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabsLayout.Padding = UDim.new(0, 6)
	tabsLayout.Parent = tabsBar

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -20, 1, -54)
	content.Position = UDim2.new(0, 10, 0, 46)
	content.BackgroundTransparency = 1
	content.ClipsDescendants = true
	content.Parent = bodyContent

	local function beginDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and ui.dragWindow == nil then
			ui.dragWindow = main
			ui.dragStart = input.Position
			ui.startPos = main.Position
		end
	end

	topBar.InputBegan:Connect(beginDrag)
	title.InputBegan:Connect(beginDrag)

	local win = setmetatable({}, windowClass)
	win.frame = main
	win.topBar = topBar
	win.sizeConstraint = sizeConstraint
	win._defaultMinSize = sizeConstraint.MinSize
	win.bodyClip = bodyClip
	win.bodyContent = bodyContent
	win.tabsBar = tabsBar
	win.content = content
	win.tabs = {}
	win.tabButtons = {}
	win.currentTab = nil
	win.title = title
	win.closeButton = closeButton
	win.minimizeButton = minimizeButton
	win.isMinimized = false
	win._isAnimatingMinimize = false
	win._expandedSize = main.Size
	win._closeFunction = nil
	win._saveControls = {}

	minimizeButton.MouseButton1Click:Connect(function()
		win:SetMinimized(not win.isMinimized)
	end)

	closeButton.MouseButton1Click:Connect(function()
		if win._closeFunction then
			win._closeFunction()
		end
	end)

	table.insert(self.windows, win)

	return win
end

function windowClass:ChangeTitle(newtitle)
	self.title.Text = newtitle
end

function windowClass:setclosefunction(callback)
	if callback ~= nil and type(callback) ~= "function" then
		error("window:setclosefunction expected a function or nil")
	end

	self._closeFunction = callback
end

function windowClass:SetCloseFunction(callback)
	self:setclosefunction(callback)
end

function windowClass:SetMinimized(isMinimized)
	isMinimized = not not isMinimized
	if self._isAnimatingMinimize or self.isMinimized == isMinimized then
		return
	end

	if isMinimized then
		self._expandedSize = self.frame.Size
		self.sizeConstraint.MinSize = Vector2.new(self._defaultMinSize.X, 44)
	else
		self.sizeConstraint.MinSize = self._defaultMinSize
	end

	self._isAnimatingMinimize = true
	self.isMinimized = isMinimized
	self.minimizeButton.Text = isMinimized and "+" or "-"

	local expandedSize = self._expandedSize or self.frame.Size
	local collapsedSize = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, 44)
	local mainTween = tweenService:Create(self.frame, windowCollapseTweenInfo, {
		Size = isMinimized and collapsedSize or expandedSize,
	})
	local bodyTween = tweenService:Create(self.bodyContent, windowCollapseTweenInfo, {
		Position = isMinimized and UDim2.new(0, 0, -1, 0) or UDim2.new(0, 0, 0, 0),
	})

	mainTween.Completed:Connect(function()
		self._isAnimatingMinimize = false
	end)

	bodyTween:Play()
	mainTween:Play()
end

function windowClass:ToggleMinimized()
	self:SetMinimized(not self.isMinimized)
end

function windowClass:Save()
	local controls = {}

	for index, control in ipairs(self._saveControls) do
		controls[index] = {
			k = control.kind,
			v = control.get(),
		}
	end

	return encodeSavePayload(http:JSONEncode({
		version = 1,
		controls = controls,
	}))
end

function windowClass:Load(data)
	local payload, decodeError = decodeSavePayload(data)
	if not payload then
		error(decodeError)
	end

	local ok, decoded = pcall(function()
		return http:JSONDecode(payload)
	end)
	if not ok or type(decoded) ~= "table" then
		error("Save data is not valid JSON")
	end

	local controls = decoded.controls
	if type(controls) ~= "table" then
		error("Save data is missing controls")
	end

	for index, savedControl in ipairs(controls) do
		local liveControl = self._saveControls[index]
		if liveControl and liveControl.kind == savedControl.k then
			liveControl.load(savedControl.v)
		end
	end
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
	tab.window = self
	tab.labels = {}
	tab._suspendSaveRegistration = 0

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

	local row = makeControlFrame(self.frame, 44)

	local container = Instance.new("TextButton")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = ui.theme.control
	container.BorderSizePixel = 0
	container.Text = ""
	container.AutoButtonColor = false
	container.Parent = row
	corner(container, 6)
	stroke(container, ui.theme.border, 0.5)
	setControlHover(container, ui.theme.control)
	padding(container, 12, 0, 12, 0)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -72, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = ui.theme.text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local switch = Instance.new("Frame")
	switch.Size = UDim2.new(0, 44, 0, 24)
	switch.Position = UDim2.new(1, -44, 0.5, -12)
	switch.BackgroundColor3 = state and ui.theme.accent or ui.theme.panelLight
	switch.BorderSizePixel = 0
	switch.Parent = container
	corner(switch, 999)
	stroke(switch, ui.theme.border, 0.4)
	ui:_bindTheme(switch, "BackgroundColor3", "accent", "panelLight", function()
		return state
	end)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.BackgroundColor3 = ui.theme.text
	knob.BorderSizePixel = 0
	knob.Parent = switch
	corner(knob, 999)

	local stateLabel = Instance.new("TextLabel")
	stateLabel.Size = UDim2.new(0, 40, 1, 0)
	stateLabel.Position = UDim2.new(1, -92, 0, 0)
	stateLabel.BackgroundTransparency = 1
	stateLabel.Text = state and "ON" or "OFF"
	stateLabel.TextColor3 = ui.theme.muted
	stateLabel.Font = Enum.Font.GothamBold
	stateLabel.TextSize = 12
	stateLabel.TextXAlignment = Enum.TextXAlignment.Right
	stateLabel.Parent = container

	local function syncToggle()
		stateLabel.Text = state and "ON" or "OFF"
		switch.BackgroundColor3 = state and ui.theme.accent or ui.theme.panelLight
		knob.Position = UDim2.new(0, state and 23 or 3, 0.5, 0)
	end

	container.MouseButton1Click:Connect(function()
		state = not state
		syncToggle()

		if callback then
			callback(state)
		end
	end)

	syncToggle()

	registerSavableControl(self, "toggle", function()
		return state
	end, function(value)
		state = value == true
		syncToggle()
		ui:RefreshTheme()
		if callback then
			callback(state)
		end
	end)

	return {
		SetValue = function(_, value)
			state = value == true
			syncToggle()
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
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = ui.theme.control
	container.BorderSizePixel = 0
	container.Parent = row
	corner(container, 6)
	stroke(container, ui.theme.border, 0.5)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 110, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = ui.theme.text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	padding(label, 12, 0, 0, 0)

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -126, 0, 30)
	box.Position = UDim2.new(0, 114, 0.5, -15)
	box.BackgroundColor3 = ui.theme.panelLight
	box.BorderSizePixel = 0
	box.TextColor3 = ui.theme.text
	box.PlaceholderColor3 = ui.theme.muted
	box.PlaceholderText = placeholder or ""
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Parent = container
	corner(box, 6)
	stroke(box, ui.theme.border, 0.5)
	padding(box, 10, 0, 10, 0)

	box.FocusLost:Connect(function()
		if callback then
			callback(box.Text)
		end
	end)

	registerSavableControl(self, "input", function()
		return box.Text
	end, function(value)
		box.Text = tostring(value or "")
		if callback then
			callback(box.Text)
		end
	end)

	return box
end

function tabClass:NumberInput(labelText, defaultValue, callback, minValue, maxValue, stepValue)
	stepValue = stepValue or 1

	local currentValue = defaultValue or 0
	local box

	local function clampValue(value)
		if minValue then
			value = math.max(minValue, value)
		end
		if maxValue then
			value = math.min(maxValue, value)
		end
		return value
	end

	local function formatValue(value)
		if math.floor(value) == value then
			return tostring(value)
		end
		return tostring(math.floor(value * 1000 + 0.5) / 1000)
	end

	local function applyValue(value, emit)
		currentValue = clampValue(value)
		box.Text = formatValue(currentValue)

		if emit and callback then
			callback(currentValue)
		end
	end

	self._suspendSaveRegistration += 1
	box = self:Input(labelText, tostring(defaultValue or 0), function(text)
		local value = normalizeNumber(text, currentValue)
		applyValue(value, true)
	end)
	self._suspendSaveRegistration -= 1

	local container = box.Parent
	box.Size = UDim2.new(1, -180, 0, 30)

	local downButton = Instance.new("TextButton")
	downButton.Size = UDim2.new(0, 28, 0, 30)
	downButton.Position = UDim2.new(1, -62, 0.5, -15)
	downButton.BackgroundColor3 = ui.theme.panelLight
	downButton.BorderSizePixel = 0
	downButton.Text = "-"
	downButton.TextColor3 = ui.theme.text
	downButton.Font = Enum.Font.GothamBold
	downButton.TextSize = 16
	downButton.AutoButtonColor = false
	downButton.Parent = container
	corner(downButton, 6)
	stroke(downButton, ui.theme.border, 0.5)
	setControlHover(downButton, ui.theme.panelLight)

	local upButton = Instance.new("TextButton")
	upButton.Size = UDim2.new(0, 28, 0, 30)
	upButton.Position = UDim2.new(1, -30, 0.5, -15)
	upButton.BackgroundColor3 = ui.theme.panelLight
	upButton.BorderSizePixel = 0
	upButton.Text = "+"
	upButton.TextColor3 = ui.theme.text
	upButton.Font = Enum.Font.GothamBold
	upButton.TextSize = 16
	upButton.AutoButtonColor = false
	upButton.Parent = container
	corner(upButton, 6)
	stroke(upButton, ui.theme.border, 0.5)
	setControlHover(upButton, ui.theme.panelLight)

	downButton.MouseButton1Click:Connect(function()
		applyValue(currentValue - stepValue, true)
	end)

	upButton.MouseButton1Click:Connect(function()
		applyValue(currentValue + stepValue, true)
	end)

	applyValue(currentValue, false)

	registerSavableControl(self, "number", function()
		return currentValue
	end, function(value)
		applyValue(normalizeNumber(tostring(value), currentValue), true)
	end)

	return box
end

function tabClass:PasswordInput(labelText, placeholder, callback)
	local realText = ""
	local masked = true
	local updatingText = false
	self._suspendSaveRegistration += 1
	local box = self:Input(labelText, placeholder or "Password")
	self._suspendSaveRegistration -= 1
	local container = box.Parent
	box.Size = UDim2.new(1, -168, 0, 30)

	local toggleButton = Instance.new("TextButton")
	toggleButton.Size = UDim2.new(0, 52, 0, 30)
	toggleButton.Position = UDim2.new(1, -54, 0.5, -15)
	toggleButton.BackgroundColor3 = ui.theme.panelLight
	toggleButton.BorderSizePixel = 0
	toggleButton.TextColor3 = ui.theme.muted
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextSize = 11
	toggleButton.AutoButtonColor = false
	toggleButton.Parent = container
	corner(toggleButton, 6)
	stroke(toggleButton, ui.theme.border, 0.5)
	setControlHover(toggleButton, ui.theme.panelLight)

	local function syncPasswordDisplay()
		updatingText = true
		box.Text = masked and string.rep("*", string.len(realText)) or realText
		toggleButton.Text = masked and "SHOW" or "HIDE"
		updatingText = false
	end

	box.FocusLost:Connect(function()
		if callback then
			callback(realText)
		end
	end)

	box:GetPropertyChangedSignal("Text"):Connect(function()
		if updatingText or not box:IsFocused() then
			return
		end

		local text = box.Text
		if masked then
			local maskedText = string.rep("*", string.len(realText))
			if text == maskedText then
				return
			end

			if string.len(text) < string.len(maskedText) then
				realText = string.sub(realText, 1, string.len(text))
			elseif string.len(text) > string.len(maskedText) then
				realText ..= string.sub(text, string.len(maskedText) + 1)
			end
		else
			realText = text
		end

		syncPasswordDisplay()
	end)

	toggleButton.MouseButton1Click:Connect(function()
		masked = not masked
		syncPasswordDisplay()
	end)

	syncPasswordDisplay()

	registerSavableControl(self, "password", function()
		return realText
	end, function(value)
		realText = tostring(value or "")
		syncPasswordDisplay()
		if callback then
			callback(realText)
		end
	end)

	return {
		box = box,
		button = toggleButton,
		GetValue = function()
			return realText
		end,
		SetValue = function(_, value)
			realText = tostring(value or "")
			syncPasswordDisplay()
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

	registerSavableControl(self, "textarea", function()
		return box.Text
	end, function(value)
		box.Text = tostring(value or "")
		if callback then
			callback(box.Text)
		end
	end)

	return box
end

function tabClass:SearchInput(labelText, placeholder, callback)
	local box = self:Input(labelText, placeholder or "Search", callback)
	local suppressChangeCallback = false

	box:GetPropertyChangedSignal("Text"):Connect(function()
		if suppressChangeCallback then
			return
		end

		if callback then
			callback(box.Text)
		end
	end)

	local controls = self.window and self.window._saveControls
	local lastControl = controls and controls[#controls]
	if lastControl and lastControl.kind == "input" then
		lastControl.kind = "search"
		lastControl.load = function(value)
			suppressChangeCallback = true
			box.Text = tostring(value or "")
			suppressChangeCallback = false
			if callback then
				callback(box.Text)
			end
		end
	end

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

	registerSavableControl(self, "slider", function()
		return value
	end, function(newValue)
		setValue(normalizeNumber(tostring(newValue), value), true)
	end)

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

	registerSavableControl(self, "keybind", function()
		return currentKey.Name
	end, function(keyName)
		local nextKey = Enum.KeyCode[tostring(keyName or "Unknown")] or Enum.KeyCode.Unknown
		currentKey = nextKey
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
	row.ZIndex = 2

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = ui.theme.control
	container.BorderSizePixel = 0
	container.Parent = row
	corner(container, 6)
	stroke(container, ui.theme.border, 0.5)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 110, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = ui.theme.text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	padding(label, 12, 0, 0, 0)

	local shield = Instance.new("TextButton")
	shield.Size = UDim2.new(1, 0, 0, 2000)
	shield.Position = UDim2.new(0, 0, 0, 44)
	shield.BackgroundTransparency = 1
	shield.BorderSizePixel = 0
	shield.Text = ""
	shield.Visible = false
	shield.Active = true
	shield.AutoButtonColor = false
	shield.Parent = row
	shield.ZIndex = 10

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(1, -176, 0, 30)
	toggle.Position = UDim2.new(0, 114, 0.5, -15)
	toggle.BackgroundColor3 = ui.theme.panelLight
	toggle.BorderSizePixel = 0
	toggle.TextColor3 = ui.theme.text
	toggle.Font = Enum.Font.GothamSemibold
	toggle.TextSize = 14
	toggle.TextXAlignment = Enum.TextXAlignment.Left
	toggle.AutoButtonColor = false
	toggle.Parent = container
	corner(toggle, 6)
	stroke(toggle, ui.theme.border, 0.5)
	padding(toggle, 10, 0, 10, 0)
	setControlHover(toggle, ui.theme.panelLight)
	toggle.ZIndex = 2

	local preview = Instance.new("Frame")
	preview.Size = UDim2.new(0, 30, 0, 30)
	preview.Position = UDim2.new(1, -30, 0.5, -15)
	preview.BackgroundColor3 = color
	preview.BorderSizePixel = 0
	preview.Parent = container
	corner(preview, 6)
	stroke(preview, ui.theme.border, 0.5)
	preview.ZIndex = 2

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(1, -118, 0, 282)
	panel.Position = UDim2.new(0, 118, 0, 50)
	panel.BackgroundColor3 = ui.theme.panel
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Active = true
	panel.Parent = row
	corner(panel, 6)
	stroke(panel, ui.theme.border, 0.35)
	padding(panel, 8, 8, 8, 8)
	setZIndexRecursive(panel, 20)

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 24, 0, 24)
	closeButton.Position = UDim2.new(1, -24, 0, 0)
	closeButton.BackgroundColor3 = ui.theme.control
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = ui.theme.text
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 12
	closeButton.AutoButtonColor = false
	closeButton.Parent = panel
	corner(closeButton, 6)
	stroke(closeButton, ui.theme.border, 0.5)
	setControlHover(closeButton, ui.theme.control)

	local picker = Instance.new("Frame")
	picker.Size = UDim2.new(1, 0, 0, 128)
	picker.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
	picker.BorderSizePixel = 0
	picker.Active = true
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
	pickerCursor.Size = UDim2.new(0, 14, 0, 14)
	pickerCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	pickerCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	pickerCursor.BorderSizePixel = 0
	pickerCursor.Parent = picker
	corner(pickerCursor, 999)
	stroke(pickerCursor, Color3.new(0, 0, 0), 0.2)

	local hueBar = Instance.new("Frame")
	hueBar.Size = UDim2.new(1, 0, 0, 16)
	hueBar.Position = UDim2.new(0, 0, 0, 140)
	hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
	hueBar.BorderSizePixel = 0
	hueBar.Active = true
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
	hueCursor.Size = UDim2.new(0, 10, 1, 8)
	hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
	hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	hueCursor.BorderSizePixel = 0
	hueCursor.Parent = hueBar
	corner(hueCursor, 999)
	stroke(hueCursor, Color3.new(0, 0, 0), 0.2)

	local statsRow = Instance.new("Frame")
	statsRow.Size = UDim2.new(1, 0, 0, 20)
	statsRow.Position = UDim2.new(0, 0, 0, 164)
	statsRow.BackgroundTransparency = 1
	statsRow.Parent = panel

	local hsvLabel = Instance.new("TextLabel")
	hsvLabel.Size = UDim2.new(0.5, -4, 1, 0)
	hsvLabel.BackgroundTransparency = 1
	hsvLabel.TextColor3 = ui.theme.muted
	hsvLabel.Font = Enum.Font.GothamMedium
	hsvLabel.TextSize = 12
	hsvLabel.TextXAlignment = Enum.TextXAlignment.Left
	hsvLabel.Parent = statsRow

	local hexPreviewLabel = Instance.new("TextLabel")
	hexPreviewLabel.Size = UDim2.new(0.5, -4, 1, 0)
	hexPreviewLabel.Position = UDim2.new(0.5, 8, 0, 0)
	hexPreviewLabel.BackgroundTransparency = 1
	hexPreviewLabel.TextColor3 = ui.theme.muted
	hexPreviewLabel.Font = Enum.Font.GothamMedium
	hexPreviewLabel.TextSize = 12
	hexPreviewLabel.TextXAlignment = Enum.TextXAlignment.Right
	hexPreviewLabel.Parent = statsRow

	local rgbBox = Instance.new("TextBox")
	rgbBox.Size = UDim2.new(0.5, -4, 0, 30)
	rgbBox.Position = UDim2.new(0, 0, 0, 190)
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

	local hexBox = Instance.new("TextBox")
	hexBox.Size = UDim2.new(0.5, -4, 0, 30)
	hexBox.Position = UDim2.new(0.5, 8, 0, 190)
	hexBox.BackgroundColor3 = ui.theme.control
	hexBox.BorderSizePixel = 0
	hexBox.TextColor3 = ui.theme.text
	hexBox.PlaceholderColor3 = ui.theme.muted
	hexBox.PlaceholderText = "#RRGGBB"
	hexBox.ClearTextOnFocus = false
	hexBox.Font = Enum.Font.Gotham
	hexBox.TextSize = 14
	hexBox.TextXAlignment = Enum.TextXAlignment.Left
	hexBox.Parent = panel
	corner(hexBox, 6)
	stroke(hexBox, ui.theme.border, 0.5)
	padding(hexBox, 10, 0, 10, 0)

	local swatchTitle = Instance.new("TextLabel")
	swatchTitle.Size = UDim2.new(1, 0, 0, 16)
	swatchTitle.Position = UDim2.new(0, 0, 0, 228)
	swatchTitle.BackgroundTransparency = 1
	swatchTitle.Text = "Quick Colors"
	swatchTitle.TextColor3 = ui.theme.muted
	swatchTitle.Font = Enum.Font.GothamMedium
	swatchTitle.TextSize = 12
	swatchTitle.TextXAlignment = Enum.TextXAlignment.Left
	swatchTitle.Parent = panel

	local swatchGrid = Instance.new("Frame")
	swatchGrid.Size = UDim2.new(1, 0, 0, 38)
	swatchGrid.Position = UDim2.new(0, 0, 0, 246)
	swatchGrid.BackgroundTransparency = 1
	swatchGrid.Parent = panel

	local swatchLayout = Instance.new("UIGridLayout")
	swatchLayout.CellPadding = UDim2.new(0, 6, 0, 6)
	swatchLayout.CellSize = UDim2.new(0, 28, 0, 28)
	swatchLayout.FillDirectionMaxCells = 8
	swatchLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	swatchLayout.SortOrder = Enum.SortOrder.LayoutOrder
	swatchLayout.Parent = swatchGrid

	local function colorToText(nextColor)
		return tostring(math.floor(nextColor.R * 255 + 0.5)) .. "," .. tostring(math.floor(nextColor.G * 255 + 0.5)) .. "," .. tostring(math.floor(nextColor.B * 255 + 0.5))
	end

	local function channelToHex(channel)
		return string.format("%02X", clamp(math.floor(channel * 255 + 0.5), 0, 255))
	end

	local function colorToHex(nextColor)
		return "#" .. channelToHex(nextColor.R) .. channelToHex(nextColor.G) .. channelToHex(nextColor.B)
	end

	local function setExpanded(isExpanded)
		expanded = isExpanded
		panel.Visible = isExpanded
		shield.Visible = isExpanded
		if isExpanded then
			setZIndexRecursive(panel, 20)
		end
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
		hexBox.Text = colorToHex(color)
		hsvLabel.Text = string.format("H:%03d  S:%03d  V:%03d", math.floor(hue * 360 + 0.5), math.floor(saturation * 100 + 0.5), math.floor(value * 100 + 0.5))
		hexPreviewLabel.Text = "Hex " .. colorToHex(color)
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

	local function parseHex(text)
		local hex = string.upper(string.gsub(text or "", "#", ""))
		if string.len(hex) == 3 then
			hex = string.sub(hex, 1, 1) .. string.sub(hex, 1, 1)
				.. string.sub(hex, 2, 2) .. string.sub(hex, 2, 2)
				.. string.sub(hex, 3, 3) .. string.sub(hex, 3, 3)
		end

		if not string.match(hex, "^[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]$") then
			return nil
		end

		return Color3.fromRGB(
			tonumber(string.sub(hex, 1, 2), 16),
			tonumber(string.sub(hex, 3, 4), 16),
			tonumber(string.sub(hex, 5, 6), 16)
		)
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

	for _, swatchColor in ipairs({
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(0, 0, 0),
		Color3.fromRGB(244, 67, 54),
		Color3.fromRGB(255, 152, 0),
		Color3.fromRGB(255, 235, 59),
		Color3.fromRGB(76, 175, 80),
		Color3.fromRGB(33, 150, 243),
		Color3.fromRGB(156, 39, 176),
		Color3.fromRGB(255, 64, 129),
		Color3.fromRGB(0, 188, 212),
		Color3.fromRGB(121, 85, 72),
		Color3.fromRGB(96, 125, 139),
	}) do
		local swatch = Instance.new("TextButton")
		swatch.BackgroundColor3 = swatchColor
		swatch.BorderSizePixel = 0
		swatch.Text = ""
		swatch.AutoButtonColor = false
		swatch.Parent = swatchGrid
		corner(swatch, 6)
		stroke(swatch, ui.theme.border, 0.35)

		swatch.MouseEnter:Connect(function()
			swatch.BackgroundColor3 = swatchColor:Lerp(Color3.new(1, 1, 1), 0.12)
		end)

		swatch.MouseLeave:Connect(function()
			swatch.BackgroundColor3 = swatchColor
		end)

		swatch.MouseButton1Click:Connect(function()
			setFromColor(swatchColor, true)
		end)
	end

	toggle.MouseButton1Click:Connect(function()
		setExpanded(not expanded)
	end)

	closeButton.MouseButton1Click:Connect(function()
		setExpanded(false)
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

	hexBox.FocusLost:Connect(function()
		local nextColor = parseHex(hexBox.Text)
		if not nextColor then
			hexBox.Text = colorToHex(color)
			return
		end

		setFromColor(nextColor, true)
	end)

	setFromColor(color, false)

	registerSavableControl(self, "color", function()
		return colorToData(color)
	end, function(newColor)
		local resolvedColor = dataToColor(newColor, color)
		setFromColor(resolvedColor, true)
	end)

	return {
		button = toggle,
		box = rgbBox,
		hexBox = hexBox,
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
	self._suspendSaveRegistration += 1

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
	self._suspendSaveRegistration -= 1

	registerSavableControl(self, "themePicker", function()
		return {
			mode = mode.value or "Default Blue",
			color = colorToData(colorInput:GetValue()),
		}
	end, function(savedValue)
		if type(savedValue) ~= "table" then
			return
		end

		local savedColor = dataToColor(savedValue.color, colorInput:GetValue())
		customColor = savedColor
		if savedValue.mode == "Default Blue" then
			colorInput:SetValue(savedColor)
			mode:SetValue("Default Blue")
			ui:SetTheme("default")
		else
			colorInput:SetValue(savedColor)
			mode:SetValue("Custom Color")
			ui:SetTheme(savedColor)
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
	self.text = normalizeLabelText(text)
	self.label.Text = self.text
end

function labelClass:GetText()
	return self.text
end

function tabClass:SetLabelText(labelid, newtext)
	local label = self.labels and self.labels[labelid]
	if not label then
		warn("tab:SetLabelText could not find label with id " .. tostring(labelid))
		return nil
	end

	label:SetText(newtext or "")
	return label
end

function tabClass:setlabeltext(labelid, text)
	return self:SetLabelText(labelid, text)
end

function tabClass:Label(labelid, text)
	local labelText = text
	local labelKey = labelid

	if text == nil then
		labelText = labelid
		labelKey = nil
	end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundColor3 = ui.theme.panel
	label.BorderSizePixel = 0
	label.Text = normalizeLabelText(labelText)
	label.TextColor3 = ui.theme.text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = self.frame
	corner(label, 6)
	stroke(label, ui.theme.border, 0.5)
	padding(label, 10, 8, 10, 8)
	textLimit(label, 10, 14)

	local item = setmetatable({}, labelClass)
	item.label = label
	item.text = normalizeLabelText(labelText)

	if labelKey ~= nil then
		self.labels[labelKey] = item
	end

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
	if self.shield then
		self.shield.Visible = isOpen
	end
	if isOpen then
		ui.openDropdowns[self] = true
		positionDropdownMenu(self)
		setZIndexRecursive(self.menu, 20)
	else
		ui.openDropdowns[self] = nil
	end
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

	if self.open then
		positionDropdownMenu(self)
	end
end

local function createDropdownControl(parent, title, options, default, callback)
	local container = makeControlFrame(parent, 44)

	local shield = Instance.new("TextButton")
	shield.Size = UDim2.new(1, 0, 0, 2000)
	shield.Position = UDim2.new(0, 0, 0, 44)
	shield.BackgroundTransparency = 1
	shield.BorderSizePixel = 0
	shield.Text = ""
	shield.Visible = false
	shield.Active = true
	shield.AutoButtonColor = false
	shield.Parent = container
	shield.ZIndex = 10

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
	button.ZIndex = 15

	local menu = Instance.new("Frame")
	menu.Size = UDim2.new(1, 0, 0, 126)
	menu.Position = UDim2.new(0, 0, 0, 50)
	menu.BackgroundColor3 = ui.theme.panel
	menu.BorderSizePixel = 0
	menu.Visible = false
	menu.Parent = container
	corner(menu, 6)
	stroke(menu, ui.theme.border, 0.35)
	setZIndexRecursive(menu, 20)

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
	drop.shield = shield
	drop.open = false
	connectDropdownPositionTracking(drop)

	button.MouseButton1Click:Connect(function()
		drop:SetOpen(not drop.open)
	end)

	drop:SetOptions(options)

	if default ~= nil then
		drop:SetValue(default)
	else
		button.Text = title .. " v"
	end

	return drop
end

function tabClass:Dropdown(title, options, default, callback)
	local dropdown = createDropdownControl(self.frame, title, options, default, callback)

	registerSavableControl(self, "dropdown", function()
		return dropdown.value
	end, function(value)
		if value == nil then
			return
		end
		dropdown:SetValue(value)
	end)

	return dropdown
end

function tabClass:PlayerInput(title, defaultPlayer, callback)
	local currentPlayer = resolvePlayer(defaultPlayer)
	local dropdown
	local originalSetValue
	self._suspendSaveRegistration += 1

	local function refreshOptions()
		local names = getPlayerNames()
		dropdown:SetOptions(names)

		if currentPlayer and not resolvePlayer(currentPlayer) then
			currentPlayer = nil
		end

		if currentPlayer then
			dropdown.value = currentPlayer.Name
			dropdown.button.Text = title .. ": " .. currentPlayer.Name
		elseif #names == 0 then
			dropdown.value = nil
			dropdown.button.Text = title .. ": None"
		else
			dropdown.button.Text = title .. " v"
		end
	end

	dropdown = self:Dropdown(title, getPlayerNames(), currentPlayer and currentPlayer.Name or nil, function(value)
		currentPlayer = resolvePlayer(value)
		if callback then
			callback(currentPlayer)
		end
	end)
	self._suspendSaveRegistration -= 1

	plrs.PlayerAdded:Connect(refreshOptions)
	plrs.PlayerRemoving:Connect(function(player)
		if currentPlayer == player then
			currentPlayer = nil
			if callback then
				callback(nil)
			end
		end
		refreshOptions()
	end)

	originalSetValue = dropdown.SetValue
	dropdown.SetValue = function(self, value)
		currentPlayer = resolvePlayer(value)
		if currentPlayer then
			originalSetValue(self, currentPlayer.Name)
		else
			self.value = nil
			self.button.Text = title .. " v"
		end
	end

	dropdown.GetValue = function()
		return currentPlayer
	end

	registerSavableControl(self, "player", function()
		return currentPlayer and currentPlayer.Name or nil
	end, function(value)
		currentPlayer = resolvePlayer(value)
		dropdown:SetValue(value)
		if not currentPlayer and callback then
			callback(nil)
		end
	end)

	refreshOptions()
	return dropdown
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
	if self.shield then
		self.shield.Visible = isOpen
	end
	if isOpen then
		ui.openDropdowns[self] = true
		positionDropdownMenu(self)
		setZIndexRecursive(self.menu, 20)
	else
		ui.openDropdowns[self] = nil
	end
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
	if self.open then
		positionDropdownMenu(self)
	end
end

function multiDropdownClass:SetOptions(options)
	self.options = options or {}
	self:Refresh()
end

function dropdownListClass:_sanitizeValue(value)
	if value ~= nil then
		return value
	end

	if self.defaultValue ~= nil then
		return self.defaultValue
	end

	if #self.options > 0 then
		return self.options[1]
	end

	return nil
end

function dropdownListClass:_emit()
	if self.callback then
		self.callback(self:GetValue())
	end
end

function dropdownListClass:_refreshHeader()
	local count = #self.rows
	local minLengthText = tostring(self.minLength or 0)
	local maxLengthText = self.maxLength == math.huge and "inf" or tostring(self.maxLength)
	self.titleLabel.Text = string.format("%s (%d/%s, min %s)", self.title, count, maxLengthText, minLengthText)
	self.addButton.Text = count >= self.maxLength and "Max" or "+"
	self.addButton.Active = count < self.maxLength
	self.addButton.AutoButtonColor = count < self.maxLength
	self.addButton.BackgroundColor3 = count < self.maxLength and ui.theme.accent or ui.theme.panelLight

	for _, row in ipairs(self.rows) do
		local canRemove = count > (self.minLength or 0)
		row.removeButton.Active = canRemove
		row.removeButton.AutoButtonColor = canRemove
		row.removeButton.TextTransparency = canRemove and 0 or 0.45
		row.removeButton.BackgroundColor3 = canRemove and ui.theme.panelLight or ui.theme.control
	end
end

function dropdownListClass:_createRow(initialValue)
	local rowHolder = Instance.new("Frame")
	rowHolder.Size = UDim2.new(1, 0, 0, 44)
	rowHolder.BackgroundTransparency = 1
	rowHolder.Parent = self.rowsFrame

	local removeButton = Instance.new("TextButton")
	removeButton.Size = UDim2.new(0, 36, 0, 36)
	removeButton.Position = UDim2.new(1, -36, 0.5, 0)
	removeButton.AnchorPoint = Vector2.new(0, 0.5)
	removeButton.BackgroundColor3 = ui.theme.panelLight
	removeButton.BorderSizePixel = 0
	removeButton.Text = "X"
	removeButton.TextColor3 = ui.theme.text
	removeButton.Font = Enum.Font.GothamBold
	removeButton.TextSize = 14
	removeButton.AutoButtonColor = false
	removeButton.Parent = rowHolder
	corner(removeButton, 6)
	stroke(removeButton, ui.theme.border, 0.4)
	setControlHover(removeButton, ui.theme.panelLight)

	local dropdown = createDropdownControl(
		rowHolder,
		self.namePrefix .. " " .. tostring(#self.rows + 1),
		self.options,
		self:_sanitizeValue(initialValue),
		function(selected)
			if not self.suppressCallback then
				self:_emit()
			end
		end
	)

	dropdown.container.Size = UDim2.new(1, -44, 0, 44)

	local row = {
		holder = rowHolder,
		dropdown = dropdown,
		removeButton = removeButton,
	}

	removeButton.MouseButton1Click:Connect(function()
		if #self.rows <= (self.minLength or 0) then
			return
		end

		for index, currentRow in ipairs(self.rows) do
			if currentRow == row then
				table.remove(self.rows, index)
				rowHolder:Destroy()
				self:_renumberRows()
				self:_refreshHeader()
				if not self.suppressCallback then
					self:_emit()
				end
				return
			end
		end
	end)

	table.insert(self.rows, row)
	self:_refreshHeader()
	if not self.suppressCallback then
		self:_emit()
	end
	return row
end

function dropdownListClass:_renumberRows()
	for index, row in ipairs(self.rows) do
		row.dropdown.title = self.namePrefix .. " " .. tostring(index)
		if row.dropdown.value ~= nil then
			row.dropdown.button.Text = row.dropdown.title .. ": " .. tostring(row.dropdown.value)
		else
			row.dropdown.button.Text = row.dropdown.title .. (row.dropdown.open and " ^" or " v")
		end
	end
end

function dropdownListClass:AddValue(value)
	if #self.rows >= self.maxLength then
		return false
	end

	self:_createRow(value)
	self:_renumberRows()
	return true
end

function dropdownListClass:Clear()
	for _, row in ipairs(self.rows) do
		row.holder:Destroy()
	end
	self.rows = {}
	self:_refreshHeader()
	if not self.suppressCallback then
		self:_emit()
	end
end

function dropdownListClass:SetValue(values)
	self.suppressCallback = true
	self:Clear()

	for _, value in ipairs(values or {}) do
		if #self.rows >= self.maxLength then
			break
		end
		self:_createRow(value)
	end

	while #self.rows < (self.minLength or 0) and #self.rows < self.maxLength do
		self:_createRow(self:_sanitizeValue(nil))
	end

	self:_renumberRows()
	self.suppressCallback = false
	self:_emit()
end

function dropdownListClass:GetValue()
	local values = {}
	for index, row in ipairs(self.rows) do
		values[index] = row.dropdown.value
	end
	return values
end

function dropdownListClass:SetOptions(options)
	self.options = cloneArray(options or {})
	for _, row in ipairs(self.rows) do
		row.dropdown:SetOptions(self.options)
		if row.dropdown.value ~= nil and not valueExists(self.options, row.dropdown.value) then
			row.dropdown.value = nil
			row.dropdown:SetValue(self:_sanitizeValue(nil))
		end
	end
	self:_emit()
end

function dropdownListClass:SetDefaultValue(value)
	self.defaultValue = value
end

function tabClass:DropdownList(name, minLength, maxLength, startList, dropdownChoices, defaultDropdownChoice, callback)
	if type(maxLength) ~= "number" and maxLength ~= nil then
		callback = defaultDropdownChoice
		defaultDropdownChoice = dropdownChoices
		dropdownChoices = startList
		startList = maxLength
		maxLength = minLength
		minLength = 0
	end

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 0)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.BackgroundColor3 = ui.theme.panel
	container.BorderSizePixel = 0
	container.Parent = self.frame
	corner(container, 6)
	stroke(container, ui.theme.border, 0.5)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 42)
	header.BackgroundTransparency = 1
	header.Parent = container

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -54, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = ui.theme.text
	titleLabel.Font = Enum.Font.GothamSemibold
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = name or "List"
	titleLabel.Parent = header
	padding(titleLabel, 12, 0, 0, 0)

	local addButton = Instance.new("TextButton")
	addButton.Size = UDim2.new(0, 32, 0, 32)
	addButton.Position = UDim2.new(1, -12, 0.5, 0)
	addButton.AnchorPoint = Vector2.new(1, 0.5)
	addButton.BackgroundColor3 = ui.theme.accent
	addButton.BorderSizePixel = 0
	addButton.Text = "+"
	addButton.TextColor3 = ui.theme.text
	addButton.Font = Enum.Font.GothamBold
	addButton.TextSize = 20
	addButton.AutoButtonColor = false
	addButton.Parent = header
	corner(addButton, 6)
	stroke(addButton, ui.theme.border, 0.35)

	local rowsFrame = Instance.new("Frame")
	rowsFrame.Size = UDim2.new(1, -24, 0, 0)
	rowsFrame.Position = UDim2.new(0, 12, 0, 42)
	rowsFrame.AutomaticSize = Enum.AutomaticSize.Y
	rowsFrame.BackgroundTransparency = 1
	rowsFrame.Parent = container

	local rowsLayout = Instance.new("UIListLayout")
	rowsLayout.Padding = UDim.new(0, 8)
	rowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowsLayout.Parent = rowsFrame

	local bottomPadding = Instance.new("Frame")
	bottomPadding.Size = UDim2.new(1, 0, 0, 12)
	bottomPadding.BackgroundTransparency = 1
	bottomPadding.Parent = rowsFrame
	bottomPadding.LayoutOrder = 9999

	local list = setmetatable({}, dropdownListClass)
	list.container = container
	list.header = header
	list.titleLabel = titleLabel
	list.addButton = addButton
	list.rowsFrame = rowsFrame
	list.title = name or "List"
	list.namePrefix = name or "Item"
	list.maxLength = math.max(0, tonumber(maxLength) or math.huge)
	list.minLength = math.max(0, tonumber(minLength) or 0)
	if list.minLength > list.maxLength then
		list.minLength = list.maxLength
	end
	list.options = cloneArray(dropdownChoices or {})
	list.defaultValue = defaultDropdownChoice
	list.callback = callback
	list.rows = {}

	addButton.MouseEnter:Connect(function()
		if #list.rows < list.maxLength then
			addButton.BackgroundColor3 = ui.theme.accentDark
		end
	end)

	addButton.MouseLeave:Connect(function()
		list:_refreshHeader()
	end)

	addButton.MouseButton1Click:Connect(function()
		list:AddValue(list:_sanitizeValue(nil))
	end)

	list:_refreshHeader()
	list:SetValue(startList or {})

	registerSavableControl(self, "dropdownList", function()
		return list:GetValue()
	end, function(values)
		list:SetValue(values or {})
	end)

	return list
end

function tabClass:MultiDropdown(title, options, defaults, callback)
	local container = makeControlFrame(self.frame, 44)

	local shield = Instance.new("TextButton")
	shield.Size = UDim2.new(1, 0, 0, 2000)
	shield.Position = UDim2.new(0, 0, 0, 44)
	shield.BackgroundTransparency = 1
	shield.BorderSizePixel = 0
	shield.Text = ""
	shield.Visible = false
	shield.Active = true
	shield.AutoButtonColor = false
	shield.Parent = container
	shield.ZIndex = 10

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
	button.ZIndex = 15

	local menu = Instance.new("Frame")
	menu.Size = UDim2.new(1, 0, 0, 158)
	menu.Position = UDim2.new(0, 0, 0, 50)
	menu.BackgroundColor3 = ui.theme.panel
	menu.BorderSizePixel = 0
	menu.Visible = false
	menu.Parent = container
	corner(menu, 6)
	stroke(menu, ui.theme.border, 0.35)
	setZIndexRecursive(menu, 20)

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
	drop.shield = shield
	drop.open = false
	drop.options = options or {}
	drop.values = {}
	connectDropdownPositionTracking(drop)

	button.MouseButton1Click:Connect(function()
		drop:SetOpen(not drop.open)
	end)

	drop:SetValue(defaults or {})

	registerSavableControl(self, "multiDropdown", function()
		local values = {}
		for _, option in ipairs(drop.options or {}) do
			if drop.values[option] then
				table.insert(values, option)
			end
		end
		return values
	end, function(values)
		drop:SetValue(values or {})
	end)

	return drop
end

function tabClass:MultiPlayerInput(title, defaultPlayers, callback)
	local currentPlayers = {}
	local dropdown
	local originalSetValue
	self._suspendSaveRegistration += 1

	for _, playerValue in ipairs(defaultPlayers or {}) do
		local player = resolvePlayer(playerValue)
		if player then
			table.insert(currentPlayers, player)
		end
	end

	local function syncCurrentPlayers()
		local nextPlayers = {}
		for _, player in ipairs(currentPlayers) do
			if resolvePlayer(player) then
				table.insert(nextPlayers, player)
			end
		end
		currentPlayers = nextPlayers
	end

	local function refreshOptions()
		syncCurrentPlayers()
		dropdown:SetOptions(getPlayerNames())
		dropdown.values = {}
		for _, player in ipairs(currentPlayers) do
			dropdown.values[player.Name] = true
		end
		dropdown:Refresh()
	end

	dropdown = self:MultiDropdown(title, getPlayerNames(), currentPlayers, function(values)
		local players = {}
		for _, value in ipairs(values) do
			local player = resolvePlayer(value)
			if player then
				table.insert(players, player)
			end
		end
		currentPlayers = players
		if callback then
			callback(players)
		end
	end)
	self._suspendSaveRegistration -= 1

	plrs.PlayerAdded:Connect(refreshOptions)
	plrs.PlayerRemoving:Connect(function(player)
		local changed = false
		local nextPlayers = {}
		for _, currentPlayer in ipairs(currentPlayers) do
			if currentPlayer ~= player then
				table.insert(nextPlayers, currentPlayer)
			else
				changed = true
			end
		end
		currentPlayers = nextPlayers
		refreshOptions()
		if changed and callback then
			callback(currentPlayers)
		end
	end)

	originalSetValue = dropdown.SetValue
	dropdown.SetValue = function(self, values)
		local players = {}
		local playerNames = {}
		for _, value in ipairs(values or {}) do
			local player = resolvePlayer(value)
			if player then
				table.insert(players, player)
				table.insert(playerNames, player.Name)
			end
		end
		currentPlayers = players
		originalSetValue(self, playerNames)
	end

	dropdown.GetValue = function()
		return currentPlayers
	end

	registerSavableControl(self, "multiPlayer", function()
		local names = {}
		for _, player in ipairs(currentPlayers) do
			table.insert(names, player.Name)
		end
		return names
	end, function(values)
		dropdown:SetValue(values or {})
	end)

	refreshOptions()
	return dropdown
end

return ui
