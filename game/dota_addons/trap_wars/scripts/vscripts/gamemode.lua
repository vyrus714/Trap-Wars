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

    --[[
    TW_CREEPS = {  -- fixme
        {name="npc_dota_creep_goodguys_melee",  team=DOTA_TEAM_GOODGUYS, count=2, rate=8},
        {name="npc_dota_creep_goodguys_ranged", team=DOTA_TEAM_GOODGUYS, count=1, rate=8, items={"item_ring_of_basilius"}},
        {name="npc_dota_creep_badguys_melee",  team=DOTA_TEAM_BADGUYS, count=2, rate=8},
        {name="npc_dota_creep_badguys_ranged", team=DOTA_TEAM_BADGUYS, count=1, rate=8, items={"item_ring_of_basilius"}}
    } ]]

    -- send the table information to our table: "trap_wars_info"
    --CustomNetTables:SetTableValue("trap_wars_info", "spawners", spawners)
    --CustomNetTables:SetTableValue("trap_wars_info", "portals", portals)
end

function GameMode:OnGameInProgress()
    --Spawners:SpawnCreepsOnInterval(CreepSpawners, 0, 10)
    --CreepSpawnThinker(TW_CREEPS)
    for team, info in pairs(TW_TEAMS) do
        AddCreep(info.creeps, "npc_dota_creep_goodguys_melee", 0, 10, 1)
        AddCreep(info.creeps, "npc_dota_creep_goodguys_ranged", 0, 10, 1, {"item_ring_of_basilius"})
        CreepSpawnThinker(info.creeps, info.creep_spawns, team)
    end

    FireGameEvent( "show_center_message", {message="Begin!", duration=3} )
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

-- this updates the score and determines win/loss
function GameMode:OnTrapWarsScoreUpdated(keys)
    -- keys.team           team id #
    -- keys.delta_score    desired change in score
    if not keys.team or not keys.delta_score then return end
    if not TW_TEAMS[keys.team] then return end

    -- change the score
    TW_TEAMS[keys.team].lives = TW_TEAMS[keys.team].lives + keys.delta_score

    -- check game conditions   <- FIXME, won't work for more than 2 teams
    if TW_TEAMS[keys.team].lives < 1 then
        TW_TEAMS[keys.team].lives = 0
        GameRules:SetSafeToLeave(true)
        if keys.team == DOTA_TEAM_GOODGUYS then          -- FIXME, see above, need to implement per-team loss that won't end game
            GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
        else 
            GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
        end
    end

    -- update the scoreboard  <- FIXME, still only works for 2 teams (radient/dire), need to write custom scoreboard
    GameRules:GetGameModeEntity():SetTopBarTeamValue(keys.team, TW_TEAMS[keys.team].lives)
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