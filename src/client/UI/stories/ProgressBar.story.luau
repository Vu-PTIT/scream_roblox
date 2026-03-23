local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local ProgressBar = require(script.Parent.Parent.components.ProgressBar)

local function App()
    local pct, setPct = React.useState(0)
    
    React.useEffect(function()
        local t = 0
        local connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
            t += dt
            local newPct = (math.sin(t) + 1) / 2 -- animates 0 to 1
            setPct(newPct)
        end)
        return function()
            connection:Disconnect()
        end
    end, {})
    
    return React.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 10),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
        Bar1 = React.createElement(ProgressBar, {
            Title = "Vocal Points",
            Icon = "🎤",
            Current = math.floor(pct * 10000),
            Max = 10000,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
        })
    })
end

return function(target)
    local root = ReactRoblox.createRoot(target)
    root:render(React.createElement(App))
    
    return function()
        root:unmount()
    end
end
