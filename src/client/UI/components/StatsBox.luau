local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

export type StatsBoxProps = {
    Attack: number,
    Defense: number,
    Position: UDim2?,
    AnchorPoint: Vector2?,
}

local function StatRow(props: { Icon: string, Title: string, Value: number, TitleColor: Color3, LayoutOrder: number })
    return React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder = props.LayoutOrder,
    }, {
        Title = React.createElement("TextLabel", {
            Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
            Text = props.Icon .. " " .. props.Title .. ":",
            TextColor3 = props.TitleColor, Font = Enum.Font.GothamBold, TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
        }),
        Value = React.createElement("TextLabel", {
            Size = UDim2.new(0.5, -24, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1,
            Text = tostring(props.Value),
            TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2,
        }),
    })
end

local function StatsBox(props: StatsBoxProps)
    return React.createElement("Frame", {
        Name = "StatsFrame",
        Size = UDim2.new(0, 180, 0, 100),
        Position = props.Position or UDim2.new(0, 15, 1, -15),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 1),
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Stroke = React.createElement("UIStroke", {
            Color = Color3.fromRGB(100, 150, 255), Transparency = 0.6, Thickness = 1.5,
        }),
        Title = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 8), BackgroundTransparency = 1,
            Text = "CHARACTER STATS", TextColor3 = Color3.fromRGB(150, 180, 220),
            Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
        }),
        Separator = React.createElement("Frame", {
            Size = UDim2.new(0.8, 0, 0, 1), Position = UDim2.new(0.1, 0, 0, 32),
            BackgroundColor3 = Color3.fromRGB(100, 150, 255), BackgroundTransparency = 0.7, BorderSizePixel = 0,
        }),
        Shadow = React.createElement("ImageLabel", {
            BackgroundTransparency = 1, Image = "rbxassetid://6015897843", ImageColor3 = Color3.new(0,0,0),
            ImageTransparency = 0.6, SliceCenter = Rect.new(49, 49, 450, 450), ScaleType = Enum.ScaleType.Slice,
            Size = UDim2.new(1, 40, 1, 40), Position = UDim2.new(0.5, 0, 0.5, 5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 0,
        }),
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 2),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
        }),
        Padding = React.createElement("UIPadding", {
            PaddingBottom = UDim.new(0, 10)
        }),
        AtkRow = React.createElement(StatRow, {
            Icon = "⚔️", Title = "DAMAGE", Value = props.Attack, TitleColor = Color3.fromRGB(255, 150, 50), LayoutOrder = 1,
        }),
        DefRow = React.createElement(StatRow, {
            Icon = "🛡️", Title = "ARMOR", Value = props.Defense, TitleColor = Color3.fromRGB(50, 150, 255), LayoutOrder = 2,
        })
    })
end

return StatsBox
