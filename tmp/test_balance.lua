-- Simulation script for knockback formula
local Config_Shout_BaseForce = 8
local Config_Shout_KnockbackScaling = 15
local Config_Shout_MaxForce = 300

local function calculateKnockbackSim(attackerAtk, targetDef)
    local flatComponent  = attackerAtk * 0.4
    local ratioComponent = (attackerAtk / math.max(1, targetDef)) * Config_Shout_KnockbackScaling
    local rawForce = Config_Shout_BaseForce + flatComponent + ratioComponent
    local capped = math.min(rawForce, Config_Shout_MaxForce)
    return capped
end

print("--- Knockback Simulation ---")
print(string.format("Newbie (ATK=10, DEF=10): %.2f", calculateKnockbackSim(10, 10)))
print(string.format("ATK lvl 5 (ATK=35, DEF=10): %.2f", calculateKnockbackSim(35, 10)))
print(string.format("ATK lvl 10 (ATK=60, DEF=10): %.2f", calculateKnockbackSim(60, 10)))
print(string.format("ATK lvl 30 (ATK=160, DEF=10): %.2f", calculateKnockbackSim(160, 10)))
print(string.format("Mid Game (ATK=100, DEF=100): %.2f", calculateKnockbackSim(100, 100)))
print(string.format("Late Game (ATK=500, DEF=500): %.2f", calculateKnockbackSim(500, 500)))
print(string.format("OP vs Noob (ATK=1000, DEF=10): %.2f", calculateKnockbackSim(1000, 10)))
