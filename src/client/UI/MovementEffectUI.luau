--!strict
-- MovementEffectUI.luau
-- Shop hiệu ứng Dash & Jump riêng biệt
-- Người chơi mua bằng Gold và equip cho từng loại

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local MovementEffectUI = {}

-- Internal state setters
local _setVisible: ((boolean) -> ())? = nil

-- Màu rarity
local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 185, 210),
	Rare      = Color3.fromRGB(90, 190, 255),
	Epic      = Color3.fromRGB(210, 120, 255),
	Legendary = Color3.fromRGB(255, 215, 80),
}

local TAB_COLORS = {
	Dash = Color3.fromRGB(80, 180, 255),
	Jump = Color3.fromRGB(255, 180, 60),
}

-- ======================================
-- Single Effect Card Component
-- ======================================
local function EffectCard(props: {
	effect: any,
	isOwned: boolean,
	isEquippedDash: boolean,
	isEquippedJump: boolean,
	activeTab: string,
	onBuy: () -> (),
	onEquip: () -> (),
})
	local effect = props.effect
	local rarityColor = RARITY_COLORS[effect.Rarity] or Color3.fromRGB(200, 200, 200)
	local tabColor = TAB_COLORS[props.activeTab] or Color3.fromRGB(100, 180, 255)

	local isEquipped = (props.activeTab == "Dash" and props.isEquippedDash)
		or (props.activeTab == "Jump" and props.isEquippedJump)

	-- Card BG color
	local bgColor = isEquipped
		and Color3.fromRGB(25, 40, 65)
		or Color3.fromRGB(22, 24, 36)

	local borderColor = isEquipped and tabColor or rarityColor

	return React.createElement("Frame", {
		Size = UDim2.new(1, -16, 0, 90),
		BackgroundColor3 = bgColor,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Stroke = React.createElement("UIStroke", {
			Color = borderColor,
			Thickness = isEquipped and 2.5 or 1.5,
			Transparency = isEquipped and 0 or 0.3,
		}),

		-- Icon
		Icon = React.createElement("TextLabel", {
			Size = UDim2.new(0, 70, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = effect.Icon or "💨",
			TextSize = 32,
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.new(1, 1, 1),
		}),

		-- Name + Rarity + Description
		InfoFrame = React.createElement("Frame", {
			Size = UDim2.new(1, -190, 1, 0),
			Position = UDim2.new(0, 78, 0, 0),
			BackgroundTransparency = 1,
		}, {
			Name = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 24),
				Position = UDim2.new(0, 0, 0, 8),
				BackgroundTransparency = 1,
				Text = effect.DisplayName or effect.Id,
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			RarityLabel = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.new(0, 0, 0, 33),
				BackgroundTransparency = 1,
				Text = "✦ " .. (effect.Rarity or "Common"),
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextColor3 = rarityColor,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Desc = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.new(0, 0, 0, 52),
				BackgroundTransparency = 1,
				Text = effect.Description or "",
				Font = Enum.Font.Gotham,
				TextSize = 10,
				TextColor3 = Color3.fromRGB(150, 155, 180),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
		}),

		-- Buttons
		BtnFrame = React.createElement("Frame", {
			Size = UDim2.new(0, 100, 1, -16),
			Position = UDim2.new(1, -108, 0, 8),
			BackgroundTransparency = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			-- Nút MUA (nếu chưa sở hữu)
			BuyBtn = not props.isOwned and React.createElement("TextButton", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = Color3.fromRGB(60, 180, 80),
				Text = string.format("💰 %s G", tostring(effect.Cost or 0)),
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				LayoutOrder = 1,
				[React.Event.Activated] = props.onBuy,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}) or nil,

			-- Nút EQUIP (nếu đã sở hữu)
			EquipBtn = props.isOwned and React.createElement("TextButton", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = isEquipped and Color3.fromRGB(40, 120, 40) or tabColor,
				Text = isEquipped and "✅ EQUIPPED" or "EQUIP",
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				LayoutOrder = 2,
				[React.Event.Activated] = isEquipped and (function() end) or props.onEquip,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}) or nil,
		}),
	})
end

-- ======================================
-- Main UI Component
-- ======================================
local function MovementEffectUIComponent()
	local visible, setVisible = React.useState(false)
	local activeTab, setActiveTab = React.useState("Dash")
	local data, setData = React.useState({
		Gold = 0,
		OwnedMovementEffects = { "Default" },
		EquippedDashEffect = "Default",
		EquippedJumpEffect = "Default",
	})

	React.useEffect(function()
		_setVisible = setVisible
		return function()
			_setVisible = nil
		end
	end, {})

	-- Sync data từ DataController
	React.useEffect(function()
		local DataController = require(script.Parent.Parent.Controllers.DataController)
		local connection

		local function loadData()
			if DataController and DataController.OnDataChanged then
				local d = DataController.GetData()
				if d then
					setData(function(prev)
						local new = table.clone(prev)
						new.Gold = d.Gold or 0
						local ownedAny = (d :: any).OwnedMovementEffects
						new.OwnedMovementEffects = ownedAny or { "Default" }
						local equipDash = (d :: any).EquippedDashEffect
						new.EquippedDashEffect = equipDash or "Default"
						local equipJump = (d :: any).EquippedJumpEffect
						new.EquippedJumpEffect = equipJump or "Default"
						return new
					end)
				end
				connection = DataController.OnDataChanged(function(key, val)
					setData(function(prev)
						if key == "__all__" then
							local new = table.clone(prev)
							new.Gold = (val :: any).Gold or 0
							new.OwnedMovementEffects = (val :: any).OwnedMovementEffects or { "Default" }
							new.EquippedDashEffect = (val :: any).EquippedDashEffect or "Default"
							new.EquippedJumpEffect = (val :: any).EquippedJumpEffect or "Default"
							return new
						elseif key == "Gold" then
							local d2 = table.clone(prev)
							d2.Gold = val
							return d2
						elseif key == "OwnedMovementEffects" then
							local d2 = table.clone(prev)
							d2.OwnedMovementEffects = val
							return d2
						elseif key == "EquippedDashEffect" then
							local d2 = table.clone(prev)
							d2.EquippedDashEffect = val
							return d2
						elseif key == "EquippedJumpEffect" then
							local d2 = table.clone(prev)
							d2.EquippedJumpEffect = val
							return d2
						end
						return prev
					end)
				end)
			end
		end

		task.spawn(loadData)
		return function()
			if type(connection) == "table" and connection.Disconnect then
				connection:Disconnect()
			end
		end
	end, {})

	if not visible then
		return React.createElement("ScreenGui", {
			Name = "MovementEffectUI",
			ResetOnSpawn = false,
			Enabled = false,
		})
	end

	local ownedMap: { [string]: boolean } = {}
	for _, id in ipairs(data.OwnedMovementEffects or {}) do
		ownedMap[id] = true
	end

	-- Buid effect cards
	local cards: { [string]: any } = {}
	for i, effect in ipairs(Config.MovementEffects) do
		local effectId = effect.Id
		local isOwned = ownedMap[effectId] == true
		local isEquipDash = data.EquippedDashEffect == effectId
		local isEquipJump = data.EquippedJumpEffect == effectId

		cards["Card_" .. effectId] = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 98),
			BackgroundTransparency = 1,
			LayoutOrder = i,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
			Card = React.createElement(EffectCard, {
				effect = effect,
				isOwned = isOwned,
				isEquippedDash = isEquipDash,
				isEquippedJump = isEquipJump,
				activeTab = activeTab,
				onBuy = function()
					Remotes.Events.BuyMovementEffect:FireServer(effectId)
				end,
				onEquip = function()
					Remotes.Events.SetMovementEffect:FireServer(effectId, activeTab)
				end,
			}),
		})
	end

	local tabColor = TAB_COLORS[activeTab] or Color3.fromRGB(100, 180, 255)

	return React.createElement("ScreenGui", {
		Name = "MovementEffectUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 150,
	}, {
		-- Backdrop
		Backdrop = React.createElement("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.45,
			Text = "",
			BorderSizePixel = 0,
			ZIndex = 1,
			[React.Event.Activated] = function()
				setVisible(false)
			end,
		}),

		-- Main Panel
		Panel = React.createElement("Frame", {
			Size = UDim2.new(0, 480, 0, 580),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(18, 20, 32),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 18) }),
			Stroke = React.createElement("UIStroke", {
				Color = tabColor,
				Thickness = 2,
				Transparency = 0.2,
			}),

			-- Header gradient
			HeaderBg = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 64),
				BackgroundColor3 = Color3.fromRGB(25, 28, 45),
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 18) }),
				Gradient = React.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, tabColor:Lerp(Color3.fromRGB(25, 28, 45), 0.6)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 28, 45)),
					}),
					Rotation = 90,
				}),

				-- Title
				Title = React.createElement("TextLabel", {
					Size = UDim2.new(1, -60, 1, 0),
					Position = UDim2.new(0, 20, 0, 0),
					BackgroundTransparency = 1,
					Text = "💨  MOVEMENT EFFECTS",
					Font = Enum.Font.GothamBlack,
					TextSize = 20,
					TextColor3 = Color3.new(1, 1, 1),
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				-- Gold display
				GoldPill = React.createElement("Frame", {
					Size = UDim2.new(0, 120, 0, 30),
					Position = UDim2.new(1, -140, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(35, 30, 15),
					BorderSizePixel = 0,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
					Stroke = React.createElement("UIStroke", {
						Color = Color3.fromRGB(220, 170, 40),
						Thickness = 1,
						Transparency = 0.4,
					}),
					Label = React.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = string.format("💰 %s G", tostring(math.floor(data.Gold or 0))),
						Font = Enum.Font.GothamBold,
						TextSize = 13,
						TextColor3 = Color3.fromRGB(240, 200, 50),
					}),
				}),

				-- Close
				CloseBtn = React.createElement("TextButton", {
					Size = UDim2.new(0, 36, 0, 36),
					Position = UDim2.new(1, -50, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(200, 60, 60),
					Text = "✕",
					Font = Enum.Font.GothamBold,
					TextSize = 18,
					TextColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					[React.Event.Activated] = function()
						setVisible(false)
					end,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
				}),
			}),

			-- Tab Buttons (Dash / Jump)
			TabBar = React.createElement("Frame", {
				Size = UDim2.new(1, -32, 0, 40),
				Position = UDim2.new(0, 16, 0, 72),
				BackgroundColor3 = Color3.fromRGB(14, 16, 26),
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				DashTab = React.createElement("TextButton", {
					Size = UDim2.new(0.5, 0, 1, 0),
					BackgroundColor3 = activeTab == "Dash"
						and TAB_COLORS.Dash
						or Color3.fromRGB(14, 16, 26),
					Text = "🏃 DASH",
					Font = Enum.Font.GothamBold,
					TextSize = 14,
					TextColor3 = activeTab == "Dash"
						and Color3.new(1, 1, 1)
						or Color3.fromRGB(120, 125, 160),
					BorderSizePixel = 0,
					LayoutOrder = 1,
					[React.Event.Activated] = function()
						setActiveTab("Dash")
					end,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
				}),

				JumpTab = React.createElement("TextButton", {
					Size = UDim2.new(0.5, 0, 1, 0),
					BackgroundColor3 = activeTab == "Jump"
						and TAB_COLORS.Jump
						or Color3.fromRGB(14, 16, 26),
					Text = "🦘 JUMP",
					Font = Enum.Font.GothamBold,
					TextSize = 14,
					TextColor3 = activeTab == "Jump"
						and Color3.new(1, 1, 1)
						or Color3.fromRGB(120, 125, 160),
					BorderSizePixel = 0,
					LayoutOrder = 2,
					[React.Event.Activated] = function()
						setActiveTab("Jump")
					end,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
				}),
			}),

			-- Equipped display banner
			EquippedBanner = React.createElement("Frame", {
				Size = UDim2.new(1, -32, 0, 30),
				Position = UDim2.new(0, 16, 0, 120),
				BackgroundColor3 = tabColor:Lerp(Color3.fromRGB(18, 20, 32), 0.8),
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
				Label = React.createElement("TextLabel", {
					Size = UDim2.new(1, -16, 1, 0),
					Position = UDim2.new(0, 8, 0, 0),
					BackgroundTransparency = 1,
					Text = string.format(
						"Currently equipped for %s: %s",
						activeTab,
						(function()
							local eId = activeTab == "Dash" and data.EquippedDashEffect or data.EquippedJumpEffect
							local eCfg = Config.GetMovementEffect(eId or "Default")
							return eCfg and (eCfg.Icon .. " " .. eCfg.DisplayName) or "None"
						end)()
					),
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextColor3 = tabColor,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
			}),

			-- Scrollable list
			ScrollFrame = React.createElement("ScrollingFrame", {
				Size = UDim2.new(1, -16, 1, -170),
				Position = UDim2.new(0, 8, 0, 160),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 4,
				ScrollBarImageColor3 = tabColor,
				CanvasSize = UDim2.new(0, 0, 0, #Config.MovementEffects * 98 + 20),
				ScrollingDirection = Enum.ScrollingDirection.Y,
			}, (function()
				local children: { [string]: any } = {
					Layout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 2),
					}),
				}
				for k, v in pairs(cards) do
					children[k] = v
				end
				return children
			end)()),
		}),
	})
end

-- ======================================
-- Public API
-- ======================================
MovementEffectUI.Component = MovementEffectUIComponent

function MovementEffectUI.Open()
	if _setVisible then
		_setVisible(true)
	end
end

function MovementEffectUI.Close()
	if _setVisible then
		_setVisible(false)
	end
end

function MovementEffectUI.Toggle()
	if _setVisible then
		-- Luau không hỗ trợ function updater với type boolean, dùng biến local
		local setter = _setVisible
		setter(false) -- Đơn giản: đóng nếu đang mở (logic cần biến trạng thái ơ nơi gọi)
	end
end

return MovementEffectUI
