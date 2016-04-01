function GameMode:OnInitGameMode()
    print('[Trap Wars] Setting up game logic ...')
    --Util:PrintTable(GameRules.team_open_grids)
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
                        if grid[i]:IsTouching(hero) then touching=true end
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
                    DebugDrawBox(Info:Get2DGridCenter(position), Vector(-64, -64, 0), Vector(64, 64, 0), 0, 128, 0, 0.75, 1/10)
                    DebugDrawSphere(Info:GetGridCenter(position), Vector(0, 0, 128), 0.75, 20, true, 1/10)
                    -- if in one of this player's grids, draw a schmansy sphere
                    if GameRules.player_grids[pid] ~= nil and Info:IsInPlayersGrid(position, pid) then
                        DebugDrawSphere(Info:GetGridCenter(position), Vector(128, 0, 0), 0.75, 24, true, 1/10)
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
    local level, pool, wave = 0, {}, {1}
    Timers:CreateTimer(function()
        local gameTime = math.floor(GameRules:GetDOTATime(false, false))

        -- every 2 minutes
        if gameTime % 240 == 0 then
            -- add a new slot to the creep wave
            wave[#wave+1] = true
        end

        -- every minute
        if gameTime % 60 == 0 then
            -- increase the creep level by 1 (cap at 18)
            if level < 18 then level=level+1 end
            -- recalculate the creep pool to include the current level + 5 levels under it
            pool = {}
            for i=0, 5 do
                if GameRules.npc_lanecreeps[level-i] ~= nil then
                    for _, name in pairs(GameRules.npc_lanecreeps[level-i]) do
                        table.insert(pool, name)
                    end
                end
            end
        end

        -- every 20 seconds
        if gameTime % 20 == 0 then
            -- get new random creep wave
            for key, _ in pairs(wave) do
                -- add a random creep from the available pool to the creep wave
                wave[key] = pool[RandomInt(1, #pool)]
            end

            -- spawn creepwaves
            for team, spawners in pairs(GameRules.team_spawners) do
                for _, spawner in pairs(spawners) do
                    for _, name in pairs(wave) do
                        -- create the creep
                        local creep = CreateUnitByName(name, spawner:GetAbsOrigin(), true, nil, nil, team)
                        -- precache the unit (if it hasn't been already)
                        if GameRules.npc_units_custom[name]._IsPrecached == nil then
                            GameRules.npc_units_custom[name]._IsPrecached = true
                            PrecacheUnitByNameAsync(name, function()end)
                        end
                        -- add attachments
                        if GameRules.npc_units_custom[name].Attachments ~= nil then
                            for attach_point, models in pairs(GameRules.npc_units_custom[name].Attachments) do
                                for model, properties in pairs(models) do
                                    Attachments:AttachProp(creep, attach_point, model, properties.scale, properties)
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

        return 1  -- check every second, just to be sure
    end)

    ----------------------------------------------
    --              Creep Heroes                --
    ----------------------------------------------
    -- FIXME: todo


    FireGameEvent( "show_center_message", {message="Begin!", duration=3} )
end

function GameMode:OnNPCSpawned( keys )
    local npc = EntIndexToHScript(keys.entindex)

    -- when a hero first spawns
    if npc:IsRealHero() and npc.bFirstSpawned == nil then
        npc.bFirstSpawned = true

        npc:AddItemByName("item_force_staff")
        npc:AddItemByName("item_blink")
        npc:AddItemByName("item_ultimate_scepter")
    end
end

--[[ function GameMode:OnHeroInGame( hero )
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
function GameMode:OnTrapWarsScoreUpdated( keys )
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
function GameMode:OnTrapWarsModifyDummy( keys )
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
function GameMode:OnTestButton( keys )
    if keys.id == 1 then
        --print("LUA: "..keys.id)
        local hero = PlayerResource:GetPlayer(0):GetAssignedHero()
        local yesno = SpawnTrap(hero:GetAbsOrigin(), "npc_trapwars_trap_firevent", 0)
        --if yesno then print("trap spawned") else print("trap NOT spawned") end
    end
    --------------------
    if keys.id == 2 then
        --print("LUA: "..keys.id)
        local hero = PlayerResource:GetPlayer(0):GetAssignedHero()
        local yesno = SpawnTrap(hero:GetAbsOrigin(), "npc_trapwars_trap_spike", 0)
        --if yesno then print("trap spawned") else print("trap NOT spawned") end
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
        if GameRules.npc_units_custom[keys.unit] == nil then
            print(keys.unit, "not a valid creep name")
            return
        end

        local hero = PlayerResource:GetSelectedHeroEntity(0)
        local creep = CreateUnitByName(keys.unit, hero:GetAbsOrigin()+Vector(-100, 0, 0), true, hero, hero, hero:GetTeam())

        Timers:CreateTimer(0.03, function()
            if creep == nil then return end

            if GameRules.npc_units_custom[keys.unit].Attachments ~= nil then
                for attach_point, models in pairs(GameRules.npc_units_custom[keys.unit].Attachments) do
                    for model, properties in pairs(models) do
                        Attachments:AttachProp(creep, attach_point, model, properties.scale, properties)
                    end
                end
            end

            creep:SetControllableByPlayer(0, true)
        end)
    end
end