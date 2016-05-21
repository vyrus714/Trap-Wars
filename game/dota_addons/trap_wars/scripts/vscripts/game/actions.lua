local GameMode = GameRules.GameMode

function GameMode:SpawnTrap(name, position, team, owner)
    -- make sure this is a valid trap
    if not GameRules.npc_traps[name] then return nil end
    -- make sure there's no building here already
    if GameMode:IsATrapInTile(position) then return nil end
    -- make sure it's a valid team
    if team < DOTA_TEAM_FIRST or DOTA_TEAM_CUSTOM_MAX < team then return nil end


    -- plonk trap
    local trap = CreateUnitByName(name, GameMode:Get2DGridCenter(position), false, nil, owner, team)

    -- add modifiers to the trap (if it has them)
    if GameRules.npc_traps[name].modifiers then
        for _, modifier in pairs(GameRules.npc_traps[name].modifiers) do
            trap:AddNewModifier(nil, nil, modifier, {}) 
        end
    end
    -- if this trap isn't phased, move any units out of it
    if not trap:HasModifier("modifier_phased") then GameMode:UnstuckUnitsInTile(position) end


    return trap
end

function GameMode:SpawnTrapForPlayer(name, position, playerid)
    -- make sure we were passed a valid player
    if not PlayerResource:IsValidTeamPlayer(playerid) then return nil end
    -- make sure the player is allowed to make a trap here
    if not GameMode:IsInPlayersGrid(position, playerid) and not GameMode:IsInSharedGrid(position, PlayerResource:GetTeam(playerid)) then return nil end


    -- create the trap
    return GameMode:SpawnTrap(name, position, PlayerResource:GetTeam(playerid), PlayerResource:GetSelectedHeroEntity(playerid))
end





----------------------------------------------
--               Creep Waves                --
----------------------------------------------
function GameMode:GetRandomLaneCreep(min_level, max_level)
    local creeps = {}

    for name, data in pairs(GameRules.npc_lanecreeps) do
        if data.Level and min_level <= data.Level and data.Level <= max_level then
            table.insert(creeps, name)
        end
    end

    return creeps[RandomInt(1, #creeps)]
end

function GameMode:SpawnLaneCreeps(min_level, max_level)
    -- get a random creep to spawn
    local name = GameMode:GetRandomLaneCreep(min_level, max_level)
    if not name then return end

    -- spawn one of these creeps at every creep spawner
    for team, spawners in pairs(GameRules.team_spawners) do
        for _, eid in pairs(spawners) do
            local spawner = EntIndexToHScript(eid)

            if spawner then
                -- create the creep
                local creep = CreateUnitByName(name, spawner:GetAbsOrigin(), true, nil, nil, team)

                -- add attachments  FIXME: perhaps move attachments to the ingame attachments system using custom vmdl containers
                if GameRules.npc_lanecreeps[name].Attachments ~= nil then
                    creep.attachments = {}
                    for attach_point, models in pairs(GameRules.npc_lanecreeps[name].Attachments) do
                        for model, properties in pairs(models) do
                            local prop = Attachments:AttachProp(creep, attach_point, model, properties.scale, properties)
                            table.insert(creep.attachments, prop)
                        end
                    end
                end

                -- execute attack move order  FIXME, needs waypoints unfortunatley
                ExecuteOrderFromTable{
                    UnitIndex = creep:entindex(),
                    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
                    Position  = spawner:GetRootMoveParent():GetAbsOrigin(),
                    Queue     = true }
            end
        end
    end
end