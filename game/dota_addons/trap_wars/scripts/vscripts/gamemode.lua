function GameMode:OnInitGameMode()
    -- Get all the required information on each creep spawner and put it in a global table
    --CreepSpawners = Spawners:CreateSpawners()

    -- grid stuff
    --TileGrid = Grid:GetGridLocations()  -- get grid from the map
    --Grid:SendToJS( TileGrid, "all" )    -- send the grid to the UI

    --[[
    for k,grid in pairs(TileGrid) do
        DebugDrawLine_vCol(grid.start, grid.start+Vector(0,grid.stop.y-grid.start.y,0), Vector(0,255,0), true, -1)
        DebugDrawLine_vCol(grid.start, grid.start+Vector(grid.stop.x-grid.start.x,0,0), Vector(0,255,0), true, -1)
        DebugDrawLine_vCol(grid.stop, grid.stop+Vector(0,grid.start.y-grid.stop.y,0), Vector(0,255,0), true, -1)
        DebugDrawLine_vCol(grid.stop, grid.stop+Vector(grid.start.x-grid.stop.x,0,0), Vector(0,255,0), true, -1)
    end
    ]]

    local temp = Entities:FindAllByName("Spawn_Good")
    for k,v in pairs(temp) do  table.insert(TW_SPAWNERS[DOTA_TEAM_GOODGUYS], v:GetAbsOrigin())  end

    temp = Entities:FindAllByName("Spawn_Bad")
    for k,v in pairs(temp) do  table.insert(TW_SPAWNERS[DOTA_TEAM_BADGUYS], v:GetAbsOrigin())  end

    TW_PORTALS = {
        [DOTA_TEAM_GOODGUYS] = Entities:FindByName(nil, "Portal_Good"):GetAbsOrigin(),
        [DOTA_TEAM_BADGUYS]  = Entities:FindByName(nil, "Portal_Bad"):GetAbsOrigin()
    }
    TW_CREEPS = {
        {name="npc_dota_creep_goodguys_melee", team=DOTA_TEAM_GOODGUYS, count=2, rate=8},
        {name="npc_dota_creep_goodguys_ranged", team=DOTA_TEAM_GOODGUYS, count=1, rate=8, items={"item_ring_of_basilius"}},
        {name="npc_dota_creep_badguys_melee", team=DOTA_TEAM_BADGUYS, count=2, rate=8},
        {name="npc_dota_creep_badguys_ranged", team=DOTA_TEAM_BADGUYS, count=1, rate=8, items={"item_ring_of_basilius"}}
    }

    -- send the table information to our table: "trap_wars_info"
    --CustomNetTables:SetTableValue("trap_wars_info", "spawners", spawners)
    --CustomNetTables:SetTableValue("trap_wars_info", "portals", portals)
end

function GameMode:OnGameInProgress()
    --Spawners:SpawnCreepsOnInterval(CreepSpawners, 0, 10)
    CreepSpawnThinker(TW_CREEPS)
    

end

function GameMode:OnNPCSpawned(keys)
    local npc = EntIndexToHScript(keys.entindex)

    if npc:IsRealHero() and npc.bFirstSpawned == nil then
        npc.bFirstSpawned = true
        GameMode:OnHeroInGame(npc)
    end
end

function GameMode:OnHeroInGame(hero)
    --[[ grid stuff
    local ent = SpawnEntityFromTableSynchronous("prop_dynamic", {
        origin = Vector(0, 0, 0),
        model  = "models/items/alchemist/alchemeyerflask/alchemeyerflask.vmdl",
        angles = Vector(0, 0, 0)
    })
    Timers:CreateTimer(function()
        local gridpos = Grid:GetCenter( hero:GetAbsOrigin(), TileGrid )
        if gridpos then
            ent:SetAbsOrigin(gridpos+Vector(0, 0, 256))
            DebugDrawBox(gridpos+Vector(0,0,0), Vector(-64,-64,0), Vector(64,64,0), 0, 255, 0, 12, 0.4)
            DebugDrawText(Vector(0,0,0), ent:GetAbsOrigin():__tostring(), true, 0.1)
        end
        return 0.1
    end)

    -- dummy unit for each client's ui
    Grid:SendDummyToJS( hero:GetPlayerID() )  ]]

    -- gimme da $$
    hero:AddItemByName("item_force_staff")
    hero:AddItemByName("item_blink")
    hero:AddItemByName("item_ultimate_scepter")
end

function GameMode:OnTrapWarsScoreUpdated(keys)
    -- keys.team           team id #
    -- keys.delta_score    desired change in score
    if not keys.team or not keys.delta_score then return end

    if keys.team == DOTA_TEAM_GOODGUYS then
        TEAM_LIVES_GOOD = TEAM_LIVES_GOOD + keys.delta_score
        if TEAM_LIVES_GOOD < 1 then
            TEAM_LIVES_GOOD = 0
            GameRules:SetSafeToLeave(true)
            GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
        end
        GameRules:GetGameModeEntity():SetTopBarTeamValue(keys.team, TEAM_LIVES_GOOD)
    elseif keys.team == DOTA_TEAM_BADGUYS then
        TEAM_LIVES_BAD = TEAM_LIVES_BAD + keys.delta_score
        if TEAM_LIVES_BAD < 1 then
            TEAM_LIVES_BAD = 0
            GameRules:SetSafeToLeave( true )
            GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
        end
        GameRules:GetGameModeEntity():SetTopBarTeamValue(keys.team, TEAM_LIVES_BAD)
    end
end

-- modify some player's dummy unit
function GameMode:OnTrapWarsModifyDummy(keys)
    if not keys.entid then return end             -- no entity id, no deal
    
    local entity = EntIndexToHScript(keys.entid)  -- no entity BY that id? also no deal!
    if not entity then return end
    
    if keys.model then                            -- changing model
        entity:SetModel(keys.model)
    end
    
    if keys.angle then                            -- changing angle (pitch)
        local a = entity:GetAngles()
        entity:SetAngles( a.x, a.y+keys.angle, a.z )
    end
end