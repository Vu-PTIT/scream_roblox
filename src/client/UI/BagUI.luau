--!strict
-- BagUI.luau
-- Redesigned React-based Character/Inventory window.
-- Tabs: Stats, Pets, Skills, Effects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local Window = require(script.Parent.components.Window)
local ModernButton = require(script.Parent.components.ModernButton)

type TabType = "Stats" | "Pets" | "Skills" | "Effects"

-- [COMPONENT] THẺ PET TRONG TÚI
local function BagPetCard(props: { Pet: any, IsEquipped: boolean })
	local pet = props.Pet
	local petCfg = nil
	local targetType = (pet.PetType or ""):lower():gsub("%s+", "")
	for _, p in ipairs(Config.Pets) do
		if p.PetType:lower():gsub("%s+", "") == targetType then petCfg = p; break end
	end

	local rarityColor = if petCfg then Config.Theme.RarityColors[petCfg.Rarity] else Color3.new(1, 1, 1)

	return React.createElement("Frame", {
		Size = UDim2.new(0, 115, 0, 145),
		BackgroundColor3 = Color3.fromRGB(35, 38, 55),
		BackgroundTransparency = 0.1,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Stroke = React.createElement("UIStroke", {
			Color = if props.IsEquipped then Color3.fromRGB(0, 255, 120) else rarityColor,
			Thickness = if props.IsEquipped then 2.5 else 1.5,
			Transparency = 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),

		Icon = React.createElement("ImageLabel", {
			Size = UDim2.new(0, 68, 0, 68),
			Position = UDim2.new(0.5, 0, 0, 8),
			AnchorPoint = Vector2.new(0.5, 0),
			Image = if petCfg and petCfg.Icon then "rbxthumb://type=Asset&id=" .. (petCfg.Icon:match("%d+") or "0") .. "&w=150&h=150" else "rbxassetid://1065507455",
			BackgroundTransparency = 1,
			ZIndex = 2,
		}),

		NameLabel = React.createElement("TextLabel", {
			Size = UDim2.new(1, -10, 0, 18),
			Position = UDim2.new(0, 5, 0, 80),
			Text = if petCfg then petCfg.DisplayName else pet.PetType,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextScaled = true,
			BackgroundTransparency = 1,
		}),

		MultLabel = React.createElement("TextLabel", {
			Size = UDim2.new(1, -10, 0, 14),
			Position = UDim2.new(0, 5, 0, 96),
			Text = "x" .. string.format("%.2f", pet.Multiplier or (petCfg and petCfg.Multiplier) or 1),
			TextColor3 = Color3.fromRGB(180, 185, 210),
			Font = Enum.Font.Gotham,
			TextSize = 10,
			BackgroundTransparency = 1,
		}),

		EquipBtn = React.createElement("Frame", {
			Size = UDim2.new(1, -10, 0, 26),
			Position = UDim2.new(0, 5, 1, -32),
			BackgroundTransparency = 1,
		}, if props.IsEquipped then {
			Unequip = React.createElement(ModernButton, {
				Text = "UNEQUIP",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor = Color3.fromRGB(0, 180, 100),
				OnClick = function() Remotes.Events.SetPetEquipped:FireServer(pet.Id, false) end,
			})
		} else {
			Layout = React.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }),
			Equip = React.createElement(ModernButton, {
				Text = "EQUIP",
				Size = UDim2.new(0.66, -2, 1, 0),
				BackgroundColor = Color3.fromRGB(65, 70, 95),
				OnClick = function() Remotes.Events.SetPetEquipped:FireServer(pet.Id, true) end,
			}),
			Sell = React.createElement(ModernButton, {
				Text = "💰",
				Size = UDim2.new(0.34, -2, 1, 0),
				BackgroundColor = Color3.fromRGB(220, 100, 100),
				OnClick = function() Remotes.Events.SellPet:FireServer(pet.Id) end,
			}),
		})
	})
end

-- [COMPONENT] THẺ SKILL TRONG TÚI
local function BagSkillCard(props: { Skill: any, EquippedSlot: number? })
	local skill = props.Skill
	local skillCfg = nil
	local targetType = (skill.SkillType or ""):lower():gsub("%s+", "")
	for _, s in ipairs(Config.Skills) do
		if s.SkillType:lower():gsub("%s+", "") == targetType then skillCfg = s; break end
	end

	local rarityColor = if skillCfg and skillCfg.Rarity then Config.Theme.RarityColors[skillCfg.Rarity] else Color3.new(1, 1, 1)

	return React.createElement("Frame", {
		Size = UDim2.new(0, 115, 0, 175),
		BackgroundColor3 = Color3.fromRGB(35, 38, 55),
		BackgroundTransparency = 0.1,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Stroke = React.createElement("UIStroke", {
			Color = if props.EquippedSlot then Color3.fromRGB(180, 100, 255) else rarityColor,
			Thickness = if props.EquippedSlot then 2.5 else 1.5,
			Transparency = 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),

		IconLabel = React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 70),
			Position = UDim2.new(0, 0, 0, 5),
			Text = if skillCfg then skillCfg.Icon else "📜",
			TextSize = 42,
			BackgroundTransparency = 1,
		}),

		NameLabel = React.createElement("TextLabel", {
			Size = UDim2.new(1, -10, 0, 18),
			Position = UDim2.new(0, 5, 0, 80),
			Text = if skillCfg then skillCfg.DisplayName else skill.SkillType,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextScaled = true,
			BackgroundTransparency = 1,
		}),

		Btns = React.createElement("Frame", {
			Size = UDim2.new(1, -10, 0, 58),
			Position = UDim2.new(0, 5, 1, -64),
			BackgroundTransparency = 1,
		}, if props.EquippedSlot then {
			Unequip = React.createElement(ModernButton, {
				Text = "UNEQUIP",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor = Color3.fromRGB(180, 50, 70),
				OnClick = function() Remotes.Events.SetSkillEquipped:FireServer(skill.Id, false) end,
			})
		} else {
			Layout = React.createElement("UIGridLayout", {
				CellSize = UDim2.new(0, 31, 0, 26),
				CellPadding = UDim2.new(0, 6, 0, 6),
			}),
			S1 = React.createElement(ModernButton, { Text = "S1", BackgroundColor = Color3.fromRGB(100, 150, 255), OnClick = function() Remotes.Events.SetSkillEquipped:FireServer(skill.Id, true, 1) end }),
			S2 = React.createElement(ModernButton, { Text = "S2", BackgroundColor = Color3.fromRGB(100, 150, 255), OnClick = function() Remotes.Events.SetSkillEquipped:FireServer(skill.Id, true, 2) end }),
			S3 = React.createElement(ModernButton, { Text = "S3", BackgroundColor = Color3.fromRGB(100, 150, 255), OnClick = function() Remotes.Events.SetSkillEquipped:FireServer(skill.Id, true, 3) end }),
			S4 = React.createElement(ModernButton, { Text = "S4", BackgroundColor = Color3.fromRGB(100, 150, 255), OnClick = function() Remotes.Events.SetSkillEquipped:FireServer(skill.Id, true, 4) end }),
			S5 = React.createElement(ModernButton, { Text = "S5", BackgroundColor = Color3.fromRGB(100, 150, 255), OnClick = function() Remotes.Events.SetSkillEquipped:FireServer(skill.Id, true, 5) end }),
			Sell = React.createElement(ModernButton, { Text = "💰", BackgroundColor = Color3.fromRGB(220, 100, 100), OnClick = function() Remotes.Events.SellSkill:FireServer(skill.Id) end }),
		}),
	})
end

local function BagUI(props: { Visible: boolean, OnClose: () -> (), Data: any })
	local activeTab, setActiveTab = React.useState("Stats" :: TabType)

	if not props.Visible then return nil end
	local data = props.Data or {}

	-- Helper: Render Tab Button
	local function TabBtn(name: string, icon: string, tab: TabType)
		local isActive = activeTab == tab
		return React.createElement(ModernButton, {
			Text = if name == "STATS" then name else "", 
			Icon = icon,
			Size = UDim2.new(0, 85, 0, 42),
			BackgroundColor = isActive and Color3.fromRGB(80, 120, 255) or Color3.fromRGB(40, 42, 60),
			OnClick = function() setActiveTab(tab) end,
		})
	end

	-- Current View Renderers
	local views = {
		Stats = function()
			local dmgCfg = Config.GetUpgrade("damage_1")
			local armCfg = Config.GetUpgrade("armor_1")
			local totalAtk = (data.Attack or 10) + (data.DamageUpgradeLevel or 0) * (dmgCfg and dmgCfg.StatPerLevel or 5)
			local totalDef = (data.Defense or 10) + (data.ArmorUpgradeLevel or 0) * (armCfg and armCfg.StatPerLevel or 10)

			local statList = {
				{ Label = "Attack Power", Value = tostring(math.floor(totalAtk)), Icon = "⚔️", Color = Color3.fromRGB(255, 100, 100) },
				{ Label = "Defense", Value = tostring(math.floor(totalDef)), Icon = "🛡️", Color = Color3.fromRGB(100, 255, 100) },
				{ Label = "Max Health", Value = tostring(math.floor(data.MaxHealth or 100)), Icon = "❤️", Color = Color3.fromRGB(255, 150, 150) },
				{ Label = "Rebirth Mod", Value = "x" .. string.format("%.2f", data.RebirthMultiplier or 1), Icon = "📈", Color = Color3.fromRGB(255, 200, 50) },
				{ Label = "Vocal Points", Value = string.format("%d", data.VocalPoints or 0), Icon = "🎙️", Color = Color3.fromRGB(100, 200, 255) },
				{ Label = "Rebirths", Value = tostring(data.RebirthCount or 0), Icon = "⭐", Color = Color3.new(1, 1, 1) },
			}

			return React.createElement("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, {
				Grid = React.createElement("UIGridLayout", { CellSize = UDim2.new(0.5, -10, 0, 75), CellPadding = UDim2.new(0, 20, 0, 20) }),
				Items = React.createElement(React.Fragment, nil, (function()
					local items = {}
					for i, stat in ipairs(statList) do
						items[stat.Label] = React.createElement("Frame", { BackgroundColor3 = Color3.fromRGB(30,32,45), BackgroundTransparency = 0.3 }, {
							Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
							Icon = React.createElement("TextLabel", { Text = stat.Icon, Size = UDim2.new(0,40,1,0), Position = UDim2.new(0,15,0,0), BackgroundTransparency = 1, TextSize = 24 }),
							Val = React.createElement("TextLabel", { Text = stat.Value, Position = UDim2.new(0,60,0,15), Size = UDim2.new(1,-70,0,30), TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 18, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left }),
							Lbl = React.createElement("TextLabel", { Text = stat.Label:upper(), Position = UDim2.new(0,60,0,42), Size = UDim2.new(1,-70,0,20), TextColor3 = Color3.fromRGB(180,185,210), Font = Enum.Font.GothamBold, TextSize = 10, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
						})
					end
					return items
				end)())
			})
		end,

		Pets = function()
			local pets = data.Pets or {}
			local equippedIds = data.EquippedPetIds or {}
			local petElements = {}
			for _, pet in ipairs(pets) do
				local isEq = false
				for _, eid in ipairs(equippedIds) do if eid == pet.Id then isEq = true; break end end
				petElements[pet.Id] = React.createElement(BagPetCard, { Pet = pet, IsEquipped = isEq })
			end
			return React.createElement("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 2 }, {
				Padding = React.createElement("UIPadding", { PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
				Grid = React.createElement("UIGridLayout", { CellSize = UDim2.new(0, 115, 0, 145), CellPadding = UDim2.new(0, 12, 0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Left }),
				Items = React.createElement(React.Fragment, nil, petElements)
			})
		end,
		
		Skills = function()
			local skills = data.Skills or {}
			local equippedIds = data.EquippedSkillIds or {}
			local skillElements = {}
			for _, skill in ipairs(skills) do
				local slot = nil
				for i=1, 5 do
					if equippedIds[i] == skill.Id or equippedIds[tostring(i)] == skill.Id then slot = i; break end
				end
				skillElements[skill.Id] = React.createElement(BagSkillCard, { Skill = skill, EquippedSlot = slot })
			end
			return React.createElement("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 2 }, {
				Padding = React.createElement("UIPadding", { PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
				Grid = React.createElement("UIGridLayout", { CellSize = UDim2.new(0, 115, 0, 175), CellPadding = UDim2.new(0, 12, 0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Left }),
				Items = React.createElement(React.Fragment, nil, skillElements)
			})
		end,
		
		Effects = function()
			local owned = data.OwnedMovementEffects or { "Default" }
			local currentDash = data.EquippedDashEffect or "Default"
			local currentJump = data.EquippedJumpEffect or "Default"
			
			local effectElements = {}
			for _, effectId in ipairs(owned) do
				local cfg = Config.GetMovementEffect(effectId)
				if cfg then
					effectElements[effectId] = React.createElement("Frame", { BackgroundColor3 = Color3.fromRGB(40, 42, 60), BackgroundTransparency = 0.2 }, {
						Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
						Title = React.createElement("TextLabel", { Size = UDim2.new(1, -250, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = (cfg.Icon or "⚡") .. " " .. cfg.DisplayName, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left }),
						Btns = React.createElement("Frame", { Size = UDim2.new(0, 230, 0, 36), Position = UDim2.new(1, -240, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1 }, {
							Layout = React.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
							Dash = React.createElement(ModernButton, { Text = if currentDash == effectId then "DASH [X]" else "DASH", Size = UDim2.new(0, 110, 1, 0), BackgroundColor = if currentDash == effectId then Color3.fromRGB(255, 100, 50) else Color3.fromRGB(60, 65, 90), OnClick = function() Remotes.Events.SetMovementEffect:FireServer(effectId, "Dash") end }),
							Jump = React.createElement(ModernButton, { Text = if currentJump == effectId then "JUMP [X]" else "JUMP", Size = UDim2.new(0, 110, 1, 0), BackgroundColor = if currentJump == effectId then Color3.fromRGB(80, 200, 50) else Color3.fromRGB(60, 65, 90), OnClick = function() Remotes.Events.SetMovementEffect:FireServer(effectId, "Jump") end }),
						})
					})
				end
			end
			
			return React.createElement("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 2 }, {
				Padding = React.createElement("UIPadding", { PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
				Grid = React.createElement("UIGridLayout", { CellSize = UDim2.new(1, 0, 0, 80), CellPadding = UDim2.new(0, 10, 0, 10) }),
				Items = React.createElement(React.Fragment, nil, effectElements)
			})
		end
	}

	return React.createElement("ScreenGui", { Name = "BagUI", DisplayOrder = 500, Enabled = props.Visible, IgnoreGuiInset = true }, {
		Window = React.createElement(Window, {
			Title = "GOKU INVENTORY",
			Icon = "🎒",
			Visible = props.Visible,
			OnClose = props.OnClose,
			Size = UDim2.new(0, 560, 0, 500),
		}, {
			Tabs = React.createElement("Frame", { Size = UDim2.new(1, 0, 0, 55), BackgroundTransparency = 1 }, {
				Layout = React.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 15), VerticalAlignment = Enum.VerticalAlignment.Center }),
				T1 = TabBtn("STATS", "📊", "Stats"),
				T2 = TabBtn("", "🐾", "Pets"),
				T3 = TabBtn("", "🔥", "Skills"),
				T4 = TabBtn("", "⚡", "Effects"),
			}),
			Content = React.createElement("Frame", { Size = UDim2.new(1, 0, 1, -65), Position = UDim2.new(0, 0, 0, 65), BackgroundTransparency = 1 }, {
				View = (views[activeTab] or function() return nil end)()
			})
		})
	})
end

return BagUI
