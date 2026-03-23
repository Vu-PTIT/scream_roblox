--!strict
-- HUD.luau
-- Client-side HUD: VocalPoints bar, Gold, Rebirth, Attack/Defense stats
-- Viết bằng Luau thuần (không cần React package)
-- Khi bạn cài Wally + React, có thể chuyển sang dùng HUDApp.luau

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game.ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local HUD = {}
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- BUILD UI
-- ============================================================
local screen: ScreenGui
local vpBarFill: Frame
local vpLabel: TextLabel
local goldLabel: TextLabel
local rebirthLabel: TextLabel
local atkLabel: TextLabel
local defLabel: TextLabel

local function buildHUD()
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	screen = Instance.new("ScreenGui")
	screen.Name = "HUD"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 0
	screen.Parent = PlayerGui

	-- ===================== TOP RIGHT PILLS =====================
	local topRight = Instance.new("Frame")
	topRight.Name = "TopRight"
	topRight.Size = UDim2.new(0, 340, 0, 45)
	topRight.Position = UDim2.new(1, -15, 0, 60)
	topRight.AnchorPoint = Vector2.new(1, 0)
	topRight.BackgroundTransparency = 1
	topRight.Parent = screen

	local topLayout = Instance.new("UIListLayout")
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	topLayout.SortOrder = Enum.SortOrder.LayoutOrder
	topLayout.Padding = UDim.new(0, 10)
	topLayout.Parent = topRight

	-- Gold pill
	local goldPill = Instance.new("Frame")
	goldPill.Name = "GoldPill"
	goldPill.Size = UDim2.new(0, 130, 0, 38)
	goldPill.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	goldPill.BorderSizePixel = 0
	goldPill.LayoutOrder = 1
	goldPill.Parent = topRight

	local goldCorner = Instance.new("UICorner")
	goldCorner.CornerRadius = UDim.new(0, 18)
	goldCorner.Parent = goldPill

	goldLabel = Instance.new("TextLabel")
	goldLabel.Name = "GoldLabel"
	goldLabel.Size = UDim2.new(1, -10, 1, 0)
	goldLabel.Position = UDim2.new(0, 5, 0, 0)
	goldLabel.BackgroundTransparency = 1
	goldLabel.Text = "💰 0 Gold"
	goldLabel.TextColor3 = Color3.fromRGB(240, 200, 50)
	goldLabel.Font = Enum.Font.GothamBold
	goldLabel.TextSize = 14
	goldLabel.TextXAlignment = Enum.TextXAlignment.Center
	goldLabel.Parent = goldPill

	-- Rebirth pill
	local rebirthPill = Instance.new("Frame")
	rebirthPill.Name = "RebirthPill"
	rebirthPill.Size = UDim2.new(0, 195, 0, 38)
	rebirthPill.BackgroundColor3 = Color3.fromRGB(45, 30, 60)
	rebirthPill.BorderSizePixel = 0
	rebirthPill.LayoutOrder = 2
	rebirthPill.Parent = topRight

	local rebirthCorner = Instance.new("UICorner")
	rebirthCorner.CornerRadius = UDim.new(0, 18)
	rebirthCorner.Parent = rebirthPill

	rebirthLabel = Instance.new("TextLabel")
	rebirthLabel.Name = "RebirthLabel"
	rebirthLabel.Size = UDim2.new(1, -10, 1, 0)
	rebirthLabel.Position = UDim2.new(0, 5, 0, 0)
	rebirthLabel.BackgroundTransparency = 1
	rebirthLabel.Text = "⭐ Rebirth: 0 (x1.00)"
	rebirthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthLabel.Font = Enum.Font.GothamBold
	rebirthLabel.TextSize = 13
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Center
	rebirthLabel.Parent = rebirthPill

	-- ===================== VP PROGRESS BAR (Bottom Left) =====================
	local vpContainer = Instance.new("Frame")
	vpContainer.Name = "VPContainer"
	vpContainer.Size = UDim2.new(0, 400, 0, 56)
	vpContainer.Position = UDim2.new(0.5, 0, 0, 15)
	vpContainer.AnchorPoint = Vector2.new(0.5, 0)
	vpContainer.BackgroundColor3 = Color3.fromRGB(21, 22, 32)
	vpContainer.BorderSizePixel = 0
	vpContainer.Parent = screen

	local vpContainerCorner = Instance.new("UICorner")
	vpContainerCorner.CornerRadius = UDim.new(0, 10)
	vpContainerCorner.Parent = vpContainer

	local vpTitle = Instance.new("TextLabel")
	vpTitle.Size = UDim2.new(1, -12, 0, 18)
	vpTitle.Position = UDim2.new(0, 8, 0, 6)
	vpTitle.BackgroundTransparency = 1
	vpTitle.Text = "🎤 VOCAL POINTS"
	vpTitle.TextColor3 = Color3.fromRGB(180, 180, 210)
	vpTitle.Font = Enum.Font.GothamBold
	vpTitle.TextSize = 11
	vpTitle.TextXAlignment = Enum.TextXAlignment.Left
	vpTitle.Parent = vpContainer

	local vpBarBg = Instance.new("Frame")
	vpBarBg.Name = "VPBarBg"
	vpBarBg.Size = UDim2.new(1, -16, 0, 18)
	vpBarBg.Position = UDim2.new(0, 8, 0, 30)
	vpBarBg.BackgroundColor3 = Color3.fromRGB(40, 42, 58)
	vpBarBg.BorderSizePixel = 0
	vpBarBg.ClipsDescendants = true
	vpBarBg.Parent = vpContainer

	local vpBgCorner = Instance.new("UICorner")
	vpBgCorner.CornerRadius = UDim.new(0, 6)
	vpBgCorner.Parent = vpBarBg

	vpBarFill = Instance.new("Frame")
	vpBarFill.Name = "VPFill"
	vpBarFill.Size = UDim2.new(0, 0, 1, 0)
	vpBarFill.BackgroundColor3 = Color3.fromRGB(84, 101, 139)
	vpBarFill.BorderSizePixel = 0
	vpBarFill.Parent = vpBarBg

	local vpFillCorner = Instance.new("UICorner")
	vpFillCorner.CornerRadius = UDim.new(0, 6)
	vpFillCorner.Parent = vpBarFill

	-- Gradient on fill
	local fillGrad = Instance.new("UIGradient")
	fillGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(84, 101, 139)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 160, 200)),
	})
	fillGrad.Rotation = 0
	fillGrad.Parent = vpBarFill

	vpLabel = Instance.new("TextLabel")
	vpLabel.Name = "VPLabel"
	vpLabel.Size = UDim2.new(1, 0, 1, 0)
	vpLabel.Position = UDim2.new(0, 0, 0, 0)
	vpLabel.BackgroundTransparency = 1
	vpLabel.Text = "0 / 10000"
	vpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	vpLabel.Font = Enum.Font.GothamBold
	vpLabel.TextSize = 11
	vpLabel.TextXAlignment = Enum.TextXAlignment.Center
	vpLabel.ZIndex = 2
	vpLabel.Parent = vpBarBg

	-- ===================== STATS BOX (Bottom Right) =====================
	local statsBox = Instance.new("Frame")
	statsBox.Name = "StatsBox"
	statsBox.Size = UDim2.new(0, 155, 0, 56)
	statsBox.Position = UDim2.new(0, 15, 1, -80)
	statsBox.AnchorPoint = Vector2.new(0, 1)
	statsBox.BackgroundColor3 = Color3.fromRGB(21, 22, 32)
	statsBox.BorderSizePixel = 0
	statsBox.Parent = screen

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 10)
	statsCorner.Parent = statsBox

	local statsLayout = Instance.new("UIListLayout")
	statsLayout.FillDirection = Enum.FillDirection.Vertical
	statsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statsLayout.Padding = UDim.new(0, 4)
	statsLayout.Parent = statsBox

	local function makeStatLabel(text: string): TextLabel
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -12, 0, 18)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = Color3.fromRGB(230, 230, 255)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = statsBox
		return lbl
	end

	atkLabel = makeStatLabel("⚔️ Attack: 10")
	defLabel = makeStatLabel("🛡️ Defense: 10")
end

-- ============================================================
-- UPDATE LOGIC
-- ============================================================
local function updateHUD(data: any)
	if not data then return end

	local vp        = math.floor(data.VocalPoints or 0)
	local maxVP     = Config.Rebirth.VocalPointsRequired
	local ratio     = math.clamp(vp / maxVP, 0, 1)

	-- Tween fill bar
	TweenService:Create(vpBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(ratio, 0, 1, 0)
	}):Play()
	vpLabel.Text = string.format("%d / %d", vp, maxVP)

	goldLabel.Text    = string.format("💰 %s", tostring(math.floor(data.Gold or 0)))
	rebirthLabel.Text = string.format("⭐ Rebirth: %d (x%.2f)", data.RebirthCount or 0, data.RebirthMultiplier or 1)

	local totalAtk = (data.Attack or 10) + (data.AttackUpgradeLevel or 0) * Config.Upgrades[1].StatPerLevel + (data.SpeakerUpgradeLevel or 0) * Config.Upgrades[2].StatPerLevel
	local totalDef = (data.Defense or 10) + (data.DefenseUpgradeLevel or 0) * Config.Upgrades[3].StatPerLevel + (data.ArmorUpgradeLevel or 0) * Config.Upgrades[4].StatPerLevel
	atkLabel.Text = string.format("⚔️ Attack: %d", totalAtk)
	defLabel.Text = string.format("🛡️ Defense: %d", totalDef)
end

-- ============================================================
-- INIT
-- ============================================================
function HUD.Init()
	buildHUD()

	-- Subscribe to PlayerDataUpdated remote
	Remotes.Events.PlayerDataUpdated.OnClientEvent:Connect(function(...)
		local args = { ... }
		local key = args[1]
		local value = args[2]

		-- Lazy update one field at a time
		local DataController: any = nil
		local ok = pcall(function()
			DataController = require(script.Parent.Parent.Controllers.DataController)
		end)
		if ok and DataController then
			local data = DataController.GetData()
			if data then
				data[key] = value
				updateHUD(data)
			end
		end
	end)

	-- Load initial data when available
	task.defer(function()
		task.wait(1)
		local ok, DataController = pcall(function()
			return require(script.Parent.Parent.Controllers.DataController)
		end)
		if ok and DataController then
			local data = DataController.GetData()
			if data then updateHUD(data) end

			-- Subscribe to ongoing data changes
			if DataController.OnDataChanged then
				DataController.OnDataChanged(function(_key, _val)
					local d = DataController.GetData()
					if d then updateHUD(d) end
				end)
			end
		end
	end)
end

return HUD
