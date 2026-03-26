local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local Window = require(script.Parent.Window)
local Button = require(script.Parent.Button)

type ShopUpgradeProps = {
	Visible: boolean,
	OnClose: () -> (),
	Data: any, -- PlayerData
}

local function getCost(cfg: any, level: number): number
	return math.floor(cfg.BaseCost * (cfg.CostScaling ^ level))
end

local function UpgradeCard(props: { Config: any, Level: number, VocalPoints: number })
	local cfg = props.Config
	local level = props.Level
	local cost = getCost(cfg, level)
	local canAfford = props.VocalPoints >= cost
	local isMaxed = level >= cfg.MaxLevel
	
	local progress = math.clamp(level / cfg.MaxLevel, 0, 1)

	local iconEmoji = "⚡"
	if cfg.Category == "Attack" then iconEmoji = "⚔️"
	elseif cfg.Category == "Defense" then iconEmoji = "🛡️"
	end

	return React.createElement("Frame", {
		Size = UDim2.new(1, -10, 0, 100),
		BackgroundColor3 = Config.Theme.SecondaryBackground,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Stroke = React.createElement("UIStroke", {
			Color = Config.Theme.StrokeColor,
			Thickness = 2,
			Transparency = 0.5,
		}),

		IconContainer = React.createElement("Frame", {
			Size = UDim2.new(0, 80, 0, 80),
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
		}, {
			Image = React.createElement("ImageLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Image = cfg.Icon or "",
				BackgroundTransparency = 1,
				ZIndex = 2,
			}),
			Fallback = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Text = iconEmoji,
				TextSize = 40,
				BackgroundTransparency = 1,
				ZIndex = 1,
				TextTransparency = 0.5,
			})
		}),

		Info = React.createElement("Frame", {
			Size = UDim2.new(1, -210, 1, -20),
			Position = UDim2.new(0, 100, 0, 10),
			BackgroundTransparency = 1,
		}, {
			Name = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 24),
				Text = cfg.DisplayName or "Upgrade",
				TextColor3 = Config.Theme.TextMain,
				Font = Enum.Font.GothamBold,
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
			}),
			Level = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				Position = UDim2.new(0, 0, 0, 24),
				Text = string.format("Level: %d / %d", level, cfg.MaxLevel),
				TextColor3 = Config.Theme.TextSecondary,
				Font = Enum.Font.Gotham,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
			}),
			Cost = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				Position = UDim2.new(0, 0, 0, 42),
				Text = if isMaxed then "MAX LEVEL" else string.format("Cost: %s VP", tostring(cost)),
				TextColor3 = if isMaxed then Config.Theme.TextMuted else (if canAfford then Config.Theme.TextGold else Color3.fromRGB(220, 100, 100)),
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
			}),
			
			ProgressBar = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 8),
				Position = UDim2.new(0, 0, 1, -8),
				BackgroundColor3 = Color3.fromRGB(40, 40, 60),
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Fill = React.createElement("Frame", {
					Size = UDim2.new(progress, 0, 1, 0),
					BackgroundColor3 = if cfg.Category == "Attack" then Color3.fromRGB(255, 150, 50) else Color3.fromRGB(50, 200, 255),
					BorderSizePixel = 0,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
				})
			})
		}),

		BuyButton = React.createElement(Button, {
			Text = if isMaxed then "MAX" else "UPGRADE",
			Size = UDim2.new(0, 100, 0, 36),
			Position = UDim2.new(1, -110, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Enabled = not isMaxed and canAfford,
			Variant = if isMaxed then "Cancel" else "Primary",
			OnClick = function()
				Remotes.Events.PurchaseUpgrade:FireServer(cfg.Id)
			end,
		})
	})
end

local function PremiumCard(props: { Config: any })
	local cfg = props.Config

	local iconEmoji = "💎"
	if cfg.Name:match("Gold") then iconEmoji = "💰"
	elseif cfg.Name:match("Stats") or cfg.Name:match("VIP") then iconEmoji = "👑"
	elseif cfg.Name:match("Auto") then iconEmoji = "⚙️"
	end

	return React.createElement("Frame", {
		Size = UDim2.new(1, -10, 0, 100),
		BackgroundColor3 = Color3.fromRGB(45, 40, 60),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Stroke = React.createElement("UIStroke", {
			Color = Color3.fromRGB(130, 100, 200),
			Thickness = 2,
			Transparency = 0.5,
		}),

		IconContainer = React.createElement("Frame", {
			Size = UDim2.new(0, 80, 0, 80),
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
		}, {
			Image = React.createElement("ImageLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Image = cfg.Icon or "",
				BackgroundTransparency = 1,
				ZIndex = 2,
			}),
			Fallback = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Text = iconEmoji,
				TextSize = 40,
				BackgroundTransparency = 1,
				ZIndex = 1,
				TextTransparency = 0.5,
			})
		}),

		Info = React.createElement("Frame", {
			Size = UDim2.new(1, -210, 1, -20),
			Position = UDim2.new(0, 100, 0, 10),
			BackgroundTransparency = 1,
		}, {
			Name = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 24),
				Text = cfg.Name or "Premium",
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamBold,
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
			}),
			TypeLabel = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				Position = UDim2.new(0, 0, 0, 24),
				Text = cfg.Type or "Gamepass",
				TextColor3 = Color3.fromRGB(200, 180, 255),
				Font = Enum.Font.Gotham,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
			}),
		}),

		BuyButton = React.createElement(Button, {
			Text = "R$ " .. (cfg.Price or "?"),
			Size = UDim2.new(0, 100, 0, 36),
			Position = UDim2.new(1, -110, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Variant = "Success",
			OnClick = function()
				local MarketplaceService = game:GetService("MarketplaceService")
				if cfg.Type == "Gamepass" then
					MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, cfg.Id)
				else
					MarketplaceService:PromptProductPurchase(game.Players.LocalPlayer, cfg.Id)
				end
			end,
		})
	})
end

local function ShopUpgrade(props: ShopUpgradeProps)
	local tab, setTab = React.useState("Attack")
	local data = props.Data or {}

	local content = {}
	if tab == "Premium" then
		local idx = 0
		for _, cfg in ipairs(Config.MonetizationProducts.Gamepasses) do
			idx += 1
			content["Pass_" .. idx] = React.createElement(PremiumCard, { Config = cfg })
		end
		for _, cfg in ipairs(Config.MonetizationProducts.DevProducts) do
			idx += 1
			content["Product_" .. idx] = React.createElement(PremiumCard, { Config = cfg })
		end
	else
		local idx = 0
		for _, cfg in ipairs(Config.Upgrades) do
			if cfg.Category == tab then
				idx += 1
				local level = 0
				if cfg.Id == "damage_1" then level = data.DamageUpgradeLevel or 0
				elseif cfg.Id == "health_1" then level = data.HealthUpgradeLevel or 0
				elseif cfg.Id == "armor_1" then level = data.ArmorUpgradeLevel or 0
				end

				content[cfg.Id] = React.createElement(UpgradeCard, {
					Config = cfg,
					Level = level,
					VocalPoints = data.VocalPoints or 0,
				})
			end
		end
	end

	return React.createElement(Window, {
		Title = "UPGRADE SHOP",
		Icon = "🛒",
		Visible = props.Visible,
		OnClose = props.OnClose,
		Size = UDim2.new(0, 560, 0, 600),
	}, {
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),

		Tabs = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			AttackTab = React.createElement(Button, {
				Text = "ATTACK",
				Size = UDim2.new(0, 120, 1, 0),
				Variant = if tab == "Attack" then "Shop" else "Cancel",
				OnClick = function() setTab("Attack") end,
			}),
			DefenseTab = React.createElement(Button, {
				Text = "DEFENSE",
				Size = UDim2.new(0, 120, 1, 0),
				Variant = if tab == "Defense" then "Shop" else "Cancel",
				OnClick = function() setTab("Defense") end,
			}),
			PremiumTab = React.createElement(Button, {
				Text = "PREMIUM",
				Size = UDim2.new(0, 120, 1, 0),
				Variant = if tab == "Premium" then "Shop" else "Cancel",
				OnClick = function() setTab("Premium") end,
			}),
		}),

		Scroll = React.createElement("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -50),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Config.Theme.BtnShopBase,
			LayoutOrder = 2,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, (function()
			local children = {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 10),
				}),
				Padding = React.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
				}),
			}
			for k, v in pairs(content) do
				children[k] = v
			end
			return children
		end)())
	})
end

return ShopUpgrade
