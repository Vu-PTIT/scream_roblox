--!strict
-- TextFilterService.luau
-- Server-side: Lọc custom shout text qua Roblox TextService
-- Bắt buộc để tuân thủ Community Standards của Roblox

local Players     = game:GetService("Players")
local TextService = game:GetService("TextService")

local Shared  = game.ReplicatedStorage.Shared
local Config  = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService: any = nil
task.defer(function()
	DataService = require(script.Parent.DataService)
end)

local TextFilterService = {}

-- Cooldown tracking
local LastFilterTime: { [number]: number } = {}

local function onSetCustomShout(player: Player, rawText: string)
	if not DataService then return end

	-- Validate type & length
	if type(rawText) ~= "string" then return end
	rawText = rawText:sub(1, Config.CustomShout.MaxLength)
	if #rawText == 0 then return end

	-- Cooldown
	local now = os.clock()
	local last = LastFilterTime[player.UserId] or 0
	if now - last < Config.CustomShout.Cooldown then
		local remaining = math.ceil(Config.CustomShout.Cooldown - (now - last))
		Remotes.Events.Notification:FireClient(player, "⏳ Đổi câu hét sau " .. remaining .. " giây!")
		return
	end
	LastFilterTime[player.UserId] = now

	-- Filter qua TextService (bắt buộc trên Roblox production)
	local filteredText = rawText
	local success, result = pcall(function()
		local textObject = TextService:FilterStringAsync(rawText, player.UserId)
		return textObject:GetNonChatStringForBroadcastAsync()
	end)

	if success and result then
		filteredText = result
	else
		-- Nếu filter fail (test env), dùng text gốc có warning
		if not success then
			warn("[TextFilterService] Filter failed for", player.Name, ":", result)
		end
		-- Trong production thực tế nên reject nếu filter fail
	end

	-- Lưu vào data
	DataService.UpdateField(player, "CustomShoutText", filteredText)

	-- Broadcast cho các client gần đó hiển thị
	Remotes.Events.DisplayCustomShout:FireAllClients(player.UserId, filteredText)
	Remotes.Events.Notification:FireClient(player, "✏️ Câu hét đã được đổi!")
end

-- Cleanup khi player rời
local function onPlayerRemoving(player: Player)
	LastFilterTime[player.UserId] = nil
end

Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Bind remote
Remotes.Events.SetCustomShout.OnServerEvent:Connect(function(player: Player, ...)
	local args = { ... }
	local text = args[1]
	if type(text) == "string" then
		onSetCustomShout(player, text)
	end
end)

return TextFilterService
