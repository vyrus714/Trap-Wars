function Activate()  -- called when the game mode is loaded
end

function OnPortal(trigger)  --  trigger.activator (other), trigger.caller (trigger)
    -- do NOT want items, or anything else that isn't CDota_BaseNPC, but damned if i can find a way to do that
    local result = {}
    trigger.activator:GatherCriteria(result)
    if result.classname == "dota_item_drop" then return end
    -- only creeps
    if not trigger.activator:IsCreep() then return end
    -- don't want units controlled by heroes
    if trigger.activator:IsOwnedByAnyPlayer() then return end


    -- get the team of the portal, we're assuming the name is formatted: <SomeName>_#
    local team = tonumber(trigger.caller:GetName():match('_(%d+).?'))
    -- if the creep is on the same team as the portal, disregaurd
    if trigger.activator:GetTeam() == team then return end


    -- send the score event
    --FireGameEvent("trapwars_score_update", {team=team, delta_score=-1}) FIXME: i have global vars now, dont need this
    -- hide the creep
    trigger.activator:AddNoDraw()
    if trigger.activator.attachments then
        for _, prop in pairs(trigger.activator.attachments) do
           prop:AddEffects(EF_NODRAW) 
        end
    end
    -- play particle effect   side note: particles/units/unit_greevil/loot_greevil_death.vpcf for portal death?
    local part = ParticleManager:CreateParticle("particles/units/unit_greevil/loot_greevil_tgt_end.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(part, 1, trigger.activator:GetAbsOrigin())
    ParticleManager:SetParticleControl(part, 3, trigger.activator:GetAbsOrigin())
    Timers:CreateTimer(4, function()
        ParticleManager:DestroyParticle(part, false)
        ParticleManager:ReleaseParticleIndex(part)
    end)
    -- emit portal sound effect
    CustomGameEventManager:Send_ServerToTeam(team, "trapwars_sound_event", {sound="Hero_Wisp.Spirits.Target"})
    -- finally kill the creep
    trigger.activator:Kill(nil, trigger.caller)
end

function OnEnteredGrid(trigger)
    if not trigger.activator:IsRealHero() then return end
    print(trigger.activator:GetName().." entered "..trigger.caller:GetName())
end

function OnExitedGrid(trigger)
    if not trigger.activator:IsRealHero() then return end
    print(trigger.activator:GetName().." exited  "..trigger.caller:GetName())
end

function OnTouchingGrid(trigger)
    print("touching"..GameRules:GetGameTime())
    --if not trigger.activator:IsRealHero() then return end
    --print(trigger.activator:GetName().." is touching "..trigger.caller:GetName())
end