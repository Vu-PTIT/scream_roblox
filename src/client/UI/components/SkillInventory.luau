local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local Window = require(script.Parent.Window)
local Button = require(script.Parent.Button)

type SkillInventoryProps = {
	Visible: boolean,
	OnClose: () -> (),
	Data: any, -- PlayerData
}

local function SkillCard(props: { Skill: any, EquippedSlot: number? })
	local skill = props.Skill
	local rarityColor = Config.Theme.RarityColors[skill.Rarity] or Color3.new(1, 1, 1)
	
	local skillCfg = nil
	for _, cfg in ipairs(Config.Skills) do
		if cfg.SkillType == skill.SkillType then
			skillCfg = cfg
			break
		end
	end

	return React.createElement("Frame", {
		Size = UDim2.new(0, 128, 0, 150),
		BackgroundColor3 = Config.Theme.SecondaryBackground,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Stroke = React.createElement("UIStroke", {
			Color = if props.EquippedSlot then Color3.fromRGB(180, 100, 255) else Config.Theme.StrokeColor,
			Thickness = if props.EquippedSlot then 2 else 1,
			Transparency = 0.5,
		}),

		Icon = React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 60),
			Text = if skillCfg then skillCfg.Icon else "📜",
			TextSize = 40,
			BackgroundTransparency = 1,
		}),

		Name = React.createElement("TextLabel", {
			Size = UDim2.new(1, -10, 0, 18),
			Position = UDim2.new(0, 5, 0, 65),
			Text = if skillCfg then skillCfg.DisplayName else skill.SkillType,
			TextColor3 = rarityColor,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextScaled = true,
			BackgroundTransparency = 1,
		}),

		Stats = React.createElement("TextLabel", {
			Size = UDim2.new(1, -10, 0, 14),
			Position = UDim2.new(0, 5, 0, 83),
			Text = if skillCfg then string.format("x%.1f DMG | %.1fs", skillCfg.DamageMult, skillCfg.Cooldown) else "",
			TextColor3 = Config.Theme.TextSecondary,
			Font = Enum.Font.Gotham,
			TextSize = 10,
			BackgroundTransparency = 1,
		}),

		Actions = React.createElement("Frame", {
			Size = UDim2.new(1, -16, 0, 28),
			Position = UDim2.new(0, 8, 1, -36),
			BackgroundTransparency = 1,
		}, if props.EquippedSlot then {
			Unequip = React.createElement(Button, {
				Text = "✓ UNEQUIP (S" .. props.EquippedSlot .. ")",
				Size = UDim2.new(1, 0, 1, 0),
				Variant = "Success",
				OnClick = function()
					Remotes.Events.SetSkillEquipped:FireServer(skill.Id, false)
				end,
			})
		} else {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
			}),
			S1 = React.createElement(Button, {
				Text = "S1",
				Size = UDim2.new(0.5, -2, 1, 0),
				Variant = "Primary",
				OnClick = function()
					Remotes.Events.SetSkillEquipped:FireServer(skill.Id, true, 1)
				end,
			}),
			S2 = React.createElement(Button, {
				Text = "S2",
				Size = UDim2.new(0.5, -2, 1, 0),
				Variant = "Primary",
				OnClick = function()
					Remotes.Events.SetSkillEquipped:FireServer(skill.Id, true, 2)
				end,
			}),
		})
	})
end

local function SkillInventory(props: SkillInventoryProps)
	local filter, setFilter = React.useState("All")
	local data = props.Data or {}
	local skills = data.Skills or {}
	local equippedSkillIds = data.EquippedSkillIds or {}

	local skillCards = {}
	for _, skill in ipairs(skills) do
		if filter == "All" or skill.Rarity == filter then
			local equippedSlot = nil
			if equippedSkillIds[1] == skill.Id then equippedSlot = 1
			elseif equippedSkillIds[2] == skill.Id then equippedSlot = 2
			end

			skillCards[skill.Id] = React.createElement(SkillCard, {
				Skill = skill,
				EquippedSlot = equippedSlot,
			})
		end
	end

	local rarities = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary"}
	local filterButtons = {}
	for i, r in ipairs(rarities) do
		filterButtons[r] = React.createElement(Button, {
			Text = r,
			Size = UDim2.new(0, 85, 1, 0),
			Variant = if filter == r then "Primary" else "Cancel",
			OnClick = function() setFilter(r) end,
			LayoutOrder = i,
		})
	end

	return React.createElement(Window, {
		Title = "SKILL SCROLLS & INVENTORY",
		Icon = "🎴",
		Visible = props.Visible,
		OnClose = props.OnClose,
		Size = UDim2.new(0, 620, 0, 580),
	}, {
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),

		-- Gacha Buttons
		GachaRow = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 15),
			}),
			Open1x = React.createElement(Button, {
				Text = string.format("OPEN 1X (%d 💰)", Config.SkillScrollCost),
				Size = UDim2.new(0, 200, 0, 48),
				Variant = "Primary",
				OnClick = function() Remotes.Events.OpenSkillScroll:FireServer(1) end,
			}),
			Open10x = React.createElement(Button, {
				Text = string.format("OPEN 10X (%d 💰)", Config.SkillScrollCost * 10),
				Size = UDim2.new(0, 200, 0, 48),
				Variant = "Primary",
				OnClick = function() Remotes.Events.OpenSkillScroll:FireServer(10) end,
			}),
		}),

		-- Filters
		Filters = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, (function()
			local children = {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 5),
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
			}
			for k, v in pairs(filterButtons) do
				children[k] = v
			end
			return children
		end)()),

		-- Grid
		Scroll = React.createElement("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -110),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Color3.fromRGB(180, 100, 255),
			LayoutOrder = 3,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, (function()
			local children = {
				Layout = React.createElement("UIGridLayout", {
					CellSize = UDim2.new(0, 128, 0, 150),
					CellPadding = UDim2.new(0, 8, 0, 8),
				}),
				Padding = React.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 5),
				}),
			}
			for k, v in pairs(skillCards) do
				children[k] = v
			end
			return children
		end)())
	})
end

return SkillInventory
