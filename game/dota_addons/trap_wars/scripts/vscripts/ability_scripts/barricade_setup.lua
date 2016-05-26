function OnCreated(keys)
    Timers:CreateTimer(1/30, function()
        local tilesize = GameRules.TileSize or 128
        local e1p = keys.caster:GetAbsOrigin()
        local offset = Vector(0, 0, 60) -- offset for the fence posts

        -- add the gridnav blocker
        local blocker = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin=e1p})
        keys.caster.blocker = blocker:GetEntityIndex()
        -- reset the entity's position after the blocker is placed  (and slide it down, since the model is a bit tall)
        keys.caster:SetAbsOrigin(e1p - offset)

        -- give our fence post a random yaw
        keys.caster:SetForwardVector(RandomVector(1))


        -- find other fence posts in the adjacent tiles and add fencing between them
        for _, entity in pairs(Entities:FindAllByClassnameWithin("npc_dota_creature", keys.caster:GetAbsOrigin(), tilesize+1)) do
            if entity.GetUnitName and entity:GetUnitName() == "npc_trapwars_barricade" and entity ~= keys.caster and entity:IsAlive() then
                -- new entity position
                local e2p = entity:GetAbsOrigin() + offset

                -- find the middle of the two fence posts
                local midpoint = e1p - (e1p-e2p)/2

                -- add in the fencing between them
                local fencing = Entities:CreateByClassname("prop_dynamic")
                fencing:SetAbsOrigin(midpoint)
                fencing:SetModel("models/props_debris/wood_fence002.vmdl")
                fencing:SetModelScale(0.8)

                -- align the fencing
                local randDir = 1
                if RandomInt(0, 1) > 0 then randDir = -1 end
                fencing:SetForwardVector(randDir*(e1p-e2p))
            end
        end
    end)
end

function OnDestroy(keys)
    local tilesize = GameRules.TileSize or 128

    -- remove the gridnav blocker
    local blocker = EntIndexToHScript(keys.caster.blocker)
    if blocker then blocker:RemoveSelf() end

    -- find and remove all of the fencing around this fence post
    for _, ent in pairs(Entities:FindAllByClassnameWithin("prop_dynamic", keys.caster:GetAbsOrigin(), tilesize/2+1)) do
        if ent:GetModelName() == "models/props_debris/wood_fence002.vmdl" then ent:Kill() end
    end

    -- hide the fence post
    keys.caster:AddEffects(EF_NODRAW)

    -- add destruction particles
    local part = ParticleManager:CreateParticle("particles/traps/barricade/barricade_destroyed.vpcf", PATTACH_ABSORIGIN, keys.caster)
    ParticleManager:SetParticleControlEnt(part, 0, keys.caster, PATTACH_ABSORIGIN, "attach_origin", keys.caster:GetAbsOrigin(), true)
    Timers:CreateTimer(2, function()
        ParticleManager:DestroyParticle(part, false)
        ParticleManager:ReleaseParticleIndex(part)
    end)
end