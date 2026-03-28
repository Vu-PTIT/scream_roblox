--!strict
-- Refx.luau
-- Lightweight VFX Replication Library
-- Principle: No server-side parts, client-side rendering with memory leak cleanup.

local RunService = game:GetService("RunService")
local Shared     = game.ReplicatedStorage:WaitForChild("Shared")
local Remotes    = require(Shared:WaitForChild("Remotes"))
local Packnafy   = require(script.Parent:WaitForChild("Packnafy"))

local Refx = {}

type EffectFactory = (...any) -> (() -> ())?
local RegisteredEffects: { [string]: EffectFactory } = {}
local ActiveEffects: { [string]: { () -> () } } = {}

-- ============================================================
-- SERVER API
-- ============================================================

-- Broadcast a VFX signal to all clients
function Refx.Fire(vfxName: string, ...: any)
	if not RunService:IsServer() then
		warn("[Refx] Fire can only be called from the Server.")
		return
	end
	
	local packedData = Packnafy.Pack(...)
	Remotes.Events.RefxSignal:FireAllClients(vfxName, packedData)
end

-- Fire to a specific client
function Refx.FireClient(player: Player, vfxName: string, ...: any)
	if not RunService:IsServer() then return end
	local packedData = Packnafy.Pack(...)
	Remotes.Events.RefxSignal:FireClient(player, vfxName, packedData)
end

-- ============================================================
-- CLIENT API
-- ============================================================

-- Register a VFX factory function
-- The factory should return a cleanup function.
function Refx.Register(vfxName: string, factory: EffectFactory)
	RegisteredEffects[vfxName] = factory
end

-- Start listening for VFX signals (should be called once on the client)
function Refx.Listen()
	if not RunService:IsClient() then
		warn("[Refx] Listen can only be called from the Client.")
		return
	end

	Remotes.Events.RefxSignal.OnClientEvent:Connect(function(vfxName: string, packedData: { any })
		local factory = RegisteredEffects[vfxName]
		if not factory then
			warn("[Refx] No factory registered for VFX:", vfxName)
			return
		end

		local args = { Packnafy.Unpack(packedData) }
		local cleanup = factory(table.unpack(args))
		
		if cleanup and type(cleanup) == "function" then
			if not ActiveEffects[vfxName] then
				ActiveEffects[vfxName] = {}
			end
			table.insert(ActiveEffects[vfxName], cleanup)
		end
	end)
end

-- Force cleanup of all active effects for a specific name
function Refx.Cleanup(vfxName: string)
	local effects = ActiveEffects[vfxName]
	if not effects then return end
	
	for _, cleanup in ipairs(effects) do
		pcall(cleanup)
	end
	ActiveEffects[vfxName] = {}
end

return Refx
