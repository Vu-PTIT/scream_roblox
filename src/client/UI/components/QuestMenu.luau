local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local Window = require(script.Parent.Window)
local Button = require(script.Parent.Button)

type QuestMenuProps = {
	Visible: boolean,
	OnClose: () -> (),
	Data: any, -- PlayerData
}

local function QuestItem(props: { Quest: any, Progress: number, IsClaimed: boolean })
	local q = props.Quest
	local isCompleted = props.Progress >= q.Required
	local ratio = math.clamp(props.Progress / q.Required, 0, 1)

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 100),
		BackgroundColor3 = Config.Theme.SecondaryBackground,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Stroke = React.createElement("UIStroke", {
			Color = Config.Theme.StrokeColor,
			Thickness = 1,
			Transparency = 0.5,
		}),

		Title = React.createElement("TextLabel", {
			Size = UDim2.new(0.65, 0, 0, 24),
			Position = UDim2.new(0, 15, 0, 12),
			Text = q.Title,
			TextColor3 = Config.Theme.TextMain,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
		}),

		Reward = React.createElement("TextLabel", {
			Size = UDim2.new(0.65, 0, 0, 20),
			Position = UDim2.new(0, 15, 0, 36),
			Text = "🎁 Reward: " .. tostring(q.Reward.Amount) .. " " .. q.Reward.Type,
			TextColor3 = Config.Theme.TextGold,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
		}),

		ProgressContainer = React.createElement("Frame", {
			Size = UDim2.new(0.6, 0, 0, 12),
			Position = UDim2.new(0, 15, 0, 68),
			BackgroundColor3 = Color3.fromRGB(20, 20, 30),
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Fill = React.createElement("Frame", {
				Size = UDim2.new(ratio, 0, 1, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Gradient = React.createElement("UIGradient", {
					Color = ColorSequence.new(Config.Theme.BtnQuestBase, Config.Theme.BtnQuestShadow),
				}),
			}),
			Text = React.createElement("TextLabel", {
				Size = UDim2.new(0.3, 0, 0, 12),
				Position = UDim2.new(1, 10, 0, 0),
				Text = string.format("%d/%d", math.floor(props.Progress), q.Required),
				TextColor3 = Config.Theme.TextSecondary,
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
			})
		}),

		ClaimButton = React.createElement(Button, {
			Text = if props.IsClaimed then "CLAIMED" else (if isCompleted then "CLAIM" else "LOCKED"),
			Size = UDim2.new(0, 110, 0, 40),
			Position = UDim2.new(1, -125, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Variant = if props.IsClaimed then "Secondary" else (if isCompleted then "Success" else "Cancel"),
			Enabled = isCompleted and not props.IsClaimed,
			OnClick = function()
				Remotes.Events.ClaimQuestReward:FireServer(q.Id)
			end,
		})
	})
end

local function QuestMenu(props: QuestMenuProps)
	local data = props.Data or {}
	local quests = data.Quests or {}
	local claimed = data.ClaimedQuests or {}

	local questElements = {}
	for i, q in ipairs(Config.Quests) do
		questElements[q.Id] = React.createElement(QuestItem, {
			Quest = q,
			Progress = quests[q.ActionType] or 0,
			IsClaimed = if claimed[q.Id] then true else false,
		})
	end

	return React.createElement(Window, {
		Title = "DAILY QUESTS",
		Icon = "📜",
		Visible = props.Visible,
		OnClose = props.OnClose,
		Size = UDim2.new(0, 520, 0, 560),
	}, {
		Scroll = React.createElement("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Config.Theme.BtnQuestBase,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, (function()
			local children = {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 12),
				}),
				Padding = React.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
				}),
			}
			for k, v in pairs(questElements) do
				children[k] = v
			end
			return children
		end)())
	})
end

return QuestMenu
