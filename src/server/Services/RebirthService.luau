--!strict
-- RebirthService.luau
-- Server-side: Xử lý Rebirth - Reset stats đổi lấy multiplier lớn hơn

local _Players = game:GetService("Players")
local Shared  = game.ReplicatedStorage.Shared
local Config  = require(Shared.Config)
local Types   = require(Shared.Types)
local Remotes = require(Shared.Remotes)

local DataService: any = nil
task.defer(function()
	DataService = require(script.Parent.DataService)
end)

local RebirthService = {}

local function onRebirthRequest(player: Player)
	if not DataService then return end
	local data = DataService.GetData(player) :: Types.PlayerData?
	if not data then return end

	-- Kiểm tra điều kiện
	if (data.TotalVocalPoints or 0) < Config.Rebirth.VocalPointsRequired then
		local needed = Config.Rebirth.VocalPointsRequired - (data.TotalVocalPoints or 0)
		Remotes.Events.Notification:FireClient(
			player,
			string.format(Config.Localization.Notifications.RebirthNeeded, math.ceil(needed))
		)
		Remotes.Events.RebirthResult:FireClient(player, false, data.RebirthMultiplier)
		return
	end

	-- Tính multiplier mới
	local newRebirthCount = data.RebirthCount + 1
	local newMultiplier   = 1 + (newRebirthCount * Config.Rebirth.MultiplierPerRebirth)

	-- Reset về default nhưng giữ nguyên pets, rebirth count, multiplier và JoinDate
	local defaultData = Config.DefaultPlayerData

	DataService.UpdateFields(player, {
		-- Reset tiến trình
		VocalPoints         = 0,
		TotalVocalPoints    = 0,
		Gold                = 0,
		Cups                = 0,
		Attack              = defaultData.Attack,
		Defense             = defaultData.Defense,
		MaxHealth           = defaultData.MaxHealth,
		DamageUpgradeLevel  = 0,
		HealthUpgradeLevel  = 0,
		ArmorUpgradeLevel   = 0,
		-- Giữ pets (không reset)
		-- Cộng rebirth
		RebirthCount        = newRebirthCount,
		RebirthMultiplier   = newMultiplier,
	})

	Remotes.Events.RebirthResult:FireClient(player, true, newMultiplier)
	Remotes.Events.Notification:FireClient(
		player,
		string.format(Config.Localization.Notifications.RebirthSuccess, newMultiplier)
	)

	print(string.format("[RebirthService] %s rebirth #%d | mult=%.2f", player.Name, newRebirthCount, newMultiplier))
end

-- Bind remote
Remotes.Events.RebirthRequest.OnServerEvent:Connect(function(player: Player)
	onRebirthRequest(player)
end)

return RebirthService
