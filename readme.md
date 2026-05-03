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

main:Button("Run", function()
	status:SetText("Running")
end)

main:Toggle("Enabled", false, function(value)
	print("Enabled:", value)
end)

main:Input("Name", "Type a name", function(text)
	print("Name:", text)
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
- Horizontally scrolling tab bar.
- Scrollable tab content for larger UIs.
- Clear selected-tab styling.
- Buttons, toggles, labeled text inputs, labels, dropdowns, and multi dropdowns.
- Labels return an object with `SetText(text)` and `GetText()`.
- Dropdowns support `SetOptions(options)` and `SetValue(value)`.
- Multi dropdowns support `SetOptions(options)` and `SetValue(values)`.
