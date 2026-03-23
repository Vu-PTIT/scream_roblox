local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)

local PillLabel = require(script.Parent.components.PillLabel)
local ProgressBar = require(script.Parent.components.ProgressBar)
local StatsBox = require(script.Parent.components.StatsBox)

-- Lắng nghe event thay đổi data (này tuỳ logic game)
local DataController: any = nil
task.defer(function()
    DataController = require(script.Parent.Parent.Controllers.DataController)
end)

local function HUDApp()
    local data, setData = React.useState({
        Gold = 0,
        RebirthCount = 0,
        RebirthMultiplier = 1,
        VocalPoints = 0,
        Attack = 0,
        AttackUpgradeLevel = 0,
        SpeakerUpgradeLevel = 0,
        Defense = 0,
        DefenseUpgradeLevel = 0,
        ArmorUpgradeLevel = 0,
    })

    React.useEffect(function()
        local connection
        local tries = 0
        local function check()
            if DataController and DataController.OnDataChanged then
                -- Load initial data
                local initialData = DataController.GetData()
                if initialData then
                    setData(function(prev)
                        local newD = table.clone(prev)
                        for k, v in pairs(initialData) do newD[k] = v end
                        return newD
                    end)
                end
                
                -- Nghe update
                connection = DataController.OnDataChanged(function(key, val)
                    setData(function(prev)
                        if key == "__all__" then
                            return val
                        else
                            local d = table.clone(prev)
                            d[key] = val
                            return d
                        end
                    end)
                end)
            else
                tries += 1
                if tries < 20 then
                    task.delay(0.1, check)
                end
            end
        end
        check()

        return function()
            if connection then connection:Disconnect() end
        end
    end, {})

    local requiredVP = Config.Rebirth.VocalPointsRequired

    return React.createElement("ScreenGui", {
        Name = "HUD",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 0,
    }, {
        -- Base Frame Layer to wrap elements
        TopRightContainer = React.createElement("Frame", {
            Name = "TopRightContainer",
            Size = UDim2.new(0, 320, 0, 45),
            Position = UDim2.new(1, -15, 0, 60),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
        }, {
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 12),
            }),
            GoldPill = React.createElement(PillLabel, {
                Icon = "💰", Text = tostring(math.floor(data.Gold or 0)),
                TextColor = Color3.fromRGB(240, 200, 50), BackgroundColor = Color3.fromRGB(35, 35, 40),
                Width = 120, LayoutOrder = 1,
            }),
            RebirthPill = React.createElement(PillLabel, {
                Icon = "⭐", Text = string.format("Rebirth: %d (x%.2f)", data.RebirthCount or 0, data.RebirthMultiplier or 1),
                TextColor = Color3.new(1, 1, 1), BackgroundColor = Color3.fromRGB(45, 30, 60),
                Width = 180, LayoutOrder = 2,
            }),
        }),

        VPBar = React.createElement(ProgressBar, {
            Title = Config.Localization.HUD.VocalPointsTitle, Icon = "🎤",
            Current = math.floor(data.VocalPoints or 0), Max = requiredVP,
            Position = UDim2.new(0, 15, 1, -15), AnchorPoint = Vector2.new(0, 1),
            FillGradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Config.Theme.PrimaryGradient[1]),
                ColorSequenceKeypoint.new(1, Config.Theme.PrimaryGradient[2])
            }),
        }),

        Stats = React.createElement(StatsBox, {
            Attack = (data.Attack or 0) + (data.AttackUpgradeLevel or 0) * Config.Upgrades[1].StatPerLevel + (data.SpeakerUpgradeLevel or 0) * Config.Upgrades[2].StatPerLevel,
            Defense = (data.Defense or 0) + (data.DefenseUpgradeLevel or 0) * Config.Upgrades[3].StatPerLevel + (data.ArmorUpgradeLevel or 0) * Config.Upgrades[4].StatPerLevel,
            Position = UDim2.new(1, -15, 1, -15), AnchorPoint = Vector2.new(1, 1),
        })
    })
end

return HUDApp
