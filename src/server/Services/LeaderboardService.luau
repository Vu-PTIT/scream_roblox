--!strict
-- LeaderboardService.luau
-- Quản lý Global Leaderboard bằng OrderedDataStore 

local LeaderboardService = {}
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local VocalPointsLB = DataStoreService:GetOrderedDataStore("ShoutSim_VocalPointsLB_v1")

local function updateBoard(data: any)
    local board = workspace:FindFirstChild("Map") and workspace:FindFirstChild("Map") :: any
    board = board and board:FindFirstChild("GlobalLeaderboardBoard")
    if not board then return end
    
    local gui = board:FindFirstChild("LeaderboardGUI")
    local list = gui and gui:FindFirstChild("ListFrame")
    if not list then return end
    
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    for i, entry in ipairs(data) do
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 40)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        frame.BorderSizePixel = 0
        frame.LayoutOrder = i
        frame.Parent = list
        
        local rank = Instance.new("TextLabel")
        rank.Size = UDim2.new(0.1, 0, 1, 0)
        rank.BackgroundTransparency = 1
        rank.Text = "#" .. tostring(i)
        rank.TextColor3 = Color3.fromRGB(255, 255, 255)
        rank.Font = Enum.Font.GothamBold
        rank.TextSize = 20
        rank.Parent = frame
        
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.6, 0, 1, 0)
        name.Position = UDim2.new(0.1, 0, 0, 0)
        name.BackgroundTransparency = 1
        local success, username = pcall(function() return Players:GetNameFromUserIdAsync(tonumber(entry.key) or 1) end)
        name.Text = success and username or "Unknown Player"
        name.TextColor3 = Color3.fromRGB(200, 200, 200)
        name.Font = Enum.Font.Gotham
        name.TextSize = 20
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = frame
        
        local score = Instance.new("TextLabel")
        score.Size = UDim2.new(0.3, 0, 1, 0)
        score.Position = UDim2.new(0.7, 0, 0, 0)
        score.BackgroundTransparency = 1
        score.Text = tostring(entry.value) .. " VP"
        score.TextColor3 = Color3.fromRGB(255, 215, 0)
        score.Font = Enum.Font.GothamBold
        score.TextSize = 20
        score.TextXAlignment = Enum.TextXAlignment.Right
        score.Parent = frame
    end
end

function LeaderboardService.Init()
    task.spawn(function()
        while true do
            -- Lưu điểm hiện tại của các người chơi online lên Leaderboard
            for _, player in ipairs(Players:GetPlayers()) do
                local data = DataService.GetData(player)
                if data then
                    pcall(function()
                        VocalPointsLB:SetAsync(tostring(player.UserId), math.floor(data.VocalPoints))
                    end)
                end
            end
            
            -- Lấy Top 10
            local success, pages = pcall(function()
                return VocalPointsLB:GetSortedAsync(false, 10)
            end)
            
            if success and pages then
                local topData = pages:GetCurrentPage()
                updateBoard(topData)
            end
            
            task.wait(60) -- Cập nhật mỗi 60 giây
        end
    end)
    print("🏆 [LeaderboardService] Started loop.")
end

return LeaderboardService
