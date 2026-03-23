local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local StatsBox = require(script.Parent.Parent.components.StatsBox)

return function(target)
    local element = React.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
    }, {
        Stats = React.createElement(StatsBox, {
            Attack = 150,
            Defense = 45,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
        })
    })
    
    local root = ReactRoblox.createRoot(target)
    root:render(element)
    
    return function()
        root:unmount()
    end
end
