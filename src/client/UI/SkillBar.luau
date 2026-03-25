--!strict
-- SkillBar.luau
-- Hiển thị hai slot skill đang được chọn
-- Hỗ trợ "Smart Binding" để cho phép chỉnh sửa trong Studio

local Players = game:GetService("Players")
local RunService    = game:GetService("RunService")
local _TweenService  = game:GetService("TweenService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config)

local DataController: any = nil
local ShoutController: any = nil
task.defer(function()
	DataController = require(script.Parent.Parent.Controllers.DataController)
	ShoutController = require(script.Parent.Parent.Controllers.ShoutController)
end)

local SkillBar = {}
local slots: { [number]: Frame } = {}

local function getSkillConfig(skillId: string?, allSkills: any)
	if not skillId then return Config.Skills[1] end
	for _, skill in ipairs(allSkills or {}) do
		if skill.Id == skillId then
			for _, cfg in ipairs(Config.Skills) do
				if cfg.SkillType == skill.SkillType then
					return cfg
				end
			end
		end
	end
	return Config.Skills[1]
end

local function updateUI()
	if not DataController then return end
	local data = DataController.GetData()
	if not data then return end

	for i = 1, 2 do
		local slotFrame = slots[i]
		if not slotFrame then continue end
		
		local skillId = data.EquippedSkillIds and data.EquippedSkillIds[i]
		local cfg = getSkillConfig(skillId, data.Skills)

		local iconLabel = slotFrame:FindFirstChild("Icon")
		if iconLabel and iconLabel:IsA("TextLabel") then
			iconLabel.Text = cfg.Icon or "📢"
		end
		
		local nameLabel = slotFrame:FindFirstChild("Name")
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Text = cfg.DisplayName or "Basic Shout"
		end
	end
end

function SkillBar.Init(overrideParent: Instance?)
	local localPlayer = Players.LocalPlayer
	if not localPlayer then return end
	
	local pg = (overrideParent or (localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui"))) :: Instance?
	if not pg then return end
	
	-- [SMART BINDING] Aggressive detection: Find ANY ScreenGui with skill slots
	if RunService:IsRunning() then
		task.wait(0.2)
	end
	
	local existing: ScreenGui? = nil
	for _, child in ipairs(pg:GetChildren()) do
		if child:IsA("ScreenGui") then
			local isMatch = (child.Name == "SkillBar") 
				or child:FindFirstChild("SlotContainer", true)
				or child:FindFirstChild("Slot_1", true)
				or child:FindFirstChild("Slot1", true)
				
			if isMatch then
				if not existing then
					existing = child
					print("ℹ️ [SkillBar] Aggressively detected and bound to: " .. child.Name)
				else
					print("⚠️ [SkillBar] Destroying duplicate: " .. child.Name)
					child:Destroy()
				end
			end
		end
	end
	
	local screenGui: ScreenGui
	if existing then
		screenGui = existing
		print("ℹ️ [SkillBar] Using existing ScreenGui for smart binding.")
	else
		local newSG = Instance.new("ScreenGui")
		newSG.Name = "SkillBar"
		newSG.ResetOnSpawn = false
		newSG.Parent = pg
		screenGui = newSG
	end

	-- Smart Bind Container
	local c = screenGui:FindFirstChild("Frame") or screenGui:FindFirstChild("SlotContainer", true)
	local container: Frame
	if c and c:IsA("Frame") then
		container = c
		print("ℹ️ [SkillBar] Bound to existing SlotContainer.")
	else
		container = Instance.new("Frame")
		container.Name = "SlotContainer"
		container.Size = UDim2.new(0, 360, 0, 80)
		container.Position = UDim2.new(0.5, 0, 1, -110)
		container.AnchorPoint = Vector2.new(0.5, 1)
		container.BackgroundTransparency = 1
		container.Parent = screenGui
		
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 16)
		layout.Parent = container
	end

	for i = 1, 2 do
		local slotName = "Slot_" .. i
		local existingSlot = container:FindFirstChild(slotName) or container:FindFirstChild(slotName, true)
		local frame: Frame
		
		if existingSlot and existingSlot:IsA("Frame") then
			frame = existingSlot
			slots[i] = frame
			print("ℹ️ [SkillBar] Bound to existing " .. slotName)
		else
			frame = Instance.new("Frame")
			frame.Name = slotName
			frame.Size = UDim2.new(0, 160, 0, 52)
			frame.BackgroundColor3 = Config.Theme.Background
			frame.BackgroundTransparency = 0.2
			frame.BorderSizePixel = 0
			frame.Parent = container
			slots[i] = frame
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = Config.Theme.CornerRadius
			corner.Parent = frame
		end

		-- Ensure surgical sub-elements
		local iconLabel = frame:FindFirstChild("Icon") or frame:FindFirstChild("SkillIcon") or frame:FindFirstChildOfClass("TextLabel")
		if not iconLabel then
			local newIconLabel = Instance.new("TextLabel")
			newIconLabel.Name = "Icon"
			newIconLabel.Size = UDim2.new(0, 44, 1, 0)
			newIconLabel.Position = UDim2.new(0, 5, 0, 0)
			newIconLabel.BackgroundTransparency = 1
			newIconLabel.Text = "📢"
			newIconLabel.TextSize = 26
			newIconLabel.TextColor3 = Config.Theme.TextMain
			newIconLabel.Font = Enum.Font.GothamBold
			newIconLabel.Parent = frame
			iconLabel = newIconLabel
		else
			(iconLabel :: Instance).Name = "Icon"
		end

		local nameLabel = frame:FindFirstChild("Name") or frame:FindFirstChild("SkillName")
		if not (nameLabel and nameLabel:IsA("TextLabel")) then
			local newNameLabel = Instance.new("TextLabel")
			newNameLabel.Name = "SkillName"
			newNameLabel.Size = UDim2.new(1, -60, 0, 20)
			newNameLabel.Position = UDim2.new(0, 50, 0, 8)
			newNameLabel.BackgroundTransparency = 1
			newNameLabel.Text = "Basic Shout"
			newNameLabel.TextColor3 = Config.Theme.TextMain
			newNameLabel.Font = Enum.Font.GothamBold
			newNameLabel.TextSize = 14
			newNameLabel.TextXAlignment = Enum.TextXAlignment.Left
			newNameLabel.Parent = frame
			nameLabel = newNameLabel
		else
			(nameLabel :: Instance).Name = "SkillName"
		end

		local cdOverlay = frame:FindFirstChild("CDOverlay")
		if not cdOverlay then
			local newCDOverlay = Instance.new("Frame")
			newCDOverlay.Name = "CDOverlay"
			newCDOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
			newCDOverlay.BackgroundTransparency = 0.6
			newCDOverlay.BorderSizePixel = 0
			newCDOverlay.ZIndex = 5
			newCDOverlay.Visible = false
			newCDOverlay.Parent = frame
			
			local cdCorner = Instance.new("UICorner")
			cdCorner.CornerRadius = Config.Theme.CornerRadius
			cdCorner.Parent = newCDOverlay

			local cdLabel = Instance.new("TextLabel")
			cdLabel.Name = "CDLabel"
			cdLabel.Size = UDim2.new(1, 0, 1, 0)
			cdLabel.BackgroundTransparency = 1
			cdLabel.TextColor3 = Color3.new(1, 1, 1)
			cdLabel.Font = Enum.Font.GothamBlack
			cdLabel.TextSize = 18
			cdLabel.Parent = newCDOverlay
			
			cdOverlay = newCDOverlay
		end
	end

	task.spawn(function()
		while not DataController do task.wait(0.1) end
		updateUI()
		DataController.OnDataChanged(function() updateUI() end)
		
		if game:GetService("RunService"):IsRunning() then
			game:GetService("RunService").RenderStepped:Connect(function()
				if not ShoutController then return end
				local now = os.clock()
				local chargingSlot = ShoutController.GetChargingSlot()
				local selectedSlot = ShoutController.GetSelectedSlot()

				for i = 1, 2 do
					local slotFrame = slots[i]
					if not slotFrame then continue end
					
					local stroke = slotFrame:FindFirstChildOfClass("UIStroke")
					if stroke then
						if chargingSlot == i then
							stroke.Color = Color3.fromRGB(255, 255, 255)
							stroke.Thickness = 3
						elseif selectedSlot == i then
							stroke.Color = Color3.fromRGB(255, 215, 0)
							stroke.Thickness = 2.5
						else
							stroke.Color = Config.Theme.TextMuted
							stroke.Thickness = 1
						end
					end

					local cdO = slotFrame:FindFirstChild("CDOverlay", true)
					if cdO and cdO:IsA("Frame") then
						local cdOverlay = cdO
						local cdLabel = cdOverlay:FindFirstChild("CDLabel") :: TextLabel?
						local lastTime, cdDuration = ShoutController.GetCooldownData(i)
						local elapsed = now - lastTime
						if elapsed < cdDuration then
							cdOverlay.Visible = true
							local remaining = cdDuration - elapsed
							if cdLabel then cdLabel.Text = string.format("%.1fs", remaining) end
							cdOverlay.Size = UDim2.new(1, 0, remaining / cdDuration, 0)
							cdOverlay.Position = UDim2.new(0, 0, 1 - (remaining / cdDuration), 0)
						else
							cdOverlay.Visible = false
						end
					end
				end
			end)
		end
	end)

	-- Force initial update for Studio/Bake mode
	pcall(updateUI)

	print("[SkillBar] Initialized")
end

return SkillBar
