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
        TotalVocalPoints = 0,
        Attack = 0,
        MaxHealth = 100,
        DamageUpgradeLevel = 0,
        HealthUpgradeLevel = 0,
        Defense = 0,
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
            Size = UDim2.new(0, 460, 0, 45),
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
                Icon = "💰", Text = string.format("%s", tostring(math.floor(data.Gold or 0))),
                TextColor = Color3.fromRGB(240, 200, 50), BackgroundColor3 = Color3.fromRGB(35, 30, 20),
                Width = 120, LayoutOrder = 1,
            }),
            VPPill = React.createElement(PillLabel, {
                Icon = "🎙️", Text = string.format("VP: %s", tostring(math.floor(data.VocalPoints or 0))),
                TextColor = Color3.fromRGB(100, 200, 255), BackgroundColor = Color3.fromRGB(30, 40, 50),
                Width = 140, LayoutOrder = 2,
            }),
            RebirthPill = React.createElement(PillLabel, {
                Icon = "⭐", Text = string.format("Rebirth: %d (x%.2f)", data.RebirthCount or 0, data.RebirthMultiplier or 1),
                TextColor = Color3.new(1, 1, 1), BackgroundColor = Color3.fromRGB(45, 30, 60),
                Width = 180, LayoutOrder = 3,
            }),
        }),

        -- Health Bar (Top Left - Professional Position)
        HealthContainer = React.createElement("Frame", {
            Name = "HealthContainer",
            Size = UDim2.new(0, 220, 0, 45),
            Position = UDim2.new(0, 15, 0, 60),
            BackgroundColor3 = Config.Theme.Background,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Stroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(255, 100, 100), Transparency = 0.6, Thickness = 1.5,
            }),
            Icon = React.createElement("TextLabel", {
                Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
                Text = "❤️", TextSize = 20,
            }),
            BarBg = React.createElement("Frame", {
                Size = UDim2.new(1, -60, 0, 10), Position = UDim2.new(0, 45, 0, 22),
                BackgroundColor3 = Color3.fromRGB(40, 20, 20), BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                Fill = React.createElement("Frame", {
                    Size = UDim2.new(1, 0, 1, 0), -- This will be handled by a script or ref in a real app, 
                    -- but here we just show the structure. React handles state updates.
                    BackgroundColor3 = Color3.fromRGB(255, 60, 80), BorderSizePixel = 0,
                }, {
                    Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })
            }),
            Label = React.createElement("TextLabel", {
                Size = UDim2.new(1, -60, 0, 14), Position = UDim2.new(0, 45, 0, 6),
                BackgroundTransparency = 1, Text = "HP: 100 / 100",
                TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
        }),

        VPBar = React.createElement(ProgressBar, {
            Title = "REBIRTH PROGRESS", Icon = "📈",
            Current = math.floor(data.TotalVocalPoints or 0), Max = requiredVP,
            Position = UDim2.new(0.5, 0, 0, 25), AnchorPoint = Vector2.new(0.5, 0),
            FillGradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Config.Theme.PrimaryGradient[1]),
                ColorSequenceKeypoint.new(1, Config.Theme.PrimaryGradient[2])
            }),
        }),

        Stats = React.createElement(StatsBox, {
            Attack = (data.Attack or 0) + (data.DamageUpgradeLevel or 0) * (Config.GetUpgrade("damage_1") and Config.GetUpgrade("damage_1").StatPerLevel or 5),
            Defense = (data.Defense or 0) + (data.ArmorUpgradeLevel or 0) * (Config.GetUpgrade("armor_1") and Config.GetUpgrade("armor_1").StatPerLevel or 10),
            Position = UDim2.new(1, -15, 1, -15), AnchorPoint = Vector2.new(1, 1),
        })
    })
end

return HUDApp
