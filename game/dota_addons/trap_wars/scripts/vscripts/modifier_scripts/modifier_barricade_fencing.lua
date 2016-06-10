LinkLuaModifier("modifier_barricade_fencing", "modifier_scripts/modifier_barricade_fencing.lua", LUA_MODIFIER_MOTION_NONE)
modifier_barricade_fencing = class({})

-- the valid unit names, and the fencing model for each
local fencing_models = {
    npc_trapwars_wood_fence = "models/traps/wood_fence/fencing.vmdl",
    npc_trapwars_stone_wall = ""
}

function modifier_barricade_fencing:OnCreated()
    if not IsServer() then return end

    local barricade = self:GetParent()
    if not barricade then return end

    -- make sure this is being run on one of the valid units
    if not fencing_models[barricade:GetUnitName()] then return end

    local tilesize = GameRules.TileSize or 128

    -- give things a frame or so to settle
    Timers:CreateTimer(1/30, function()
        local caster_pos = GameRules.GameMode:Get2DGridCenter(barricade:GetAbsOrigin())

        -- add the gridnav blocker
        local blocker = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin=caster_pos})
        barricade.blocker = blocker:GetEntityIndex()
        -- reset the entity's position after the blocker is placed
        barricade:SetAbsOrigin(caster_pos)

        -- set the post's yaw to one of four directions 0->2pi
        local unit_vector = Vector(1, 0, 0)
        for i=0, RandomInt(0, 3) do
            unit_vector = RotatePosition(unit_vector, VectorToAngles(Vector(0, 1, 0)), unit_vector)
        end
        barricade:SetForwardVector(RandomVector(1))

        -- do a precursory removal of any diagonal fencing around this tile (would have preferred a simple radius check, however it was glitchy as hell)
        local diagonal_spots = {
            caster_pos + Vector(tilesize/2, tilesize/2, 0),
            caster_pos + Vector(tilesize/2, -tilesize/2, 0),
            caster_pos + Vector(-tilesize/2, tilesize/2, 0),
            caster_pos + Vector(-tilesize/2, -tilesize/2, 0)
        }
        for _, pos in pairs(diagonal_spots) do
            for _, ent in pairs(Entities:FindAllByClassnameWithin("prop_dynamic", pos, tilesize/4)) do
                for _, model in pairs(fencing_models) do
                    if not ent:IsNull() and ent:GetModelName() == model then ent:Kill() end
                end
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

        -- find other barricades around this one at said positions, but only if they're the same unit type as this one
        local found_entities = {}
        for i, pos in pairs(check_positions) do
            for _, ent in pairs(Entities:FindAllByClassnameWithin("npc_dota_creature", pos, tilesize/2)) do
                if ent:GetUnitName() == barricade:GetUnitName() and ent:IsAlive() then
                    found_entities[i] = ent
                    break;
                else
                    for unit_name, _ in pairs(fencing_models) do
                        if ent:GetUnitName() == unit_name and ent:IsAlive() then
                            found_entities[i] = true;
                        end
                    end
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

                -- finally, if it's not the same unit type when we searched above, ignore these checks and don't add (still used for checks on surrounding like-types though)
                if type(found_entities[i]) == "boolean" then add_fencing=false end


                if add_fencing then
                    -- new entity position
                    local ent_pos = found_entities[i]:GetAbsOrigin()

                    -- add in the fencing between them
                    local fencing = Entities:CreateByClassname("prop_dynamic")
                    fencing:SetAbsOrigin(caster_pos - (caster_pos-ent_pos)/2)

                    -- set the fencing model
                    fencing:SetModel(fencing_models[barricade:GetUnitName()])

                    -- align the fencing a random direction to spice things up a bit
                    local rand = 1
                    if RandomInt(0, 1) > 0 then rand = -1 end
                    fencing:SetForwardVector(rand*(caster_pos-ent_pos))
                end
            end
        end
    end)
end

function modifier_barricade_fencing:OnDestroy()
    if not IsServer() then return end

    local barricade = self:GetParent()
    if not barricade then return end

    -- make sure this is being run on one of the valid units
    if not fencing_models[barricade:GetUnitName()] then return end

    local tilesize = GameRules.TileSize or 128


    -- remove the gridnav blocker
    local blocker = EntIndexToHScript(barricade.blocker or -1)
    if blocker then blocker:RemoveSelf() end

    -- find and remove all of the fencing around this fence post
    for _, ent in pairs(Entities:FindAllByClassnameWithin("prop_dynamic", barricade:GetAbsOrigin(), math.sqrt(2*(tilesize*tilesize))/2+1)) do
        if ent:GetModelName() == "models/props_debris/wood_fence002.vmdl" then ent:Kill() end
    end


    -- re-add any diagonal fencing between surrounding posts that are still alive
    local caster_pos = GameRules.GameMode:Get2DGridCenter(barricade:GetAbsOrigin())
    local caster_unit_name = barricade:GetUnitName()
    Timers:CreateTimer(1/30, function()
        local check_positions = {
            caster_pos + Vector(         0,   tilesize+1, 0),
            caster_pos + Vector(tilesize+1,            0, 0),
            caster_pos + Vector(          0, -tilesize-1, 0),
            caster_pos + Vector(-tilesize-1,           0, 0),
        }

        -- find other barricades around this one at said positions
        local found_entities = {}
        for i, pos in pairs(check_positions) do
            for _, ent in pairs(Entities:FindAllByClassnameWithin("npc_dota_creature", pos, tilesize/2)) do
                for unit_name, _ in pairs(fencing_models) do
                    if ent:GetUnitName() == unit_name and ent:IsAlive() then
                        found_entities[i] = ent;
                        break;
                    end
                end
            end
        end

        -- add the fencing between if they're connected diagonally and are the same type
        found_entities[5] = found_entities[1]
        for i=1, 4 do
            if found_entities[i] and found_entities[i+1] then
                -- positions
                local ent1_pos = found_entities[i]:GetAbsOrigin()
                local ent2_pos = found_entities[i+1]:GetAbsOrigin()

                if ent1_pos and ent2_pos then
                    -- add in the fencing between them
                    local fencing = Entities:CreateByClassname("prop_dynamic")
                    fencing:SetAbsOrigin(ent1_pos - (ent1_pos-ent2_pos)/2)

                    -- set the fencing model
                    fencing:SetModel(fencing_models[caster_unit_name])

                    -- align the fencing a random direction to spice things up a bit
                    local rand = 1
                    if RandomInt(0, 1) > 0 then rand = -1 end
                    fencing:SetForwardVector(rand*(ent1_pos-ent2_pos))
                end
            end
        end
    end)

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