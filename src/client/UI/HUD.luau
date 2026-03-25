--!strict
-- HUD.luau
-- Client-side HUD: VocalPoints bar, Gold, Rebirth, Attack/Defense stats
-- Viết bằng Luau thuần (hỗ trợ "Smart Binding" để cho phép chỉnh sửa trong Studio)

local Players      = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game.ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local HUD = {}
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- UI REFERENCES (Lưu trữ để cập nhật data)
-- ============================================================
local screen: ScreenGui
local vpBarFill: Frame = nil :: any
local vpLabel: TextLabel = nil :: any
local goldLabel: TextLabel = nil :: any
local rebirthLabel: TextLabel = nil :: any
local atkLabel: TextLabel = nil :: any
local defLabel: TextLabel = nil :: any
local hpBarFill: Frame = nil :: any
local hpLabel: TextLabel = nil :: any

HUD.VPPillLabel = nil :: TextLabel?

-- ============================================================
-- HELPER: PILL CREATOR
-- ============================================================
local function _makePill(name: string, icon: string, color: Color3, weight: number, parent: Instance): TextLabel
	-- Visual Recognition: Search for ANY child that looks like this pill (by icon)
	local existing: Frame? = parent:FindFirstChild(name) :: Frame?
	
	if not existing then
		-- Debug: List all children
		print("🔍 [HUD] Searching children of " .. parent.Name .. " for icon: " .. icon)
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("Frame") then
				local lbl = child:FindFirstChildOfClass("TextLabel")
				local textMatch = lbl and lbl.Text:find(icon)
				local nameMatch = child.Name:lower():find(name:lower():gsub("pill", ""))
				
				if textMatch or nameMatch then
					existing = child
					print("✅ [HUD] RECLAIMED pill: " .. name .. " from " .. child.Name .. " (Source: " .. (if textMatch then "Icon" else "Name") .. ")")
					child.Name = name
					break
				end
			end
		end
	end
	
	-- Recursive depth search if still not found
	if not existing and screen then
		print("🔍 [HUD] Pill '" .. name .. "' not found. Searching ENTIRE ScreenGui...")
		for _, desc in ipairs(screen:GetDescendants()) do
			if desc:IsA("Frame") and not desc:IsDescendantOf(parent) then
				local lbl = desc:FindFirstChildOfClass("TextLabel")
				local textMatch = lbl and lbl.Text:find(icon)
				local nameMatch = desc.Name:lower():find(name:lower():gsub("pill", ""))
				
				if textMatch or nameMatch then
					existing = desc
					print("✅ [HUD] RECLAIMED pill (RECURSIVE): " .. name .. " from " .. desc:GetFullName())
					desc.Name = name
					desc.Parent = parent -- Reparent to correct container
					break
				end
			end
		end
	end

	if existing and existing:IsA("Frame") then
		local label = existing:FindFirstChild("Label") or existing:FindFirstChildOfClass("TextLabel")
		if label and label:IsA("TextLabel") then 
			print("ℹ️ [HUD] Bound to existing pill: " .. name)
			return label 
		end
	end

	print("ℹ️ [HUD] Creating new pill: " .. name)
	local pill = Instance.new("Frame")
	pill.Name = name
	pill.Size = UDim2.new(0, weight, 0, 36)
	pill.BackgroundColor3 = Config.Theme.Background
	pill.BackgroundTransparency = 0.2
	pill.BorderSizePixel = 0
	pill.Parent = parent

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 18)
	pCorner.Parent = pill

	local pStroke = Instance.new("UIStroke")
	pStroke.Thickness = 1
	pStroke.Color = color
	pStroke.Transparency = 0.5
	pStroke.Parent = pill

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = icon .. " 0"
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = pill
	
	return label
end

-- ============================================================
-- BUILD UI (Smart Binding)
-- ============================================================

local function buildHUD(overrideParent: Instance?)
	local pg = (overrideParent or (LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"))) :: Instance?
	if not pg then return end
	
	-- [SMART BINDING] Aggressive detection: Find ANY ScreenGui with HUD containers
	if RunService:IsRunning() then
		-- Wait a short bit to let React render its UI to avoid race condition duplication
		task.wait(0.2)
	end
	
	local existing: ScreenGui? = nil
	for _, child in ipairs(pg:GetChildren()) do
		if child:IsA("ScreenGui") then
			local isMatch = (child.Name == "HUD") 
				or child:FindFirstChild("VPContainer", true) 
				or child:FindFirstChild("TopRight", true)
				or child:FindFirstChild("HealthContainer", true)
				or child:FindFirstChild("StatsFrame", true)
				
			if isMatch then
				if not existing then
					existing = child
					print("ℹ️ [HUD] Aggressively detected and bound to: " .. child.Name)
				else
					print("⚠️ [HUD] Destroying duplicate: " .. child.Name)
					child:Destroy()
				end
			end
		end
	end
	
	if existing then
		screen = existing
		print("ℹ️ [HUD] Using existing ScreenGui for smart binding.")
	else
		local newScreen = Instance.new("ScreenGui")
		newScreen.Name = "HUD"
		newScreen.ResetOnSpawn = false
		newScreen.IgnoreGuiInset = true
		newScreen.DisplayOrder = 0
		newScreen.Parent = pg
		screen = newScreen
	end

	-- 1. TOP RIGHT PILLS (Merge TopRight and TopRightContainer)
	local tr1 = screen:FindFirstChild("TopRight")
	local tr2 = screen:FindFirstChild("TopRightContainer") or screen:FindFirstChild("TopRightContainer", true)
	
	local tr: Instance? = tr1 or tr2
	
	if tr1 and tr2 and tr1 ~= tr2 then
		print("ℹ️ [HUD] Merging TopRight containers...")
		for _, child in ipairs(tr1:GetChildren()) do
			if not tr2:FindFirstChild(child.Name) then
				child.Parent = tr2
			else
				child:Destroy()
			end
		end
		tr1:Destroy()
		tr = tr2
	end

	local topRight: Frame
	if tr and tr:IsA("Frame") then
		topRight = tr
		print("ℹ️ [HUD] Bound to existing TopRight container.")
	else
		topRight = Instance.new("Frame")
		topRight.Name = "TopRight"
		topRight.Size = UDim2.new(0, 480, 0, 45)
		topRight.Position = UDim2.new(1, -15, 0, 50)
		topRight.AnchorPoint = Vector2.new(1, 0)
		topRight.BackgroundTransparency = 1
		topRight.Parent = screen

		local topLayout = Instance.new("UIListLayout")
		topLayout.FillDirection = Enum.FillDirection.Horizontal
		topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		topLayout.SortOrder = Enum.SortOrder.LayoutOrder
		topLayout.Padding = UDim.new(0, 12)
		topLayout.Parent = topRight
	end
	topRight.Name = "TopRight"

	local gLabel = _makePill("GoldPill", "💰", Config.Theme.TextGold, 120, topRight)
	goldLabel = gLabel :: TextLabel
	if gLabel and gLabel.Parent and gLabel.Parent:IsA("Frame") then
		(gLabel.Parent :: Frame).LayoutOrder = 1
	end
	
	local vLabel = _makePill("VPPill", "🎙️", Color3.fromRGB(100, 200, 255), 140, topRight)
	HUD.VPPillLabel = vLabel
	if vLabel and vLabel.Parent then
		(vLabel.Parent :: Frame).LayoutOrder = 2
	end
	
	local rLabel = _makePill("RebirthPill", "⭐", Color3.fromRGB(255, 255, 255), 180, topRight)
	rebirthLabel = rLabel
	if rLabel and rLabel.Parent then
		(rLabel.Parent :: Frame).LayoutOrder = 3
	end

	-- 2. VP PROGRESS BAR
	local vpc = screen:FindFirstChild("VPContainer") or screen:FindFirstChild("VPBar", true)
	local vpContainer: Frame
	if vpc and vpc:IsA("Frame") then
		vpContainer = vpc
		vpLabel = (vpContainer:FindFirstChild("VPLabel", true) or vpContainer:FindFirstChild("PercentLabel", true) or Instance.new("TextLabel")) :: TextLabel
	else
		vpContainer = Instance.new("Frame")
		vpContainer.Name = "VPContainer"
		vpContainer.Size = UDim2.new(0, 420, 0, 50)
		vpContainer.Position = UDim2.new(0.5, 0, 0, 20)
		vpContainer.AnchorPoint = Vector2.new(0.5, 0)
		vpContainer.BackgroundColor3 = Config.Theme.Background
		vpContainer.BackgroundTransparency = 0.2
		vpContainer.BorderSizePixel = 0
		vpContainer.Parent = screen
		
		local vpcCorner = Instance.new("UICorner")
		vpcCorner.CornerRadius = Config.Theme.CornerRadius
		vpcCorner.Parent = vpContainer
		
		local vpTitle = Instance.new("TextLabel")
		vpTitle.Size = UDim2.new(1, 0, 0, 18)
		vpTitle.Position = UDim2.new(0, 0, 0, 4)
		vpTitle.BackgroundTransparency = 1
		vpTitle.Text = "REBIRTH PROGRESS"
		vpTitle.TextColor3 = Config.Theme.TextSecondary
		vpTitle.Font = Enum.Font.GothamBold
		vpTitle.TextSize = 10
		vpTitle.Parent = vpContainer

		local vpBarBg = Instance.new("Frame")
		vpBarBg.Size = UDim2.new(1, -30, 0, 10)
		vpBarBg.Position = UDim2.new(0.5, 0, 0, 32)
		vpBarBg.AnchorPoint = Vector2.new(0.5, 0)
		vpBarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		vpBarBg.BorderSizePixel = 0
		vpBarBg.ClipsDescendants = true
		vpBarBg.Parent = vpContainer
		
		local vpbCorner = Instance.new("UICorner")
		vpbCorner.CornerRadius = UDim.new(1, 0)
		vpbCorner.Parent = vpBarBg

		vpLabel = Instance.new("TextLabel")
		vpLabel.Name = "VPLabel"
		vpLabel.Size = UDim2.new(1, 0, 0, 14)
		vpLabel.Position = UDim2.new(0, 0, 0, 22)
		vpLabel.BackgroundTransparency = 1
		vpLabel.TextSize = 10
		vpLabel.Font = Enum.Font.GothamBold
		vpLabel.Parent = vpContainer
	end

	local vpf = vpContainer:FindFirstChild("VPFill", true)
	if vpf and vpf:IsA("Frame") then
		vpBarFill = vpf
	else
		local bg = vpContainer:FindFirstChildOfClass("Frame", true)
		if bg then
			vpBarFill = Instance.new("Frame")
			vpBarFill.Name = "VPFill"
			vpBarFill.Size = UDim2.new(0.5, 0, 1, 0)
			vpBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			vpBarFill.BorderSizePixel = 0
			vpBarFill.Parent = bg
			local fillGrad = Instance.new("UIGradient")
			fillGrad.Color = ColorSequence.new(Color3.fromRGB(80, 150, 255), Color3.fromRGB(150, 200, 255))
			fillGrad.Parent = vpBarFill
			local vpfCorner = Instance.new("UICorner")
			vpfCorner.CornerRadius = UDim.new(1, 0)
			vpfCorner.Parent = vpBarFill
		end
	end

	-- 3. STATS FRAME (Standardized to StatsFrame for React compatibility)
	local sb = screen:FindFirstChild("StatsFrame") 
		or screen:FindFirstChild("StatsFrame", true)
		or screen:FindFirstChild("StatsBox") 
		or screen:FindFirstChild("StatsBox", true)
		
	-- [CLEANUP] If we found StatsFrame, but there is ALSO a StatsBox, nuke the Box.
	local legacyBox = screen:FindFirstChild("StatsBox")
	if legacyBox and legacyBox ~= sb then
		print("ℹ️ [HUD] Nuking legacy StatsBox duplicate")
		legacyBox:Destroy()
	end

	local statsBox: Frame
	if sb and sb:IsA("Frame") then
		statsBox = sb
		print("ℹ️ [HUD] Bound to Stats container: " .. statsBox.Name)
		
		-- Cleanup legacy naming if found
		if statsBox.Name == "StatsBox" then
			statsBox.Name = "StatsFrame"
		end
		
		-- Re-apply layout if missing (React components usually have lists)
		if not statsBox:FindFirstChildOfClass("UIListLayout") then
			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.Padding = UDim.new(0, 2)
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
			layout.Parent = statsBox
		end
	else
		statsBox = Instance.new("Frame")
		statsBox.Name = "StatsFrame"
		statsBox.Size = UDim2.new(0, 180, 0, 100)
		statsBox.Position = UDim2.new(0, 15, 1, -15)
		statsBox.AnchorPoint = Vector2.new(0, 1)
		statsBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
		statsBox.BackgroundTransparency = 0.2
		statsBox.BorderSizePixel = 0
		statsBox.Parent = screen
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = statsBox
		
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.Padding = UDim.new(0, 2)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.Parent = statsBox
	end

	local function _bindStat(name: string, icon: string): TextLabel
		local statKey = if name == "Atk" or name == "Attack" then "Atk" else "Def"
		local rowName = statKey .. "Row" -- Standard: AtkRow, DefRow
		
		-- Visual Recognition for Rows
		local row: Frame? = statsBox:FindFirstChild(rowName) :: Frame?
		if not row then
			print("🔍 [HUD] Searching statsBox for " .. statKey .. " icon: " .. icon)
			for _, child in ipairs(statsBox:GetChildren()) do
				if child:IsA("Frame") then
					local lbl = child:FindFirstChildOfClass("TextLabel")
					local textMatch = lbl and lbl.Text:find(icon)
					local nameMatch = child.Name:lower():find(statKey:lower())
					
					if textMatch or nameMatch then
						row = child
						print("✅ [HUD] RECLAIMED row: " .. rowName .. " from " .. child.Name)
						child.Name = rowName
						break
					end
				end
			end
		end
		
		-- Recursive search for stats if not found in parent
		if not row and screen then
			for _, desc in ipairs(screen:GetDescendants()) do
				if desc:IsA("Frame") and (desc.Name:find("Row") or desc.Name:find("Stats")) and not desc:IsDescendantOf(statsBox) then
					local lbl = desc:FindFirstChildOfClass("TextLabel")
					local textMatch = lbl and lbl.Text:find(icon)
					local nameMatch = desc.Name:lower():find(statKey:lower())
					
					if textMatch or nameMatch then
						row = desc
						print("✅ [HUD] RECLAIMED row (RECURSIVE): " .. rowName .. " from " .. desc:GetFullName())
						desc.Name = rowName
						desc.Parent = statsBox
						break
					end
				end
			end
		end
			
		if not (row and row:IsA("Frame")) then
			local newRow = Instance.new("Frame")
			newRow.Name = rowName
			newRow.Size = UDim2.new(1, -20, 0, 24)
			newRow.BackgroundTransparency = 1
			newRow.Parent = statsBox
			row = newRow
		else
			row.Name = rowName -- Standardize to AtkRow/DefRow
		end
		
		local rowInstance = row :: Frame
		-- Standard React label name is "Value"
		local label = rowInstance:FindFirstChild("Value") 
			or rowInstance:FindFirstChild(statKey .. "Label")
			or rowInstance:FindFirstChild("Label")
			
		if not (label and label:IsA("TextLabel")) then
			local newLabel = Instance.new("TextLabel")
			newLabel.Name = "Value" -- Standard React Name
			newLabel.Size = UDim2.new(1, -25, 1, 0)
			newLabel.Position = UDim2.new(0, 25, 0, 0)
			newLabel.BackgroundTransparency = 1
			newLabel.TextColor3 = Config.Theme.TextSecondary
			newLabel.Font = Enum.Font.GothamBold
			newLabel.TextSize = 13
			newLabel.TextXAlignment = Enum.TextXAlignment.Left
			newLabel.Parent = rowInstance
			
			local iconLbl = Instance.new("TextLabel")
			iconLbl.Size = UDim2.new(0, 20, 1, 0)
			iconLbl.BackgroundTransparency = 1
			iconLbl.Text = icon
			iconLbl.Parent = rowInstance
			
			label = newLabel
		else
			-- If it exists, ensure we only have ONE icon label
			local existingIcons = {}
			for _, c in ipairs(rowInstance:GetChildren()) do
				if c:IsA("TextLabel") and c.Text == icon then
					table.insert(existingIcons, c)
				end
			end
			if #existingIcons > 1 then
				for i = 2, #existingIcons do
					existingIcons[i]:Destroy()
				end
			end
		end
		
		return label :: TextLabel
	end

	atkLabel = _bindStat("Atk", "⚔️")
	defLabel = _bindStat("Def", "🛡️")
end

-- ============================================================
-- UPDATE LOGIC
-- ============================================================
local function updateHUD(data: any)
	local d = data or {}
	local vp = math.floor(d.TotalVocalPoints or 0)
	local maxVP = Config.Rebirth.VocalPointsRequired or 100
	local ratio = math.clamp(vp / maxVP, 0, 1)

	if vpBarFill then
		TweenService:Create(vpBarFill, TweenInfo.new(0.4), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
	end
	if vpLabel then vpLabel.Text = string.format("%d / %d", vp, maxVP) end
	if goldLabel then goldLabel.Text = string.format("💰 %s", tostring(math.floor(d.Gold or 0))) end
	if HUD.VPPillLabel then HUD.VPPillLabel.Text = string.format("🎙️ VP: %s", tostring(math.floor(d.VocalPoints or 0))) end
	if rebirthLabel then rebirthLabel.Text = string.format("⭐ Rebirth: %d", d.RebirthCount or 0) end
	if hpLabel then hpLabel.Text = "HP: 100 / 100" end -- Default for Studio
	
	local totalAtk = (d.Attack or 10) + (d.DamageUpgradeLevel or 0) * (Config.Upgrades[1].StatPerLevel or 0)
	local totalDef = (d.Defense or 10) + (d.ArmorUpgradeLevel or 0) * (Config.Upgrades[3].StatPerLevel or 0)
	if atkLabel then atkLabel.Text = string.format("Damage: %d", totalAtk) end
	if defLabel then defLabel.Text = string.format("Armor: %d", totalDef) end
end

-- ============================================================
-- HP BAR
-- ============================================================
local function setupHealthBar()
	-- Standardize to HealthContainer (React Name)
	local hpc = screen:FindFirstChild("HealthContainer") 
		or screen:FindFirstChild("HealthContainer", true)
		or screen:FindFirstChild("HPContainer")
		or screen:FindFirstChild("HPContainer", true)
		
	-- [CLEANUP] If we found two containers, nuke the vanilla one if we bound to React one
	local legacyHPC = screen:FindFirstChild("HPContainer")
	if legacyHPC and legacyHPC ~= hpc then
		print("ℹ️ [HUD] Nuking legacy HPContainer duplicate")
		legacyHPC:Destroy()
	end

	local hpContainer: Frame
	if hpc and hpc:IsA("Frame") then
		hpContainer = hpc
		print("ℹ️ [HUD] Bound to Health container: " .. hpContainer.Name)
		if hpContainer.Name == "HPContainer" then
			hpContainer.Name = "HealthContainer"
		end
		hpBarFill = (hpContainer:FindFirstChild("Fill", true) or hpContainer:FindFirstChild("Bar", true) or hpContainer:FindFirstChild("HPFill", true)) :: Frame
		hpLabel = (hpContainer:FindFirstChild("Label", true) or hpContainer:FindFirstChild("HPLabel", true)) :: TextLabel
	else
		hpContainer = Instance.new("Frame")
		hpContainer.Name = "HealthContainer"
		hpContainer.Size = UDim2.new(0, 180, 0, 32)
		hpContainer.Position = UDim2.new(0, 15, 0, 60)
		hpContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		hpContainer.BackgroundTransparency = 0.4
		hpContainer.Parent = screen
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = hpContainer
		
		hpBarFill = Instance.new("Frame")
		hpBarFill.Name = "Fill"
		hpBarFill.Size = UDim2.new(1, 0, 1, 0)
		hpBarFill.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
		hpBarFill.Parent = hpContainer
		
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = hpBarFill
		
		hpLabel = Instance.new("TextLabel")
		hpLabel.Name = "Label"
		hpLabel.Size = UDim2.new(1, 0, 1, 0)
		hpLabel.BackgroundTransparency = 1
		hpLabel.Text = "HP: 100 / 100"
		hpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		hpLabel.Font = Enum.Font.GothamBold
		hpLabel.TextSize = 10
		hpLabel.Parent = hpContainer
	end

	local function updateHP()
		if not LocalPlayer then return end
		local char = LocalPlayer.Character
		if char and hpBarFill and hpLabel then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
				TweenService:Create(hpBarFill, TweenInfo.new(0.25), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
				hpLabel.Text = string.format("HP: %d / %d", math.ceil(hum.Health), math.ceil(hum.MaxHealth))
			end
		end
	end
	if LocalPlayer then
		LocalPlayer.CharacterAdded:Connect(function(char)
			local hum = char:WaitForChild("Humanoid") :: Humanoid
			hum.HealthChanged:Connect(updateHP)
			updateHP()
		end)
		if LocalPlayer.Character then updateHP() end
	end
end

-- ============================================================
-- INIT
-- ============================================================
function HUD.Init(overrideParent: Instance?)
	buildHUD(overrideParent)
	if screen then setupHealthBar() end
	
	pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)

	-- Initial updates for Studio/Bake mode
	updateHUD({})
	
	task.defer(function()
		task.wait(1)
		local ok, DC = pcall(function() return require(script.Parent.Parent.Controllers.DataController) end)
		if ok and DC then
			local data = DC.GetData()
			if data then updateHUD(data) end
			-- Final data population
			updateHUD({})
			
			-- [SAFETY] Delayed cleanup to handle any late-rendering duplicates
			if RunService:IsRunning() then
				task.delay(3, function()
					local pg = (LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"))
					if not pg then return end
					local screen = pg:FindFirstChild("HUD")
					if not (screen and screen:IsA("ScreenGui")) then return end
					
					-- Nuke any Vanilla-style HPContainer if HealthContainer exists
					local h1 = screen:FindFirstChild("HealthContainer")
					local h2 = screen:FindFirstChild("HPContainer")
					if h1 and h2 and h1 ~= h2 then h2:Destroy(); print("🧹 [HUD] Late-cleanup: HPContainer removed") end
					
					-- Nuke any StatsBox if StatsFrame exists
					local s1 = screen:FindFirstChild("StatsFrame")
					local s2 = screen:FindFirstChild("StatsBox")
					if s1 and s2 and s1 ~= s2 then s2:Destroy(); print("🧹 [HUD] Late-cleanup: StatsBox removed") end
				end)
			end

			print("[HUD] Initialized")
			if DC.OnDataChanged then
				DC.OnDataChanged(function() 
					local d = DC.GetData() 
					if d then updateHUD(d) end 
				end)
			end
		end
	end)
end

return HUD
