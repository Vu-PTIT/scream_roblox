-- BakePlugin.server.luau
-- VERSION: 2.1 (CLEAN ASCII)
print("[Goku Plugin] Initializing...");

local RunService = game:GetService("RunService");

-- 1. Check if 'plugin' global exists
local isPluginContext = false;
pcall(function() 
    if plugin ~= nil and typeof(plugin) == "Instance" and plugin:IsA("Plugin") then 
        isPluginContext = true;
    end
end);

if not isPluginContext then return end;

-- 2. Must ONLY run in EDIT MODE
if not RunService:IsEdit() then return end;

-- Create Toolbar and Buttons
local toolbar = plugin:CreateToolbar("Goku Tools");
local bakeButton = toolbar:CreateButton("Bake All", "Bake everything", "rbxassetid://4458901886");
local cleanButton = toolbar:CreateButton("Master Clean", "Clean everything", "rbxassetid://4458901571");
local exportButton = toolbar:CreateButton("Export Config", "Export Map Config to Output", "rbxassetid://4458901404");

local function runFullLogic()
    local ServerScriptService = game:GetService("ServerScriptService");
    local StarterGui = game:GetService("StarterGui");
    local StarterPlayer = game:GetService("StarterPlayer");
    local Workspace = game.Workspace;

    exportButton.Click:Connect(function()
        local map = Workspace:FindFirstChild("Map")
        if not map then warn("[Goku Plugin] No Map folder found to export."); return end
        
        print("\n--- [GOKU EXPORT: MAP CONFIG] ---")
        print("Config.Map = {")
        
        local function printPart(p, indent)
            if not p:IsA("BasePart") then return end
            print(string.format("%s%s = {", indent, p.Name))
            print(string.format("%s\tPosition = Vector3.new(%.2f, %.2f, %.2f),", indent, p.Position.X, p.Position.Y, p.Position.Z))
            print(string.format("%s\tSize = Vector3.new(%.2f, %.2f, %.2f),", indent, p.Size.X, p.Size.Y, p.Size.Z))
            print(string.format("%s},", indent))
        end

        local sz = map:FindFirstChild("SafeZones") and map.SafeZones:FindFirstChild("SafeZoneBase")
        if sz then printPart(sz, "\t") end
        
        local pvp = map:FindFirstChild("PvPZones") and map.PvPZones:FindFirstChild("PvPArenaBase")
        if pvp then printPart(pvp, "\t") end
        
        local starter = Workspace:FindFirstChild("StarterZone") and Workspace.StarterZone:FindFirstChild("Base")
        if starter then 
            print("\tStarterZone = {")
            print(string.format("\t\tPosition = Vector3.new(%.2f, %.2f, %.2f),", starter.Position.X, starter.Position.Y, starter.Position.Z))
            print(string.format("\t\tSize = Vector3.new(%.2f, %.2f, %.2f),", starter.Size.X, starter.Size.Y, starter.Size.Z))
            print("\t},")
        end

        print("}")
        print("--- [END EXPORT] ---\n")
        print("[Goku Plugin] Map config exported to Output (F9)!")
    end)

    local function cleanAll()
        print("[Goku Plugin] Performing Master Clean...");
        for _, child in ipairs(StarterGui:GetChildren()) do
            if child:IsA("ScreenGui") then child:Destroy(); end
        end
        local map = Workspace:FindFirstChild("Map");
        if map then map:Destroy(); end
        print("[Goku Plugin] Clean complete!");
    end

    bakeButton.Click:Connect(function()
        print("[Goku Plugin] Starting Power Bake...");
        -- Removed cleanAll() to preserve manual Studio edits (Smart Binding handles updates)

        -- 2.1 Bake Map
        local server = ServerScriptService:FindFirstChild("Server") or ServerScriptService:FindFirstChild("Source");
        local ms = server and server:FindFirstChild("Services") and server.Services:FindFirstChild("MapService");
        if ms and ms:IsA("ModuleScript") then 
            local success, err = pcall(function() require(ms).Init(); end);
            if not success then warn("[Goku Plugin] Map Bake Error: " .. tostring(err)); end
        end
        -- 2.2 Bake UI
        local scRoot = StarterPlayer:WaitForChild("StarterPlayerScripts"):FindFirstChild("Client");
        local uiMod = scRoot and scRoot:FindFirstChild("UI");
        if uiMod then
            print("[Goku Plugin] Baking UI Modules...");
            local list = {"HUD", "SkillBar", "Shop", "PetUI", "BagUI", "SkillUI", "RewardUI", "QuestUI", "CodeUI", "RebirthUI", "CustomShoutUI", "EggHatchUI"};
            for _, n in ipairs(list) do
                local m = uiMod:FindFirstChild(n);
                if m and m:IsA("ModuleScript") then 
                    pcall(function() require(m).Init(StarterGui); end);
                end
            end
        end
        print("[Goku Plugin] Power Bake complete!");
    end);
    
    cleanButton.Click:Connect(cleanAll);
end

pcall(runFullLogic);
print("[Goku Plugin] Loaded successfully.");