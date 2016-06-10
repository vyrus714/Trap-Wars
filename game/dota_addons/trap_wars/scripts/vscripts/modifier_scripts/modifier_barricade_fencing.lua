LinkLuaModifier("modifier_barricade_fencing", "modifier_scripts/modifier_barricade_fencing.lua", LUA_MODIFIER_MOTION_NONE)
modifier_barricade_fencing = class({})

function modifier_barricade_fencing:OnCreated()
    if not IsServer() then return end

    local barricade = self:GetParent()
    if not barricade then return end


    Timers:CreateTimer(1/30, function()
        local tilesize = GameRules.TileSize or 128
        local caster_pos = GameRules.GameMode:Get2DGridCenter(barricade:GetAbsOrigin())
        local offset = Vector(0, 0, 60) -- offset for the fence posts

        -- add the gridnav blocker
        local blocker = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin=caster_pos})
        barricade.blocker = blocker:GetEntityIndex()
        -- reset the entity's position after the blocker is placed  (and slide it down, since the model is a bit tall)
        barricade:SetAbsOrigin(caster_pos - offset)

        -- give our fence post a random yaw
        barricade:SetForwardVector(RandomVector(1))

        -- do a precursory removal of any diagonal fencing around this tile (very annoying that it had to come to this)
        local diagonal_spots = {
            caster_pos + Vector(tilesize/2, tilesize/2, 0),
            caster_pos + Vector(tilesize/2, -tilesize/2, 0),
            caster_pos + Vector(-tilesize/2, tilesize/2, 0),
            caster_pos + Vector(-tilesize/2, -tilesize/2, 0)
        }
        for _, pos in pairs(diagonal_spots) do
            for _, ent in pairs(Entities:FindAllByClassnameWithin("prop_dynamic", pos, tilesize/4)) do
                if ent:GetModelName() == "models/props_debris/wood_fence002.vmdl" then ent:Kill() end
            end
        end

        -- very specifically ordered list of positions to check around this entity
        local check_positions = {
            caster_pos + Vector(         0,   tilesize+1, 0),
            caster_pos + Vector(tilesize+1,   tilesize+1, 0),
            caster_pos + Vector(tilesize+1,            0, 0),
            caster_pos + Vector(tilesize+1,  -tilesize-1, 0),
            caster_pos + Vector(          0, -tilesize-1, 0),
            caster_pos + Vector(-tilesize-1, -tilesize-1, 0),
            caster_pos + Vector(-tilesize-1,           0, 0),
            caster_pos + Vector(-tilesize-1,  tilesize+1, 0)
        }

        -- find other barricades around this one at said positions
        local found_entities = {}
        for i, pos in pairs(check_positions) do
            for _, ent in pairs(Entities:FindAllByClassnameWithin("npc_dota_creature", pos, tilesize/2)) do
                if ent.GetUnitName and ent:GetUnitName() == "npc_trapwars_barricade" and ent:IsAlive() then
                    found_entities[i] = ent
                    break;
                end
            end
        end

        -- add the fencing between them (odd=horizontal\vertical, even=diagonal)
        for i=1, 8 do
            if found_entities[i] then
                local add_fencing = false

                -- if it's an odd tile (horizontal\vertical), always add
                if (i+1)%2 == 0 then
                    add_fencing = true

                -- if it's an even tile (diagonal), add only if there isn't any even tiles next to it
                else
                    if i == 1 then
                        if not found_entities[8] and not found_entities[i+1] then add_fencing=true end
                    elseif i == 8 then
                        if not found_entities[i-1] and not found_entities[1] then add_fencing=true end
                    elseif not found_entities[i-1] and not found_entities[i+1] then add_fencing=true end
                end


                if add_fencing then
                    Timers:CreateTimer(1/15, function()
                        -- new entity position
                        local ent_pos = found_entities[i]:GetAbsOrigin() + offset

                        -- add in the fencing between them
                        local fencing = Entities:CreateByClassname("prop_dynamic")
                        fencing:SetAbsOrigin(caster_pos - (caster_pos-ent_pos)/2)

                        -- set the fencing model
                        fencing:SetModel("models/props_debris/wood_fence002.vmdl")
                        fencing:SetModelScale(0.8)

                        -- align the fencing
                        local rand = 1
                        if RandomInt(0, 1) > 0 then rand = -1 end
                        fencing:SetForwardVector(rand*(caster_pos-ent_pos))
                    end)
                end
            end
        end
    end)
end

function modifier_barricade_fencing:OnDestroy()
    if not IsServer() then return end

    local barricade = self:GetParent()
    if not barricade then return end

    local tilesize = GameRules.TileSize or 128


    -- remove the gridnav blocker
    local blocker = EntIndexToHScript(barricade.blocker or -1)
    if blocker then blocker:RemoveSelf() end

    -- find and remove all of the fencing around this fence post
    for _, ent in pairs(Entities:FindAllByClassnameWithin("prop_dynamic", barricade:GetAbsOrigin(), math.sqrt(2*(tilesize*tilesize))/2+1)) do
        if ent:GetModelName() == "models/props_debris/wood_fence002.vmdl" then ent:Kill() end
    end

    -- hide the fence post
    barricade:AddEffects(EF_NODRAW)

    -- add destruction particles
    local part = ParticleManager:CreateParticle("particles/traps/barricade/barricade_destroyed.vpcf", PATTACH_ABSORIGIN, barricade)
    ParticleManager:SetParticleControlEnt(part, 0, barricade, PATTACH_ABSORIGIN, "attach_origin", barricade:GetAbsOrigin(), true)
    Timers:CreateTimer(2, function()
        ParticleManager:DestroyParticle(part, false)
        ParticleManager:ReleaseParticleIndex(part)
    end)
end

function modifier_barricade_fencing:IsHidden()
    return true
end 