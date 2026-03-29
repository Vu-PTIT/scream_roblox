local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

export type PillLabelProps = {
    LayoutOrder: number?,
    Icon: string?,
    Text: string,
    TextColor: Color3?,
    BackgroundColor: Color3?,
    Width: number?,
    Height: number?,
}

-- Mặc định "beautiful" styling cho PillLabel
local function PillLabel(props: PillLabelProps)
    local width = props.Width or 120
    local height = props.Height or 40
    local iconText = (props.Icon and props.Icon .. " " or "") .. props.Text

    return React.createElement("Frame", {
        Size = UDim2.new(0, width, 0, height),
        BackgroundColor3 = props.BackgroundColor or Color3.fromRGB(35, 35, 40),
        BackgroundTransparency = 0.2, -- Glass look
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder,
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0, 10),
        }),
        -- Subtle highlight border
        Stroke = React.createElement("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 0.75,
            Thickness = 1,
        }),
        Icon = props.Icon and React.createElement("TextLabel", {
            Size = UDim2.new(0, height, 1, 0),
            BackgroundTransparency = 1,
            Text = props.Icon,
            TextSize = 18,
            ZIndex = 2,
        }),
        Label = React.createElement("TextLabel", {
            Size = UDim2.new(1, props.Icon and -height or 0, 1, 0),
            Position = UDim2.new(0, props.Icon and height or 0, 0, 0),
            BackgroundTransparency = 1,
            Text = props.Text,
            TextColor3 = props.TextColor or Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 2,
        }),
    })
end

return PillLabel
