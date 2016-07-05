local GameMode = GameRules.GameMode

-- libraries
require('libraries/util')
require('libraries/timers')
require('libraries/attachments')
-- game functions
require('game/setup')
require('game/information')
require('game/actions')

function GameMode:InitGameMode()
    -- load settings from the setup file
    GameMode:SetupGameMode()
                
    -- new grid claims
    Timers:CreateTimer(2/30, function()
        for index, info in pairs(GameRules.GroundGrid) do
            if type(index) == "number" and info.plot then
                -- check to see if someone's already claimed this grid plot  FIXME: turn this into an info function
                local claimed = nil
                for playerid, claims in pairs(GameRules.player_plots) do
                    -- make sure the player is on the right team
                    if PlayerResource:GetTeam(playerid) == info.team then
                        for _, claim in pairs(claims) do
                            if claim == info.plot then claimed = playerid end  -- FIXME: just use bool, this was for debug
                        end
                    end
                end

                if claimed == nil then
                    local grid_pos = GameMode:GetGridPosition(index)
                    for playerid, _ in pairs(GameRules.valid_players) do
                        if PlayerResource:GetTeam(playerid) == info.team then
                            local hero = PlayerResource:GetSelectedHeroEntity(playerid)
                            if hero then
                                local player_pos = hero:GetAbsOrigin()

                                if (grid_pos - player_pos):Length2D() < 45 then
                                    -- claim the grid plot
                                    if not GameRules.player_plots[playerid] then GameRules.player_plots[playerid] = {} end
                                    table.insert(GameRules.player_plots[playerid], info.plot)

                                    break;
                                end
                            end
                        end
                    end
                end
            end
        end

        return 1/30
    end)


    -- light up the grids  FIXME: update to particles, and only do the ones that can be claimed
    Timers:CreateTimer(2/30, function()
        for index, info in pairs(GameRules.GroundGrid) do
            if type(index) == "number" then
                -- check to see if someone's already claimed this grid plot  FIXME: turn this into an info function
                local claimed = nil
                for playerid, claims in pairs(GameRules.player_plots) do
                    -- make sure the player is on the right team
                    if PlayerResource:GetTeam(playerid) == info.team then
                        for _, claim in pairs(claims) do
                            if claim == info.plot then claimed = playerid end  -- FIXME: just use bool, this was for debug
                        end
                    end
                end
                
                if info.team then
                    local color
                    if info.team == DOTA_TEAM_GOODGUYS then color = Vector(0, 255, 0) end
                    if info.team == DOTA_TEAM_BADGUYS  then color = Vector(255, 0, 0) end
                    if claimed ~= nil then color = GameRules.player_colors[claimed] end
                    DebugDrawBoxDirection(GameMode:GetGridPosition(index), Vector(-30, -30, 0), Vector(30, 30, 1), Vector(0, 0, 0), color or Vector(64, 64, 64), 0.4, 4/30)
                end
            end
        end

        return 4/30
    end)


    -------------------------------------------------------------------
    -- Claiming / Drawing unclaimed grid areas
    -------------------------------------------------------------------
    local tick, ticks_to_claim = 0.5, 8
    Timers:CreateTimer(function()
        for team, _ in pairs(GameRules.valid_teams) do
            -- get players on this team
            local players = {}  -- key=playerid, value=hero entity handle
            for i=1, PlayerResource:GetPlayerCountForTeam(team) do
                local pid = PlayerResource:GetNthPlayerIDOnTeam(team, i)
                if PlayerResource:IsValidTeamPlayerID(pid) and PlayerResource:IsValidTeamPlayer(pid) then  -- yes, i am paranoid!
                    local player = PlayerResource:GetPlayer(pid)
                    if player ~= nil then
                        players[pid] = player:GetAssignedHero()
                    end
                end
            end

            -- update claim status for grids in the GameRules.team_open_grids table
            for grid_key, grid in pairs(GameRules.team_open_grids[team]) do
                -- on first loop for this grid:
                if grid.player_claims == nil then
                    -- make sure grid has claim table
                    grid.player_claims = {}
                    -- outline grid with particles
                    if grid.particles == nil then grid.particles={} end
                    for _, line in pairs(grid.lines) do
                        --[[local part = ParticleManager:CreateParticle("particles/line_stars_continuous.vpcf", PATTACH_CUSTOMORIGIN, nil)
                        ParticleManager:SetParticleControl(part, 0, line.start)
                        ParticleManager:SetParticleControl(part, 1, line.stop)
                        ParticleManager:SetParticleControl(part, 2, Vector(255, 255, 255))
                        ParticleManager:SetParticleControl(part, 3, Vector(math.ceil(Util:Distance(line.start, line.stop)*0.08), 0, 0))
                        table.insert(grid.particles, part)]]
                        part = ParticleManager:CreateParticle("particles/ui_mouseactions/bounding_area_view_a.vpcf", PATTACH_CUSTOMORIGIN, nil)
                        ParticleManager:SetParticleControl(part, 0, line.start)
                        ParticleManager:SetParticleControl(part, 1, line.stop)
                        ParticleManager:SetParticleControl(part, 15, Vector(255, 255, 255))
                        ParticleManager:SetParticleControl(part, 16, Vector(1, 0, 0))
                        table.insert(grid.particles, part)
                    end
                end

                -- loop through each entity in the grid and check if players{} are touching any
                for pid, hero in pairs(players) do
                    -- particle information
                    local theta = 2*math.pi/ticks_to_claim
                    local color = GameRules.player_colors[pid] or Vector(255, 255, 255)

                    -- are we touching this grid?
                    local touching = false
                    for i=1, #grid do
                        if EntIndexToHScript(grid[i]):IsTouching(hero) then touching=true end
                    end

                    -- update player's claims
                    if touching then
                        -- create or increment this player's claim
                        if grid.player_claims[pid] == nil then
                            -- create the claim
                            grid.player_claims[pid] = 1

                            -- particles
                            hero.claim_indicator_parts = {}
                            hero.claim_indicator_parts.base = ParticleManager:CreateParticle("particles/overhead_indicator_1.vpcf", PATTACH_OVERHEAD_FOLLOW, hero)
                            local part = ParticleManager:CreateParticle("particles/overhead_indicator_1_b.vpcf", PATTACH_OVERHEAD_FOLLOW, hero)
                            ParticleManager:SetParticleControl(part, 1, Vector(66*math.cos(theta*grid.player_claims[pid]+math.pi/4), 66*math.sin(theta*grid.player_claims[pid]+math.pi/4), 0))
                            ParticleManager:SetParticleControl(part, 2, color)
                            table.insert(hero.claim_indicator_parts, part)
                        else
                            -- increment
                            grid.player_claims[pid] = grid.player_claims[pid] + 1

                            -- particles
                            local part = ParticleManager:CreateParticle("particles/overhead_indicator_1_b.vpcf", PATTACH_OVERHEAD_FOLLOW, hero)
                            ParticleManager:SetParticleControl(part, 1, Vector(66*math.cos(theta*grid.player_claims[pid]+math.pi/4), 66*math.sin(theta*grid.player_claims[pid]+math.pi/4), 0))
                            ParticleManager:SetParticleControl(part, 2, color)
                            table.insert(hero.claim_indicator_parts, part)
                        end
                    else
                        -- if we aren't touching and have a claim status, decriment it
                        if grid.player_claims ~= nil and grid.player_claims[pid] ~= nil then
                            -- decriment
                            grid.player_claims[pid] = grid.player_claims[pid] - 1

                            -- particles
                            ParticleManager:DestroyParticle(hero.claim_indicator_parts[#hero.claim_indicator_parts], false)
                            ParticleManager:ReleaseParticleIndex(hero.claim_indicator_parts[#hero.claim_indicator_parts])
                            hero.claim_indicator_parts[#hero.claim_indicator_parts] = nil

                            -- if we are lower than the minimm, remove the claim and particles
                            if grid.player_claims[pid] < 1 then
                                -- claim
                                grid.player_claims[pid] = nil

                                -- particles
                                for _, part in pairs(hero.claim_indicator_parts) do
                                    ParticleManager:DestroyParticle(part, false)
                                    ParticleManager:ReleaseParticleIndex(part)
                                end
                                hero.claim_indicator_parts = nil
                            end
                        end
                    end

                    -- check claims-if someone wins: remove particles, set as winner, add particles, break from outer loop
                    if grid.player_claims[pid] ~= nil and ticks_to_claim+1 <= grid.player_claims[pid] then
                        -- remove all of the player's claim particles
                        for pid_temp, claim in pairs(grid.player_claims) do
                            -- this player's hero
                            local hero_temp = PlayerResource:GetPlayer(pid_temp):GetAssignedHero()

                            -- remove particles attached to it
                            for _, part in pairs(hero_temp.claim_indicator_parts) do
                                ParticleManager:DestroyParticle(part, false)
                                ParticleManager:ReleaseParticleIndex(part)
                            end
                            hero_temp.claim_indicator_parts = nil
                        end

                        -- remove the grid's outlining particles and claim table
                        for _, part in pairs(grid.particles) do
                            ParticleManager:DestroyParticle(part, false)
                            ParticleManager:ReleaseParticleIndex(part)
                        end
                        grid.particles = nil
                        grid.player_claims = nil

                        -- move the grid to this player's grid table
                        if not GameRules.player_grids[pid] then GameRules.player_grids[pid]={} end
                        table.insert(GameRules.player_grids[pid], grid)
                        table.remove(GameRules.team_open_grids[team], grid_key)

                        -- add some fancy particles: on the hero ...
                        --[[local part = ParticleManager:CreateParticle("particles/overhead_flame.vpcf", PATTACH_OVERHEAD_FOLLOW, hero)
                        ParticleManager:SetParticleControl(part, 2, color)]]
                        local part = ParticleManager:CreateParticle("particles/model_stars_continuous.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
                        ParticleManager:SetParticleControlEnt(part, 0, hero, PATTACH_POINT_FOLLOW, "attach_hitloc", hero:GetAbsOrigin(), true)
                        ParticleManager:SetParticleControl(part, 2, color)
                        -- and remove them
                        Timers:CreateTimer(8, function()
                            ParticleManager:DestroyParticle(part, false)
                            ParticleManager:ReleaseParticleIndex(part)
                        end)

                        -- add some fancy particles: on the grid:
                        local short_particles, long_particles = {}, {}
                        for _, line in pairs(grid.lines) do
                            -- shorter outline of the grid
                            local part = ParticleManager:CreateParticle("particles/line_stars_continuous.vpcf", PATTACH_CUSTOMORIGIN, nil)
                            ParticleManager:SetParticleControl(part, 0, line.start)
                            ParticleManager:SetParticleControl(part, 1, line.stop)
                            ParticleManager:SetParticleControl(part, 2, color)
                            ParticleManager:SetParticleControl(part, 3, Vector(math.ceil(Util:Distance(line.start, line.stop)*0.08), 0, 0))
                            --[[local part = ParticleManager:CreateParticle("particles/ui_mouseactions/bounding_area_view_a.vpcf", PATTACH_CUSTOMORIGIN, nil)
                            ParticleManager:SetParticleControl(part, 0, line.start)
                            ParticleManager:SetParticleControl(part, 1, line.stop)
                            ParticleManager:SetParticleControl(part, 15, color)
                            ParticleManager:SetParticleControl(part, 16, Vector(1, 0, 0))]]
                            table.insert(short_particles, part)

                            -- longer starburst particles
                            --[[part = ParticleManager:CreateParticle("particles/line_stars_burst.vpcf", PATTACH_CUSTOMORIGIN, nil)
                            ParticleManager:SetParticleControl(part, 0, line.start)
                            ParticleManager:SetParticleControl(part, 1, line.stop)
                            ParticleManager:SetParticleControl(part, 2, color)
                            ParticleManager:SetParticleControl(part, 3, Vector(math.ceil(Util:Distance(line.start, line.stop)*0.08), 0, 0))
                            table.insert(long_particles, part)]]
                        end
                        -- and remove them
                        Timers:CreateTimer(2, function()
                            for _, part in pairs(short_particles) do
                                ParticleManager:DestroyParticle(part, false)
                                ParticleManager:ReleaseParticleIndex(part)
                            end
                        end)
                        Timers:CreateTimer(12, function()
                            for _, part in pairs(long_particles) do
                                ParticleManager:DestroyParticle(part, false)
                                ParticleManager:ReleaseParticleIndex(part)
                            end
                        end)

                        -- break from player-check loop and continue checking other grids
                        break
                    end
                end
            end
        end
        return tick
    end)
    -------------------------------------------------------------------
end

function GameMode:OnGameInProgress()
    print('[Trap Wars] Game logic started.')

    -- FIXME: remove this shitty debug thing  --
    Timers:CreateTimer(function()
        for team, _ in pairs(GameRules.valid_teams) do
            -- get players on this team
            local players = {}  -- key=playerid, value=hero entity handle
            for i=1, PlayerResource:GetPlayerCountForTeam(team) do
                local pid = PlayerResource:GetNthPlayerIDOnTeam(team, i)
                if PlayerResource:IsValidTeamPlayerID(pid) and PlayerResource:IsValidTeamPlayer(pid) then  -- yes, i am paranoid!
                    players[pid] = PlayerResource:GetSelectedHeroEntity(pid)
                end
            end

            for pid, hero in pairs(players) do
                local position = hero:GetAbsOrigin()
                if position ~= nil then
                    -- draw some chmansy debug lines
                    DebugDrawBox(GameMode:SnapToGrid2D(position), Vector(-32, -32, 0), Vector(32, 32, 0), 0, 128, 0, 0.75, 1/10)
                    --DebugDrawSphere(GameMode:SnapToGrid2D(position)+Vector(0, 0, 32), Vector(0, 0, 128), 0.75, 20, true, 1/10)
                    -- if in one of this player's grids, draw a schmansy sphere
                    if GameRules.player_grids[pid] ~= nil and GameMode:IsInPlayersGrid(position, pid) then
                        --DebugDrawSphere(GameMode:SnapToGrid2D(position)+Vector(0, 0, 32), Vector(128, 0, 0), 0.75, 24, true, 1/10)
                    end

                    local length = 2
                    local width  = 2
                    if GameMode:CanTrapGoHere(position, length, width) then
                        DebugDrawBox(GameMode:SnapBoxToGrid2D(position, length, width), Vector(-length*32, -width*32, 0), Vector(length*32, width*32, 0), 0, 255, 0, 0.75, 1/10)
                    else
                        DebugDrawBox(GameMode:SnapBoxToGrid2D(position, length, width), Vector(-length*32, -width*32, 0), Vector(length*32, width*32, 0), 255, 0, 0, 0.75, 1/10)
                    end
                end
            end
        end

        return 1/10
    end)
    ----------------------------------------------


    ----------------------------------------------
    --               Creep Waves                --
    ----------------------------------------------
    local CreepLevel = 1
    local SpawnDelay = 8
    local DelaySpacer = 0

    Timers:CreateTimer(function()
        -- get a random delay time between 0.55 - 1.45 times the current SpawnDelay
        local actual_delay = SpawnDelay * RandomFloat(0.55, 1.45)
        local left_over_time = SpawnDelay - actual_delay
        actual_delay = actual_delay + DelaySpacer
        DelaySpacer = left_over_time

        -- over 30 minutes scale the creep level and delay between creep spawns
        local GameTime = math.floor(GameRules:GetDOTATime(false, false))
        if GameTime < 1800 then
            CreepLevel = math.floor(GameTime/120) + 1
            SpawnDelay = 8 - (6/1800)*GameTime
        else
            if CreepLevel ~= 16 then CreepLevel=16 end
            if SpawnDelay ~= 2 then SpawnDelay=2 end
        end

        -- spawn the creeps
        GameMode:SpawnLaneCreeps(CreepLevel-5, CreepLevel)

        return actual_delay
    end)

    ----------------------------------------------
    --              Creep Heroes                --
    ----------------------------------------------
    -- FIXME: todo


    FireGameEvent( "show_center_message", {message="Begin!", duration=3} )
end

function GameMode:OnNPCSpawned(keys)
    local npc = EntIndexToHScript(keys.entindex)

    -- when a hero first spawns
    if npc:IsRealHero() and npc.bFirstSpawned == nil then
        npc.bFirstSpawned = true

        npc:AddItemByName("item_force_staff")
        npc:AddItemByName("item_blink")
        npc:AddItemByName("item_ultimate_scepter")
    end
end

function GameMode:OnEntityKilled(keys)
    local entity = EntIndexToHScript(keys.entindex_killed)

    -- if it is a derivative of CDOTA_BaseNPC
    if entity.GetUnitName then
        -- if it's a trap
        if GameRules.npc_traps[entity:GetUnitName()] then
            -- remove the trap from the grid
            GameMode:RemoveTrapFromGrid(keys.entindex_killed)

            -- traps will mostly be removed via the ui, so they need to be removed faster than normal
            -- for traps that do have health, particles will be used in place of death animations anyway
            Timers:CreateTimer(1, function()  -- give any other functions 1 second to refer to this, then remove it
                entity:RemoveSelf()
            end)
        end
    end
end

function GameMode:OnBuyTrap(keys)
    -- if the position is a JS array, convert to a Vector()
    if type(keys.position) == "table" then keys.position = Vector(keys.position["0"], keys.position["1"], keys.position["2"]) end

    -- run some tests to make sure we can buy this trap
    local success = true
    local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)


    -- only allow trap buying when the player is alive
    if not hero:IsAlive() then success = false end

    -- check if the player is within range of the tile they're trying to sell on
    if GameRules.build_distance < (GameMode:SnapToGrid2D(keys.position) - hero:GetAbsOrigin()):Length2D() then success = false end

    -- make sure the player can afford this trap
    local cost
    if GameRules.npc_traps[keys.name] then cost = GameRules.npc_traps[keys.name].GoldCost end
    if cost and PlayerResource:GetGold(keys.playerid) < cost then success = false end


    -- if we're allowed to make the trap
    if success then
        -- attempt to spawn the trap
        local trap = GameMode:SpawnTrapForPlayer(keys.name, keys.position, keys.playerid)

        -- if (and only if) we made the trap, spend the gold and return
        if trap then
            -- remove gold
            if cost then PlayerResource:SpendGold(keys.playerid, cost, DOTA_ModifyGold_PurchaseItem) end
            -- play success sound
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(keys.playerid), "trapwars_sound_event", {sound="General.Buy"})
            -- exit
            return
        end
    end

    -- we're not allowed, or trap creation failed  -  play failure sound
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(keys.playerid), "trapwars_sound_event", {sound="General.Cancel"})
end

function GameMode:OnSellTrap(keys)    -- FIXME: perhaps find the trap id in JS, then send a table of entity ids, that way it can be extended to multiple-sell events
    -- get the trap
    local trap = EntIndexToHScript(keys.entindex)
    local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
    local success = true


    -- only allow trap selling when the player is alive
    if not hero:IsAlive() then success=false end

    -- make sure we actually got an entity at all
    if not trap then
        success=false
    else
        -- make sure it's on the right team
        if trap:GetTeam() ~= PlayerResource:GetTeam(keys.playerid) then success=false end

        -- if it has an owner that isn't this player, don't sell the other person's shit
        if trap:GetPlayerOwner() and trap:GetPlayerOwnerID() ~= keys.playerid then success=false end

        -- check if the player is within range of the tile they're trying to sell on
        if GameRules.build_distance < (trap:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D() then success=false end
    end


    -- if all our tests were successful, and we have a trap on that tile, initiate sellback
    if success then
        -- give the player back 50% of the gold (FIXME: create a 10-second long sell-back)  -- FIXME: if\when upgrades are added, factor that in here as well
        PlayerResource:ModifyGold(keys.playerid, (GameRules.npc_traps[trap:GetUnitName()].GoldCost or 0)/2, false, DOTA_ModifyGold_SellItem)

        -- hide the trap
        trap:AddNoDraw()
        -- remove the trap
        trap:Kill(nil, nil)

        -- play the sound effect
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(keys.playerid), "trapwars_sound_event", {sound="General.Sell"})
        -- once extended to multiple trap sell events, use this if the table is >1
        --CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(keys.playerid), "trapwars_sound_event", {sound="General.CoinsBig"})
    else
        -- we're not allowed, or didn't find the trap  -  play failure sound
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(keys.playerid), "trapwars_sound_event", {sound="General.Cancel"})
    end
end

function GameMode:OnBuyCreep(keys)
    --[[
    if GameRules.npc_herocreeps[keys.item]

    -- if there is no slot given, or given a used slot, return
    if not keys.slot or GameRules.player_creeps[keys.playerID][keys.slot] ~= 0 then return end
    -- if said slot is out-of-bounds (no cheating!), return
    if keys.slot < 1 or GameRules.max_player_creeps < keys.slot then return end

    -- add this creep to said slot
    GameRules.player_creeps[keys.PlayerID][keys.slot] = keys.item

    -- update the nettable
    CustomNetTables:SetTableValue("trapwars_player_creeps", ""..pid, GameRules.player_creeps[pid])
    ]]
end

--[[ function GameMode:OnHeroInGame( hero )  FIXME: remove whatever the hell this was
    --grid stuff
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
    Grid:SendDummyToJS( hero:GetPlayerID() )
end  ]]

-- this updates the score and determines win/loss
function GameMode:OnTrapWarsScoreUpdated(keys)  --FIXME: remove this as well
    if true then return end  -- FIXME disabled the win condition for testing
    -- keys.team           team id #
    -- keys.delta_score    desired change in score
    if not keys.team or not keys.delta_score then return end  -- if there's no team or score to change
    if not GameRules.valid_teams[keys.team] then return end  -- if this team isn't valid

    -- change the score
    GameRules.team_lives[keys.team] = GameRules.team_lives[keys.team] + keys.delta_score

    -- check game conditions   <- FIXME, won't work for more than 2 teams
    if GameRules.team_lives[keys.team] < 1 then
        GameRules.team_lives[keys.team] = 0
        GameRules:SetSafeToLeave(true)
        if keys.team == DOTA_TEAM_GOODGUYS then  -- FIXME, see above, need to implement per-team loss that won't end game
            GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
        else 
            GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
        end
    end

    -- update the scoreboard  <- FIXME, still only works for 2 teams (radient/dire), need to write custom scoreboard
    GameRules:GetGameModeEntity():SetTopBarTeamValue(keys.team, GameRules.team_lives[keys.team])
end

-- modify some player's dummy unit
function GameMode:OnTrapWarsModifyDummy(keys)  --FIXME: remove, not using (probably)
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

-- FIXME test function when test panel buttons are pressed
function GameMode:OnTestButton(keys)
    if keys.id == 1 then
        --print("LUA: "..keys.id)
        local hero = PlayerResource:GetSelectedHeroEntity(0)
        GameMode:OnBuyTrap{name="npc_trapwars_fire_vent", position=hero:GetAbsOrigin(), playerid=0}
    end
    --------------------
    if keys.id == 2 then
        --print("LUA: "..keys.id)
        local hero = PlayerResource:GetSelectedHeroEntity(0)
        GameMode:OnBuyTrap{name="npc_trapwars_wood_fence", position=hero:GetAbsOrigin(), playerid=0}
    end
    --------------------
    if keys.id == 3 then
        print("LUA: "..keys.id)
    end
    --------------------
    if keys.id == 4 then
        print("LUA: "..keys.id)
    end
    --------------------

    if keys.id == 5 and keys.unit ~= nil then
        local info = {}
        if GameRules.npc_herocreeps[keys.unit] ~= nil then
            info = GameRules.npc_herocreeps[keys.unit]
        elseif GameRules.npc_lanecreeps[keys.unit] ~= nil then
            info = GameRules.npc_lanecreeps[keys.unit]
        else
            print("\""..keys.unit.."\" is not a valid unit name!")
            return
        end

        local hero = PlayerResource:GetSelectedHeroEntity(0)
        local creep = CreateUnitByName(keys.unit, hero:GetAbsOrigin()+Vector(-100, 0, 0), true, hero, hero, hero:GetTeam())

        Timers:CreateTimer(0.03, function()
            if creep == nil then return end

            if info.Attachments ~= nil then
                for attach_point, models in pairs(info.Attachments) do
                    for model, properties in pairs(models) do
                        Attachments:AttachProp(creep, attach_point, model, properties.scale, properties)
                    end
                end
            end
            creep:SetControllableByPlayer(0, true)
        end)
    end
end