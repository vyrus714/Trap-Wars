function OnPortal(keys)  --  keys.activator (activating entity), keys.caller (portal\trigger)
    -- if it's not a CDOTA_BaseNPC, or it's a hero, or it's controlled by a hero, then ignore that unit
    if not keys.activator.IsDeniable or keys.activator:IsHero() or keys.activator:IsOwnedByAnyPlayer() then return end

    local portal_team = keys.caller:Attribute_GetIntValue("team", -1)
    local creep_team = keys.activator:GetTeam()

    -- if the creep\portal are on the same team, ignore
    if creep_team == portal_team then return end


    -- adjust the score  FIXME: implement score system

    -- emit portal sound effect
    --CustomGameEventManager:Send_ServerToTeam(team, "trapwars_sound_event", {sound="Hero_Wisp.Spirits.Target"})  FIXME: turned off for sanity's sake

    -- play particle effect at creep location  side note: particles/units/unit_greevil/loot_greevil_death.vpcf for portal death?
    local part = ParticleManager:CreateParticle("particles/units/unit_greevil/loot_greevil_tgt_end.vpcf", PATTACH_CUSTOMORIGIN, nil)  -- FIXME: create particle for this
    ParticleManager:SetParticleControl(part, 1, keys.activator:GetAbsOrigin())
    ParticleManager:SetParticleControl(part, 3, keys.activator:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(part)

    -- play particle effect at portal location  FIXME: implement?

    -- hide and kill the creep
    keys.activator:AddNoDraw()
    if keys.activator.attachments then
        for _, prop in pairs(keys.activator.attachments) do
           prop:AddNoDraw()
        end
    end
    keys.activator:Kill(nil, keys.caller)
end