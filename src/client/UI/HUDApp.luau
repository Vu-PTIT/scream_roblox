--!strict
-- HUDApp.luau
-- Unified HUD system for Shout Simulator.
-- Manages layout for Stats, Health, Skills, and Navigation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)

local PillLabel = require(script.Parent.components.PillLabel)
local ProgressBar = require(script.Parent.components.ProgressBar)
local SkillSlot = require(script.Parent.components.SkillSlot)
local ModernButton = require(script.Parent.components.ModernButton)

-- Controllers
local DataController: any = nil
local ShoutController: any = nil
local _ShopApp: any = nil

task.defer(function()
	DataController = require(script.Parent.Parent.Controllers.DataController)
	ShoutController = require(script.Parent.Parent.Controllers.ShoutController)
	_ShopApp = require(script.Parent.ShopApp)
end)

type Props = {
	HandleAction: (id: string) -> (),
	Data: any,
}

local function HUDApp(props: Props)
	local data = props.Data or {}
	
	-- Fallback for initial data structure
	if not data.Gold then data.Gold = 0 end
	if not data.RebirthCount then data.RebirthCount = 0 end
	if not data.VocalPoints then data.VocalPoints = 0 end
	if not data.MaxHealth then data.MaxHealth = 100 end

	local health, setHealth = React.useState(data.MaxHealth or 100)
	local maxHealth, setMaxHealth = React.useState(data.MaxHealth or 100)

	React.useEffect(function()
		local LocalPlayer = Players.LocalPlayer
		if not LocalPlayer then return end

		local connection1: RBXScriptConnection? = nil
		local connection2: RBXScriptConnection? = nil
		local connection3: RBXScriptConnection? = nil

		local function updateHealth(char: Model?)
			if not char then return end
			task.spawn(function()
				local hum = char:WaitForChild("Humanoid", 3) :: Humanoid?
				if hum then
					setHealth(math.floor(hum.Health))
					setMaxHealth(math.floor(hum.MaxHealth))
					
					if connection1 then connection1:Disconnect() end
					if connection2 then connection2:Disconnect() end
					
					connection1 = hum.HealthChanged:Connect(function(newHp)
						setHealth(math.floor(newHp))
					end)
					connection2 = hum:GetPropertyChangedSignal("MaxHealth"):Connect(function()
						setMaxHealth(math.floor(hum.MaxHealth))
					end)
				end
			end)
		end

		updateHealth(LocalPlayer.Character)
		connection3 = LocalPlayer.CharacterAdded:Connect(updateHealth)

		return function()
			if connection1 then connection1:Disconnect() end
			if connection2 then connection2:Disconnect() end
			if connection3 then connection3:Disconnect() end
		end
	end, {})

	local displayHealth = math.clamp(health, 0, maxHealth)
	local hpPct = maxHealth > 0 and (displayHealth / maxHealth) or 0

	local requiredVP = Config.Rebirth.VocalPointsRequired

	local handleNavAction = function(id: string)
		if props.HandleAction then
			props.HandleAction(id)
		end
	end

	return React.createElement("ScreenGui", {
		Name = "HUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 0,
	}, {
		-- 1. BOTTOM LEFT: PLAYER STATUS CARD
		BottomLeftStatus = React.createElement("Frame", {
			Name = "StatusCard",
			Size = UDim2.new(0, 300, 0, 180),
			Position = UDim2.new(0, 20, 1, -20),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			-- Stats Row (Wallet) - LayoutOrder 3
			WalletRow = React.createElement("Frame", {
				Size = UDim2.new(0, 300, 0, 35),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Gold = React.createElement(PillLabel, {
					Icon = "💰",
					Text = string.format("%s", tostring(math.floor(data.Gold or 0))),
					TextColor = Color3.fromRGB(240, 200, 50),
					BackgroundColor = Color3.fromRGB(30, 30, 35),
					Width = 90,
					Height = 35,
					LayoutOrder = 1,
				}),
				VP = React.createElement(PillLabel, {
					Icon = "🎙️",
					Text = string.format("%s", tostring(math.floor(data.VocalPoints or 0))),
					TextColor = Color3.fromRGB(100, 200, 255),
					BackgroundColor = Color3.fromRGB(30, 35, 45),
					Width = 95,
					Height = 35,
					LayoutOrder = 2,
				}),
				Rebirth = React.createElement(PillLabel, {
					Icon = "⭐",
					Text = string.format("%d", data.RebirthCount or 0),
					TextColor = Color3.new(1, 1, 1),
					BackgroundColor = Color3.fromRGB(40, 30, 50),
					Width = 70,
					Height = 35,
					LayoutOrder = 3,
				}),
			}),

			-- Health Bar - LayoutOrder 2
			HealthBar = React.createElement("Frame", {
				Size = UDim2.new(0, 280, 0, 40),
				BackgroundColor3 = Color3.fromRGB(25, 25, 30),
				BackgroundTransparency = 0.2,
				LayoutOrder = 2,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
				Stroke = React.createElement("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.75, Thickness = 1 }),
				
				Icon = React.createElement("TextLabel", {
					Size = UDim2.new(0, 40, 1, 0),
					BackgroundTransparency = 1,
					Text = "❤️",
					TextSize = 18,
				}),
				
				BarBg = React.createElement("Frame", {
					Size = UDim2.new(1, -60, 0, 10),
					Position = UDim2.new(0, 45, 0, 22),
					BackgroundColor3 = Color3.fromRGB(40, 20, 20),
					BackgroundTransparency = 0.4,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
					Fill = React.createElement("Frame", {
						Size = UDim2.new(hpPct, 0, 1, 0),
						BackgroundColor3 = Color3.fromRGB(255, 60, 80),
					}, {
						Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
					}),
				}),
				
				Label = React.createElement("TextLabel", {
					Size = UDim2.new(1, -60, 0, 14),
					Position = UDim2.new(0, 45, 0, 6),
					BackgroundTransparency = 1,
					Text = string.format("HEALTH: %d / %d", displayHealth, maxHealth),
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold,
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
			}),

			-- Rebirth Progress (Large) - LayoutOrder 1
			Progress = React.createElement(ProgressBar, {
				Title = "REBIRTH PROGRESS",
				Icon = "📈",
				Current = math.floor(data.TotalVocalPoints or 0),
				Max = requiredVP,
				Size = UDim2.new(0, 280, 0, 55),
				Position = UDim2.new(0, 0, 0, 0),
				AnchorPoint = Vector2.new(0, 0),
				LayoutOrder = 1,
			}),
		}),

		-- 2. BOTTOM CENTER: SKILLS ONLY
		BottomCenterDock = React.createElement("Frame", {
			Name = "ControlDock",
			Size = UDim2.new(0, 400, 0, 70),
			Position = UDim2.new(0.5, 0, 1, -20),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),

			-- Skills Row
			SkillsRow = React.createElement("Frame", {
				Size = UDim2.new(0, 400, 0, 60),
				BackgroundTransparency = 1,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 10),
				}),
				Skill1 = React.createElement(SkillSlot, { Index = 1, Data = data, ShoutController = ShoutController }),
				Skill2 = React.createElement(SkillSlot, { Index = 2, Data = data, ShoutController = ShoutController }),
				Skill3 = React.createElement(SkillSlot, { Index = 3, Data = data, ShoutController = ShoutController }),
				Skill4 = React.createElement(SkillSlot, { Index = 4, Data = data, ShoutController = ShoutController }),
				Skill5 = React.createElement(SkillSlot, { Index = 5, Data = data, ShoutController = ShoutController }),
			}),
		}),

		-- 3. BOTTOM RIGHT: INVENTORY (BAG)
		BottomRightContainer = React.createElement("Frame", {
			Name = "RightHUD",
			Size = UDim2.new(0, 70, 0, 70),
			Position = UDim2.new(1, -20, 1, -20),
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
		}, {
			BagBtn = React.createElement(ModernButton, {
				Icon = "🎒", -- Backpack emoji
				Size = UDim2.new(0, 60, 0, 60),
				BackgroundColor = Color3.fromRGB(150, 60, 60),
				OnClick = function()
					handleNavAction("Bag")
				end,
			}),
		}),

	})
end

return HUDApp
