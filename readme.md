# ui-modules

A simple Roblox Luau UI module for creating draggable windows with tabs and common controls.

## Load

```luau
local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/BullerWilliam/ui-modules/refs/heads/main/default.luau"))()
```

## Example

```luau
local window = ui:CreateWindow("Example UI")

local main = window:CreateTab("Main")
local settings = window:CreateTab("Settings")

local status = main:Label("Ready")

main:ThemePicker("Theme", Color3.fromRGB(255, 90, 120))
main:Divider("Actions")

main:Button("Run", function()
	status:SetText("Running")
end)

main:Toggle("Enabled", false, function(value)
	print("Enabled:", value)
end)

main:Input("Name", "Type a name", function(text)
	print("Name:", text)
end)

main:NumberInput("WalkSpeed", 16, function(value)
	print("Speed:", value)
end, 1, 100, 2)

main:Slider("Volume", 0, 100, 50, function(value)
	print("Volume:", value)
end)

main:Keybind("Open Menu", Enum.KeyCode.RightShift, function(keyCode)
	print("Keybind:", keyCode.Name)
end)

main:Dropdown("Mode", { "Easy", "Normal", "Hard" }, "Normal", function(value)
	print("Mode:", value)
end)

settings:MultiDropdown("Features", { "ESP", "Speed", "Fly", "Noclip" }, { "ESP" }, function(values)
	print("Selected:", table.concat(values, ", "))
end)
```

## Features

- Draggable, auto-scaled windows.
- Theme switching with default blue or a custom accent color.
- Horizontally scrolling tab bar.
- Scrollable tab content for larger UIs.
- Clear selected-tab styling.
- Dividers with optional labels for sectioning content.
- Buttons, toggles, labels, dropdowns, and multi dropdowns.
- Input helpers for text, stepped number input, password input with show/hide, paragraph text, search, slider, keybind, and a visual color picker with RGB entry.
- Labels return an object with `SetText(text)` and `GetText()`.
- Themes can be changed with `ui:SetTheme("default")`, `ui:SetTheme(Color3.fromRGB(255, 90, 120))`, `ui:SetAccentColor(color)`, or `ui:UseDefaultTheme()`.
- Dropdowns support `SetOptions(options)` and `SetValue(value)`.
- Multi dropdowns support `SetOptions(options)` and `SetValue(values)`.

## Inputs

```luau
tab:Input("Name", "Placeholder", callback)
tab:NumberInput("Amount", 10, callback, 0, 100, 5)
tab:PasswordInput("Password", "Secret", callback)
tab:TextArea("Notes", "Write more text", callback)
tab:SearchInput("Search", "Find something", callback)
tab:Slider("Volume", 0, 100, 50, callback)
tab:Keybind("Menu Key", Enum.KeyCode.RightShift, callback)
tab:ColorInput("Accent", Color3.fromRGB(75, 139, 255), callback)
tab:ThemePicker("Theme", Color3.fromRGB(255, 90, 120))
tab:Divider()
tab:Divider("Section")
```
