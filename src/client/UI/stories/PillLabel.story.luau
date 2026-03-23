local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local PillLabel = require(script.Parent.Parent.components.PillLabel)

return function(target)
    local element = React.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 10),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
        Pill1 = React.createElement(PillLabel, {
            Icon = "💰",
            Text = "1,000",
            TextColor = Color3.fromRGB(240, 200, 50),
            BackgroundColor = Color3.fromRGB(35, 35, 40),
            Width = 120,
        }),
        Pill2 = React.createElement(PillLabel, {
            Icon = "⭐",
            Text = "Rebirth: 2 (x1.50)",
            TextColor = Color3.new(1, 1, 1),
            BackgroundColor = Color3.fromRGB(45, 30, 60),
            Width = 180,
        }),
    })
    
    local root = ReactRoblox.createRoot(target)
    root:render(element)
    
    return function()
        root:unmount()
    end
end
