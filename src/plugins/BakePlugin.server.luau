-- BakePlugin.server.luau
-- VERSION: 3.0 (Studio-First Workflow)
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
local bakeButton = toolbar:CreateButton("Bake UI", "Refresh UI Components and Map Logic", "rbxassetid://4458901886");

local function runFullLogic()
    local ServerScriptService = game:GetService("ServerScriptService");
    local StarterGui = game:GetService("StarterGui");
    local StarterPlayer = game:GetService("StarterPlayer");

    bakeButton.Click:Connect(function()
        print("[Goku Plugin] Refreshing Studio Environment...");

        -- 1. Initialize Map Logic (Attach prompts, GUIs to existing parts)
        local server = ServerScriptService:FindFirstChild("Server") or ServerScriptService:FindFirstChild("Source");
        local ms = server and server:FindFirstChild("Services") and server.Services:FindFirstChild("MapService");
        if ms and ms:IsA("ModuleScript") then 
            print("[Goku Plugin] Initializing MapService...");
            local success, err = pcall(function() require(ms).Init(); end);
            if not success then warn("[Goku Plugin] MapInit Error: " .. tostring(err)); end
        end

        -- 2. Bake UI (Render React components into StarterGui for preview)
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
        print("[Goku Plugin] Refresh complete!");
    end);
end

pcall(runFullLogic);
print("[Goku Plugin] Loaded successfully.");