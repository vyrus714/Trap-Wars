LinkLuaModifier("modifier_point_simple_obstruction", "modifier_scripts/modifier_point_simple_obstruction.lua", LUA_MODIFIER_MOTION_NONE)
modifier_point_simple_obstruction = class({})

-- right now limited to 2x2 sized traps (128x128 units), since that is the size of the PSOs (and I don't want to mess with multiple PSOs ... yet)

function modifier_point_simple_obstruction:OnCreated()
    if not IsServer() then return end

    -- get the unit
    local unit = self:GetParent()
    if not unit then return end


    Timers:CreateTimer(1/30, function()
        -- get the unit's grid position
        local unit_tile_pos = GameRules.GameMode:SnapBoxToGrid2D(unit:GetAbsOrigin(), 2, 2)  -- and this is where we assume 2x2 trap size

        -- if there was somehow something registered as a pso on this unit already, remove it
        local detritus = EntIndexToHScript(unit.pso or -1)
        if detritus then detritus:RemoveSelf() end

        -- add the obstruction
        local pso = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin=unit_tile_pos})
        unit.pso = pso:GetEntityIndex()

        -- reset the entity's position after the pso is placed, in case it moved
        unit:SetAbsOrigin(unit_tile_pos)


        -- run a check to make sure this pso isn't stopping pathing, only redirecting it
        Timers:CreateTimer(1/30, function()
            local can_path = true

            for _, spawners in pairs(GameRules.team_spawners) do
                for _, entid in pairs(spawners) do
                    local spawner = EntIndexToHScript(entid)
                    if spawner then
                        local portal = spawner:GetRootMoveParent()
                        if portal and not GridNav:CanFindPath(spawner:GetAbsOrigin(), portal:GetAbsOrigin()) then can_path=false end
                    end
                end
            end

            -- if we can't find a path, then we need to remove this unit and refund the player
            if not can_path then
                -- make sure we remove the pso, just in case
                pso:RemoveSelf()

                -- refund the player
                PlayerResource:ModifyGold(unit:GetPlayerOwnerID(), GameRules.npc_traps[unit:GetUnitName()].GoldCost or 0, false, DOTA_ModifyGold_GameTick)

                -- FIXME: play a callback sound (FIXME: message as well)
                CustomGameEventManager:Send_ServerToPlayer(unit:GetPlayerOwner(), "trapwars_sound_event", {sound="General.Cancel"})

                -- kill the unit
                unit:RemoveSelf()
            end
        end)
    end)
end

function modifier_point_simple_obstruction:OnDestroy()
    if not IsServer() then return end

    -- get the unit
    local unit = self:GetParent()
    if not unit then return end

    -- remove the obstruction
    local pso = EntIndexToHScript(unit.pso or -1)
    if pso then pso:RemoveSelf() end
end

function modifier_point_simple_obstruction:IsHidden()
    return true
end 