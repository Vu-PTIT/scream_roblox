--!strict
-- ShopUpgrade.luau
-- Complete Shop UI: Upgrades (Atk/Def), Effects (Dash/Jump), and Premium.
-- Optimized for React-Luau to prevent 'createTextInstance' crashes.

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

-- ============================================================
-- HELPERS
-- ============================================================
local function getCost(cfg: any, level: number): number
	return math.floor(cfg.BaseCost * (cfg.CostScaling ^ level))
end

local CATEGORY_COLORS = {
	Attack  = Color3.fromRGB(255, 140, 50),
	Defense = Color3.fromRGB(50, 200, 255),
}

local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 185, 210),
	Rare      = Color3.fromRGB(90, 190, 255),
	Epic      = Color3.fromRGB(210, 120, 255),
	Legendary = Color3.fromRGB(255, 215, 80),
}

-- ============================================================
-- COMPONENT: UPGRADE CARD
-- ============================================================
local function UpgradeCard(props: { Config: any, Level: number, VocalPoints: number })
	local cfg = props.Config
	local level = props.Level
	local cost = getCost(cfg, level)
	local canAfford = props.VocalPoints >= cost
	local isMaxed = level >= cfg.MaxLevel
	local progress = math.clamp(level / cfg.MaxLevel, 0, 1)

	local isAtk = cfg.Category == "Attack"
	local accentColor = CATEGORY_COLORS[cfg.Category] or Color3.fromRGB(100, 180, 255)
	local iconEmoji = if isAtk then "⚔️" else (if cfg.Id == "health_1" then "❤️" else "🛡️")
	local fillColor = if isAtk then Color3.fromRGB(255, 150, 50) else (if cfg.Id == "armor_1" then Color3.fromRGB(50, 200, 255) else Color3.fromRGB(80, 240, 140))

	return React.createElement("Frame", {
		Size = UDim2.new(1, -10, 0, 106),
		BackgroundColor3 = Config.Theme.SecondaryBackground,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Stroke = React.createElement("UIStroke", {
			Color = accentColor, Thickness = 1.5, Transparency = 0.55,
		}),

		Badge = React.createElement("Frame", {
			Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(0, 100, 0, 10), BackgroundColor3 = accentColor, BackgroundTransparency = 0.3,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Pad = React.createElement("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
			Label = React.createElement("TextLabel", {
				Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1, Text = if isAtk then "⚔ ATK" else "🛡 DEF",
				Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.new(1, 1, 1),
			}),
		}),

		Icon = React.createElement("Frame", {
			Size = UDim2.new(0, 80, 0, 80), Position = UDim2.new(0, 10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = accentColor:Lerp(Color3.fromRGB(20, 22, 35), 0.8),
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
			Img = React.createElement("ImageLabel", { Size = UDim2.new(1, 0, 1, 0), Image = cfg.Icon or "", BackgroundTransparency = 1, ZIndex = 2 }),
			Txt = React.createElement("TextLabel", { Size = UDim2.new(1, 0, 1, 0), Text = iconEmoji, TextSize = 36, BackgroundTransparency = 1, ZIndex = 1 }),
		}),

		Info = React.createElement("Frame", {
			Size = UDim2.new(1, -215, 1, -16), Position = UDim2.new(0, 100, 0, 34), BackgroundTransparency = 1,
		}, {
			Name = React.createElement("TextLabel", { Size = UDim2.new(1, 0, 0, 22), Text = cfg.DisplayName or "Upgrade", TextColor3 = Config.Theme.TextMain, Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1 }),
			Lvl = React.createElement("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 22), Text = "Level " .. level .. " / " .. cfg.MaxLevel, TextColor3 = Config.Theme.TextSecondary, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1 }),
			Cst = React.createElement("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 38), Text = if isMaxed then "✅ MAX" else "🎙️ " .. cost .. " VP", TextColor3 = if isMaxed then Config.Theme.TextMuted else (if canAfford then Config.Theme.TextGold else Color3.fromRGB(220, 100, 100)), Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1 }),
			BarBg = React.createElement("Frame", { Size = UDim2.new(1, 0, 0, 7), Position = UDim2.new(0, 0, 1, -8), BackgroundColor3 = Color3.fromRGB(30, 32, 48), BorderSizePixel = 0 }, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Fill = React.createElement("Frame", { Size = UDim2.new(progress, 0, 1, 0), BackgroundColor3 = fillColor, BorderSizePixel = 0 }, { Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
			}),
		}),

		Buy = React.createElement(Button, {
			Text = if isMaxed then "MAX" else "UPGRADE", Size = UDim2.new(0, 100, 0, 36), Position = UDim2.new(1, -112, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5), Enabled = not isMaxed and canAfford, Variant = if isMaxed then "Cancel" else "Primary",
			OnClick = function() Remotes.Events.PurchaseUpgrade:FireServer(cfg.Id) end,
		}),
	})
end

-- ============================================================
-- COMPONENT: EFFECT CARD
-- ============================================================
local function EffectCard(props: { Effect: any, IsOwned: boolean, EquippedDash: string, EquippedJump: string, ActiveTab: string, Gold: number })
	local eff = props.Effect
	local rarityColor = RARITY_COLORS[eff.Rarity] or Color3.fromRGB(200, 200, 200)
	local isDash = props.ActiveTab == "Dash"
	local tabColor = if isDash then Color3.fromRGB(80, 180, 255) else Color3.fromRGB(255, 180, 60)
	local isEquipped = (isDash and props.EquippedDash == eff.Id) or (not isDash and props.EquippedJump == eff.Id)
	local canAfford = props.Gold >= (eff.Cost or 0)

	return React.createElement("Frame", {
		Size = UDim2.new(1, -10, 0, 100),
		BackgroundColor3 = if isEquipped then tabColor:Lerp(Config.Theme.SecondaryBackground, 0.7) else Config.Theme.SecondaryBackground,
		BackgroundTransparency = 0.15,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Stroke = React.createElement("UIStroke", { Color = if isEquipped then tabColor else rarityColor, Thickness = if isEquipped then 2.5 else 1.5 }),

		Icon = React.createElement("Frame", { Size = UDim2.new(0, 80, 0, 80), Position = UDim2.new(0, 10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = rarityColor:Lerp(Color3.fromRGB(20, 22, 35), 0.75) }, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
			Txt = React.createElement("TextLabel", { Size = UDim2.new(1, 0, 1, 0), Text = eff.Icon or "💨", TextSize = 36, BackgroundTransparency = 1 }),
		}),

		Info = React.createElement("Frame", { Size = UDim2.new(1, -215, 1, -16), Position = UDim2.new(0, 100, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1 }, {
			Name = React.createElement("TextLabel", { Size = UDim2.new(1, 0, 0, 22), Text = eff.DisplayName or eff.Id, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1 }),
			Rarity = React.createElement("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 22), Text = "✦ " .. (eff.Rarity or "Common"), TextColor3 = rarityColor, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1 }),
		}),

		Btns = React.createElement("Frame", { Size = UDim2.new(0, 105, 1, -16), Position = UDim2.new(1, -112, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1 }, {
			Layout = React.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 5) }),
			Buy = if not props.IsOwned then React.createElement(Button, { Text = "💰 " .. (eff.Cost or 0), Size = UDim2.new(1, 0, 0, 32), Enabled = canAfford, Variant = "Success", OnClick = function() Remotes.Events.BuyMovementEffect:FireServer(eff.Id) end }) else nil,
			Equip = if props.IsOwned then React.createElement(Button, { Text = if isEquipped then "✅" else "EQUIP", Size = UDim2.new(1, 0, 0, 32), Enabled = not isEquipped, Variant = if isEquipped then "Cancel" else "Primary", OnClick = function() Remotes.Events.SetMovementEffect:FireServer(eff.Id, props.ActiveTab) end }) else nil,
		}),
	})
end

-- ============================================================
-- COMPONENT: PREMIUM CARD
-- ============================================================
local function PremiumCard(props: { Config: any })
	local cfg = props.Config
	local icon = if cfg.Name:match("Auto") then "⚙️" else (if cfg.Name:match("VIP") then "👑" else "💰")

	return React.createElement("Frame", {
		Size = UDim2.new(1, -10, 0, 100), BackgroundColor3 = Color3.fromRGB(45, 42, 65), BackgroundTransparency = 0.15,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Stroke = React.createElement("UIStroke", { Color = Color3.fromRGB(150, 120, 255), Thickness = 2 }),

		Icon = React.createElement("Frame", { Size = UDim2.new(0, 80, 0, 80), Position = UDim2.new(0, 10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Color3.fromRGB(30, 28, 45) }, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
			Img = React.createElement("ImageLabel", { Size = UDim2.new(1, 0, 1, 0), Image = cfg.Icon or "", BackgroundTransparency = 1, ZIndex = 2 }),
			Txt = React.createElement("TextLabel", { Size = UDim2.new(1, 0, 1, 0), Text = icon, TextSize = 40, BackgroundTransparency = 1, TextTransparency = 0.5 }),
		}),

		Info = React.createElement("Frame", { Size = UDim2.new(1, -215, 1, -16), Position = UDim2.new(0, 100, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1 }, {
			Name = React.createElement("TextLabel", { Size = UDim2.new(1, 0, 0, 24), Text = cfg.Name or "Premium", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1 }),
			Type = React.createElement("TextLabel", { Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 24), Text = cfg.Type or "Gamepass", TextColor3 = Color3.fromRGB(200, 180, 255), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1 }),
		}),

		Buy = React.createElement(Button, {
			Text = "R$ " .. (cfg.Price or "?"), Size = UDim2.new(0, 105, 0, 36), Position = UDim2.new(1, -112, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Variant = "Success",
			OnClick = function()
				local MS = game:GetService("MarketplaceService")
				if cfg.Type == "Gamepass" then MS:PromptGamePassPurchase(game.Players.LocalPlayer, cfg.Id) else MS:PromptProductPurchase(game.Players.LocalPlayer, cfg.Id) end
			end,
		}),
	})
end

-- ============================================================
-- MAIN COMPONENT: SHOP UPGRADE
-- ============================================================
local function ShopUpgrade(props: ShopUpgradeProps)
	local tab, setTab = React.useState("Upgrades")
	local data = props.Data or {}
	local owned: { [string]: boolean } = { Default = true }
	for _, id in ipairs(data.OwnedMovementEffects or {}) do owned[id] = true end

	local scrollContent: { [string]: any } = {}

	if tab == "Upgrades" then
		for _, cfg in ipairs(Config.Upgrades) do
			local level = if cfg.Id == "damage_1" then data.DamageUpgradeLevel or 0 elseif cfg.Id == "health_1" then data.HealthUpgradeLevel or 0 elseif cfg.Id == "armor_1" then data.ArmorUpgradeLevel or 0 else 0
			scrollContent["Upg_" .. cfg.Id] = React.createElement(UpgradeCard, { Config = cfg, Level = level, VocalPoints = data.VocalPoints or 0 })
		end
	elseif tab == "Effects_Dash" or tab == "Effects_Jump" then
		local activeMove = if tab == "Effects_Dash" then "Dash" else "Jump"
		for _, eff in ipairs(Config.MovementEffects) do
			scrollContent["Eff_" .. eff.Id] = React.createElement(EffectCard, { Effect = eff, IsOwned = owned[eff.Id] == true, EquippedDash = data.EquippedDashEffect or "Default", EquippedJump = data.EquippedJumpEffect or "Default", ActiveTab = activeMove, Gold = data.Gold or 0 })
		end
	elseif tab == "Premium" then
		local idx = 0
		for _, cfg in ipairs(Config.MonetizationProducts.Gamepasses) do idx += 1; scrollContent["Pass_" .. idx] = React.createElement(PremiumCard, { Config = cfg }) end
		for _, cfg in ipairs(Config.MonetizationProducts.DevProducts) do idx += 1; scrollContent["Prod_" .. idx] = React.createElement(PremiumCard, { Config = cfg }) end
	end

	-- Build tab bar safely
	local TAB_DEFS = { { id = "Upgrades", label = "⚔️ UPGRADES", color = Color3.fromRGB(255, 140, 50) }, { id = "Effects_Dash", label = "🏃 DASH", color = Color3.fromRGB(80, 180, 255) }, { id = "Effects_Jump", label = "🦘 JUMP", color = Color3.fromRGB(255, 180, 60) }, { id = "Premium", label = "⭐ PREMIUM", color = Color3.fromRGB(180, 100, 255) } }
	local tabElements = { Layout = React.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }) }
	for i, td in ipairs(TAB_DEFS) do
		local isActive = tab == td.id
		tabElements["Tab_" .. td.id] = React.createElement("TextButton", { Size = UDim2.new(0, 110, 1, 0), BackgroundColor3 = if isActive then td.color else Color3.fromRGB(30,33,50), BackgroundTransparency = if isActive then 0 else 0.2, Text = td.label, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = if isActive then Color3.new(1,1,1) else Color3.fromRGB(140,145,170), BorderSizePixel = 0, LayoutOrder = i, [React.Event.Activated] = function() setTab(td.id) end }, { React.createElement("UICorner", { CornerRadius = UDim.new(0, 9) }) })
	end

	return React.createElement(Window, { Title = "SHOP", Icon = "🛒", Visible = props.Visible, OnClose = props.OnClose, Size = UDim2.new(0, 580, 0, 620) }, {
		List = React.createElement("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
		Tabs = React.createElement("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, LayoutOrder = 1 }, tabElements),
		Scroll = React.createElement("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1, LayoutOrder = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0) }, (function()
			local children = { Layout = React.createElement("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }), Padding = React.createElement("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }) }
			for k, v in pairs(scrollContent) do children[k] = v end
			return children
		end)())
	})
end

return ShopUpgrade
