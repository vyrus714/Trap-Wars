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
        -- get player info once so we don't do this for every index
        local player_info = {}
        for pid, _ in pairs(GameRules.valid_players) do
            local hero = PlayerResource:GetSelectedHeroEntity(pid)

            if hero then
                player_info[pid] = {
                    team = PlayerResource:GetTeam(pid),
                    pos  = hero:GetAbsOrigin()
                }
            end
        end

        -- go through every grid square and check if it's a claimable plot
        for index, info in pairs(GameRules.GroundGrid) do
            -- if this plot is claimable, and isn't claimed already
            if info.plot and not GameRules.Plots[info.plot] then
                local grid_pos = GameMode:GetGridPosition(index)

                -- go through each player and see if they're in this plot
                for pid, pinfo in pairs(player_info) do
                    if info.team == pinfo.team and (grid_pos-pinfo.pos):Length2D() < 45 then
                        -- claim the grid plot
                        GameRules.Plots[info.plot] = pid
                        CustomNetTables:SetTableValue("plots", ""..info.plot, {pid=GameRules.Plots[info.plot]})

                        break;
                    end
                end
            end
        end

        return 1/30
    end)
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
                    local length = 2
                    local width  = 2

                    DebugDrawSphere(position, Vector(255, 0, 0), 1.0, 10, true, 1/10) 
                    DebugDrawBox(GameMode:SnapToGrid2D(position), Vector(-32, -32, 0), Vector(32, 32, 0), 0, 128, 0, 0.75, 1/10)
                    DebugDrawBox(GameMode:SnapBoxToGrid2D(position, length, width), Vector(-32, -32, 0), Vector(32, 32, 0), 255, 0, 0, 0.75, 1/10)

                    if GameMode:CanPlayerBuildHere(pid, position, length, width) then
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
    CustomNetTables:SetTableValue("player_creeps", ""..pid, GameRules.player_creeps[pid])
    ]]
end

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