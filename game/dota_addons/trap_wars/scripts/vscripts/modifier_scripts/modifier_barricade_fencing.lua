LinkLuaModifier("modifier_barricade_fencing", "modifier_scripts/modifier_barricade_fencing.lua", LUA_MODIFIER_MOTION_NONE)
modifier_barricade_fencing = class({})

-- right now hardcoded for 2x2 grid square traps (128x128 units)
-- the valid unit names, and the fencing model for each (precached in the unit)
local fencing_models = {
    npc_trapwars_wood_fence = "models/traps/wood_fence/fencing.vmdl",
    npc_trapwars_stone_wall = ""
}
local destruction_particles = {
    npc_trapwars_wood_fence = "particles/traps/barricade/barricade_destroyed.vpcf",
    npc_trapwars_stone_wall = ""
}

-----------------------------------------
--       Base Modifier Functions       --
-----------------------------------------
function modifier_barricade_fencing:OnCreated()
    if not IsServer() then return end

    local barricade = self:GetParent()
    if not barricade then return end  

    -- make sure this is being run on one of the valid units
    if not fencing_models[barricade:GetUnitName()] then return end

    -- give things a frame or so to settle
    Timers:CreateTimer(1/30, function()
        -- set the post's yaw to one of four directions 0->2pi
        local angle = RandomInt(0,3) * math.pi/2
        barricade:SetForwardVector(Vector(math.cos(angle), math.sin(angle), 0))

        -- remove any fencing in this section
        self:ClearFencing(barricade)

        -- build the fencing
        self:BuildFencing(barricade)
    end)
end

function modifier_barricade_fencing:OnDestroy()
    if not IsServer() then return end

    local barricade = self:GetParent()
    if not barricade then return end

    -- make sure this is being run on one of the valid units
    if not fencing_models[barricade:GetUnitName()] then return end


    -- find and remove all of the fencing around this fence post
    self:ClearFencing(barricade)

    -- hide the fence post
    barricade:AddNoDraw()

    -- add destruction particles
    if destruction_particles[barricade:GetUnitName()] then
        local part = ParticleManager:CreateParticle(destruction_particles[barricade:GetUnitName()], PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(part, 0, barricade:GetAbsOrigin())
        ParticleManager:SetParticleControlOrientation(part, 0, barricade:GetForwardVector(), barricade:GetRightVector(), barricade:GetUpVector())
        
        Timers:CreateTimer(2, function()
            ParticleManager:DestroyParticle(part, false)
            ParticleManager:ReleaseParticleIndex(part)
        end)
    end
end

function modifier_barricade_fencing:IsHidden()
    return true
end


-----------------------------------------
--         Additional Functions        --
-----------------------------------------
function modifier_barricade_fencing:FindAdjacentBarricades(center, radius, ignore_this)
    local found_entities = {}

    for _, ent in pairs(Entities:FindAllByClassnameWithin("npc_dota_creature", center, radius)) do
        if fencing_models[ent:GetUnitName()] and ent ~= ignore_this then
            table.insert(found_entities, ent)
        end
    end

    return found_entities
end

function modifier_barricade_fencing:FindAdjacentFencing(center, radius, ignore_this)
    local found_entities = {}

    for _, ent in pairs(Entities:FindAllByClassnameWithin("prop_dynamic", center, radius)) do
        for _, model in pairs(fencing_models) do
            if ent:GetModelName() == model and ent ~= ignore_this then
                table.insert(found_entities, ent)
                break
            end
        end
    end

    return found_entities
end

function modifier_barricade_fencing:SortEntitiesByDistance(entity_array, center)
    local sorted_array, distances = {}, {}

    for _, ent in pairs(entity_array) do
        local distance = (center - ent:GetAbsOrigin()):Length2D()

        for key=1, #sorted_array+1 do
            if not distances[key] or distance < distances[key] then
                table.insert(distances, key, distance)
                table.insert(sorted_array, key, ent)
                break
            end
        end
    end

    return sorted_array
end

function modifier_barricade_fencing:SortEntitiesByAngle(entity_array, center)  -- fIXME: remove this if it isn't getting used (tbd)
    local square, diagonal, acute1, acute2, other = {}, {}, {}, {}, {}

    for _, ent in pairs(entity_array) do
        local angle = math.floor(math.acos(Vector(1, 0, 0):Dot((center-ent:GetAbsOrigin()):Normalized()))*180/math.pi+0.5)

        if angle == 0 or angle == 90 or angle == 180 then
            table.insert(square, ent)
        elseif angle == 45 or angle == 135 then
            table.insert(diagonal, ent)
        elseif angle == 27 or angle == 63 then
            table.insert(acute1, ent)
        elseif angle == 117 or angle == 153 then
            table.insert(acute2, ent)
        else
            table.insert(other, ent)
        end
    end

    local sorted_array = {}
    for _, ent in pairs(square)   do table.insert(sorted_array, ent) end
    for _, ent in pairs(diagonal) do table.insert(sorted_array, ent) end
    for _, ent in pairs(acute1)   do table.insert(sorted_array, ent) end
    for _, ent in pairs(acute2)   do table.insert(sorted_array, ent) end
    for _, ent in pairs(other)    do table.insert(sorted_array, ent) end
    return sorted_array
end

function modifier_barricade_fencing:ClearFencing(barricade)
    if not barricade then return end
    local center = GameRules.GameMode:SnapBoxToGrid2D(barricade:GetAbsOrigin(), 2, 2)

    for _, ent in pairs(Entities:FindAllByClassnameWithin("prop_dynamic", center, 91)) do
        for _, model in pairs(fencing_models) do
            if ent:GetModelName() == model then
                ent:Kill()
                break
            end
        end
    end
end

function modifier_barricade_fencing:BuildFencing(barricade)
    if not barricade then return end
    local unit_name = barricade:GetUnitName()
    local center = GameRules.GameMode:SnapBoxToGrid2D(barricade:GetAbsOrigin(), 2, 2)

    --for _, ent in pairs(self:SortEntitiesByAngle(self:FindAdjacentBarricades(center, 182, barricade), center)) do
    for _, ent in pairs(self:SortEntitiesByDistance(self:FindAdjacentBarricades(center, 182, barricade), center)) do
        local ent_pos = ent:GetAbsOrigin()
        local fence_pos = center - (center-ent_pos)/2
        local build = true

        -- if it's not the same type of barricade, don't build fencing to it
        if unit_name ~= ent:GetUnitName() then build = false end


        local angle = math.floor(math.acos(Vector(1, 0, 0):Dot((center-ent_pos):Normalized()))*180/math.pi+0.5)
        -- 0 27 45 63 90 117 135 153 180 153 135 117 90 63 45 27 0

        if angle == 45 or angle == 135 then
            local adjacent_fences = self:FindAdjacentFencing(fence_pos, 64)
            if #adjacent_fences > 1 then build = false end
        end
        --[[  FIXME: these didn't work; come up with some better way of dealing with the odd angles
        if angle == 117 then
            local adjacent_fences = self:FindAdjacentFencing(fence_pos+Vector(64, 0, 0), 10)
            for _, ent in pairs(self:FindAdjacentFencing(fence_pos+Vector(-64, 0, 0), 10)) do table.insert(adjacent_fences, ent) end
            if #adjacent_fences > 1 then build = false end
        end

        if angle == 153 then
            local adjacent_fences = self:FindAdjacentFencing(fence_pos+Vector(0, 64, 0), 10)
            for _, ent in pairs(self:FindAdjacentFencing(fence_pos+Vector(0, -64, 0), 10)) do table.insert(adjacent_fences, ent) end
            if #adjacent_fences > 1 then build = false end
        end

        if angle == 117 or angle == 153 then
            local adjacent_cades = self:FindAdjacentBarricades(center, 182, barricade)
            if #adjacent_cades > 2 then build = false end
        end
        ]]


        if build then
            local fencing = SpawnEntityFromTableSynchronous("prop_dynamic", {model=fencing_models[unit_name], origin=center-(center-ent_pos)/2})
            fencing:SetForwardVector((1+RandomInt(0, 1)*-2)*(center-ent_pos))
        end
    end
end