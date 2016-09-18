local GameMode = GameRules.GameMode

----------------------------------------------
--                Spawning                  --
----------------------------------------------
function GameMode:SpawnTrap(name, position, args)  -- optional args: {rotation = [0-3], team = DOTATeam_t, owner = CDOTA_BaseNPC}
    -- make sure this is a valid trap
    if not GameRules.npc_traps[name] then return nil end

    -- parse out the args into local variables, so they're easier to work with
    local rotation = 0
    local owner    = nil
    local team     = DOTA_TEAM_NOTEAM

    if args then
        if args.rotation then rotation = args.rotation end
        if args.owner    then owner    = args.owner    end
        if args.team     then team     = args.team     end
    end


    -- get the length and width
    local length = GameRules.npc_traps[name].Length or 1
    local width  = GameRules.npc_traps[name].Width  or 1

    -- if we're at 90 or 270 degrees, swap the length and width
    if rotation == 1 or rotation == 3 then
        local temp = length
        length = width
        width = temp
    end


    -- snap the position to the grid, based on our trap's length and width
    position = GameMode:SnapBoxToGrid2D(position, length, width)


    -- plonk trap
    local trap = CreateUnitByName(name, position, false, nil, owner, team)

    if trap then
        -- if there's a rotation, rotate the trap to that rotation
        local angles = trap:GetAngles()
        trap:SetAngles(angles.x, rotation*90, angles.z)

        -- add this trap's entity index to the grid
        GameMode:AddTrapToGrid(position, length, width, trap:GetEntityIndex())

        -- allow the owner to control the trap  FIXME: keep this? ideally no, still not much choice..
        if owner then
            local pid = owner:GetPlayerOwnerID()
            if pid then trap:SetControllableByPlayer(pid, true) end
        end

        -- add modifiers to the trap (if it has them)
        if GameRules.npc_traps[name].modifiers then
            for _, modifier in pairs(GameRules.npc_traps[name].modifiers) do
                trap:AddNewModifier(nil, nil, modifier, {})
            end
        end

        -- if this trap isn't phased, move any units out of it
        if not trap:HasModifier("modifier_phased") then GameMode:UnstickUnitsInBox(position, length, width) end
    end

    return trap
end

function GameMode:SpawnTrapForPlayer(name, position, playerid, rotation)  -- rotation is optional
    -- make sure we were passed a valid player
    if not PlayerResource:IsValidTeamPlayer(playerid) then return nil end

    -- make sure the player is allowed to make a trap here
    local length = GameRules.npc_traps[name].Length or 1
    local width  = GameRules.npc_traps[name].Width  or 1

    if not GameMode:CanPlayerBuildHere(playerid, position, length, width, rotation) then return nil end

    -- create the trap
    return GameMode:SpawnTrap(name, position, {team=PlayerResource:GetTeam(playerid), owner=PlayerResource:GetSelectedHeroEntity(playerid), rotation=rotation})
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
                -- new command FollowEntity?
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
                    Position  = spawner:GetRootMoveParent():GetAbsOrigin(),  -- spawners are all children to the portals they attack
                    Queue     = true
                }
            end
        end
    end
end


----------------------------------------------
--                   Grid                   --
----------------------------------------------
function GameMode:AddTrapToGrid(position, length, width, entity_index)  -- FIXME: air grid support
    length, width = math.ceil(length), math.ceil(width)
    position = GameMode:SnapBoxToGrid2D(position, length, width)
    local start_index = GameMode:GetGridIndex(position - Vector(length*32, width*32, 0) + Vector(32, 32, 0))

    -- starting at the lower left corner, iterate through the grid tiles in this box
    for i=0, length*width-1 do
        local index = start_index + i%length + math.floor(i/width)*GameRules.grid_width
        local tile = GameRules.GroundGrid[index]

        -- add the trap to the tile data
        if tile then tile.trap = entity_index end

        -- update the nettable value for this tile
        CustomNetTables:SetTableValue("ground_grid", ""..index, tile)
    end
end

function GameMode:RemoveTrapFromGrid(entity_index)
    for index, info in pairs(GameRules.GroundGrid) do
        if info.trap == entity_index then
            info.trap = nil
            CustomNetTables:SetTableValue("ground_grid", ""..index, info)
        end
    end
end

-- find clear space for units in a box
function GameMode:UnstickUnitsInBox(position, length, width)
    length, width = math.ceil(length), math.ceil(width)
    position = GameMode:SnapBoxToGrid2D(position, length, width)
    local start_index = GameMode:GetGridIndex(position - Vector(length*32, width*32, 0) + Vector(32, 32, 0))

    -- starting at the lower left corner, find clear space for any units in each tile of the box
    for i=0, length*width-1 do
        local tile_pos = GameMode:GetGridPosition(start_index + i%length + math.floor(i/width)*GameRules.grid_width)

        local ents = Entities:FindAllInSphere(tile_pos, 45.3)  -- 45.3 being the diagonal of a 64x64 sized tile
        for _, ent in pairs(ents) do
            -- make sure it's an npc, and exclude traps
            if ent.IsDeniable ~= nil and not GameRules.npc_traps[ent:GetUnitName()] then FindClearSpaceForUnit(ent, ent:GetAbsOrigin(), true) end
        end
    end
end


----------------------------------------------
--                  Misc                    --
----------------------------------------------
function GameMode:CreatePortalParticles()
    for team, portal_ids in pairs(GameRules.team_portals) do
        for _, portal_id in pairs(portal_ids) do
            local portal = EntIndexToHScript(portal_id)
            if portal then
                local part = ParticleManager:CreateParticle("particles/portal/portal.vpcf", PATTACH_CUSTOMORIGIN, nil)
                ParticleManager:SetParticleControl(part, 0, portal:GetAbsOrigin())
                portal.particle = part
            end
        end
    end
end