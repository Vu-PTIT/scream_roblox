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
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder,
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0.5, 0),
        }),
        -- Thêm UIStroke để làm viền nhẹ cho đẹp hơn
        Stroke = React.createElement("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 0.85,
            Thickness = 1.5,
        }),
        -- DropShadow
        Shadow = React.createElement("ImageLabel", {
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.5,
            SliceCenter = Rect.new(49, 49, 450, 450),
            ScaleType = Enum.ScaleType.Slice,
            Size = UDim2.new(1, 30, 1, 30),
            Position = UDim2.new(0.5, 0, 0.5, 4),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 0,
        }),
        Label = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = iconText,
            TextColor3 = props.TextColor or Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 2,
        }),
    })
end

return PillLabel
