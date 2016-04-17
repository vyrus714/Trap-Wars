local GameMode = GameRules.GameMode

function GameMode:SetupGameMode()
    print('[Trap Wars] Setting up Game Mode ...')

    ---------------------------
    -- Unit and Ability Data --
    ---------------------------
    --GameRules.npc_abilities_custom = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")  FIXME: need this? likely no
    GameRules.npc_units_custom     = LoadKeyValues("scripts/npc/npc_units_custom.txt")

    -- parse out unit names from GameRules.npc_units_custom into three specific types | only store the unit name, for data use ^^
    GameRules.npc_herocreeps = {}  -- npc_trapwars_herocreep_
    GameRules.npc_traps      = {}  -- npc_trapwars_trap_
    GameRules.npc_lanecreeps = {}  -- npc_trapwars_lanecreep_

    for name, info in pairs(GameRules.npc_units_custom) do
        if string.match(name, '^npc_trapwars_herocreep_.-') == "npc_trapwars_herocreep_" then table.insert(GameRules.npc_herocreeps, name)
        elseif string.match(name, '^npc_trapwars_trap_.-') == "npc_trapwars_trap_" then table.insert(GameRules.npc_traps, name)
        elseif string.match(name, '^npc_trapwars_lanecreep_.-') == "npc_trapwars_lanecreep_" then
            local level = GameRules.npc_units_custom[name].Level
            if GameRules.npc_lanecreeps[level] == nil then GameRules.npc_lanecreeps[level]={} end
            table.insert(GameRules.npc_lanecreeps[level], name)
        else end
    end

    -- precache the lane creeps now, the traps and hero creeps can be done on-use since we don't know how many of them will be used
    for _, creeps in pairs(GameRules.npc_lanecreeps) do
        for _, name in pairs(creeps) do
            GameRules.npc_units_custom[name]._IsPrecached = true
            PrecacheUnitByNameAsync(name, function()end)
        end
    end

    -----------------------
    -- Generic Variables --
    -----------------------
    GameRules.max_player_grids = 1 -- FIXME: perhaps add some map\player variability to this
    GameRules.default_lives    = 50
    GameRules.valid_teams      = GameMode:GetValidTeams()

    GameRules.UserIDPlayerID   = {}  -- for associating userid's and playerid's for event handling; in OnPlayerConnectFull()

    ---------------------------------------------
    -- Player Specific Values | key = playerid --
    ---------------------------------------------
    GameRules.valid_players = {}  -- filled when players join teams in OnPlayerTeam()
    GameRules.player_colors = {}  -- filled when players first connect in OnPlayerConnectFull()
    GameRules.player_grids  = {}  -- store grids per-player ala vvvv  FIXME
    GameRules.player_creeps = {}  -- store creeps per-player, rather than a jumbled mess per team  FIXME

    ----------------------------------------------
    -- Team Specific Values | key = team number --
    ----------------------------------------------
    GameRules.team_lives       = {}
    GameRules.team_spawners    = {}
    GameRules.team_portals     = {}
    GameRules.team_shared_grid = {}
    GameRules.team_open_grids  = {}

    -- fill up those tables with info
    for team, _ in pairs(GameRules.valid_teams) do
        GameRules.team_lives      [team] = GameRules.default_lives
        GameRules.team_spawners   [team] = GameMode:GetSpawners(team)
        GameRules.team_shared_grid[team] = GameMode:GetSharedGrid(team)
        GameRules.team_open_grids [team] = GameMode:GetUnclaimedGrids(team)  -- FIXME: give this a nettable\move drawing clientside?

        Timers:CreateTimer(1, function() GameRules.team_portals[team] = GameMode:GetPortals(team) end) -- doesn't like making particles so early

        -- set net table initial values for the stuff we're using above here
        CustomNetTables:SetTableValue("trapwars_team_shared_grid", ""..team, GameRules.team_shared_grid[team]) -- FIXME: sending full unit handle, bad!
        CustomNetTables:SetTableValue("trapwars_team_scores", ""..team, {GameRules.team_lives[team]})
    end

    ----------------
    -- Game Rules --
    ----------------
    GameRules:SetHeroSelectionTime(20)
    GameRules:SetPreGameTime(10)       -- FIXME
    GameRules:SetPostGameTime(60)
    GameRules:SetTreeRegrowTime(60)
    GameRules:SetGoldPerTick(3)        -- BALANCE
    GameRules:SetGoldTickTime(5)       -- BALANCE
    GameRules:SetUseUniversalShopMode(true)
    GameRules:SetHeroMinimapIconScale(1)
    GameRules:SetCreepMinimapIconScale(1)
    GameRules:SetStartingGold(10000)   -- FIXME

    local GameModeEntity = GameRules:GetGameModeEntity()
    GameModeEntity:SetFogOfWarDisabled(true)
    GameModeEntity:SetCameraDistanceOverride(1337)
    --GameModeEntity:SetCustomBuybackCostEnabled(true)
    --GameModeEntity:SetCustomBuybackCooldownEnabled(true)
    GameModeEntity:SetFixedRespawnTime(20.0)  -- BALANCE
    --GameModeEntity:SetTopBarTeamValuesVisible(true)
    GameModeEntity:SetTopBarTeamValuesOverride(true)  -- FIXME
    GameModeEntity:SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, GameRules.default_lives)  -- FIXME
    GameModeEntity:SetTopBarTeamValue(DOTA_TEAM_BADGUYS, GameRules.default_lives)  -- FIXME

    -- set the max players for each team (rounds down if given an odd # of players for the map)
    local max_players = math.floor(GameMode:GetTotalPlayers() / Util:TableCount(GameRules.valid_teams))
    for team, _ in pairs(GameRules.valid_teams) do 
        GameRules:SetCustomGameTeamMaxPlayers(team, max_players)
    end

    ----------------------------------
    -- Initialize Static Net Tables --
    ----------------------------------
    -- tables set on a one-time-only basis at the start of the game
    CustomNetTables:SetTableValue("trapwars_static_info", "valid_teams", GameRules.valid_teams)
    CustomNetTables:SetTableValue("trapwars_static_info", "vars",        {default_lives=GameRules.default_lives})

    for key, value in pairs(GameRules.npc_herocreeps) do
        if GameRules.npc_units_custom[value] then
            CustomNetTables:SetTableValue("trapwars_npc_herocreeps", value, GameRules.npc_units_custom[value])
        end
    end
    for key, value in pairs(GameRules.npc_traps) do
        if GameRules.npc_units_custom[value] then
            CustomNetTables:SetTableValue("trapwars_npc_traps", value, GameRules.npc_units_custom[value])
        end
    end

    -- other, changing, net tables each get their own table, so the values can update independantly
    -- these are listed here for reference, even though they are set\updated elsewhere
    -- "trapwars_team_shared_grid", "team_id", GameRules.team_shared_grid[team]  forget what that is
    -- "trapwars_team_scores", "team_id", {int}
    -- "trapwars_valid_players", "pid", {boolean}
    -- "trapwars_player_colors", "pid", {vector}
    -- "trapwars_player_grids", "pid", grid tables  --FIXME: implement

    ------------------------
    -- Register Listeners --
    ------------------------
    -- setup file functions
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnPlayerConnectFull'), self)
    ListenToGameEvent('player_team', Dynamic_Wrap(GameMode, 'OnPlayerTeam'), self)
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)
    --gamemode file functions
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
    ListenToGameEvent("trapwars_score_update", Dynamic_Wrap(GameMode, 'OnTrapWarsScoreUpdated'), self)
    CustomGameEventManager:RegisterListener("test_button", Dynamic_Wrap(GameMode, 'OnTestButton'))  -- FIXME TESTING


    print('[Trap Wars] Setup Complete.')
end

-------------------------------
-- Setup Listener Functions  --
-------------------------------

function GameMode:OnPlayerConnectFull(keys)
    local player = EntIndexToHScript(keys.index+1)

    -- delay one frame so we get an accurate player id
    Timers:CreateTimer(function()
        local pid = player:GetPlayerID()

        -- when a player connects, store their userid and playerid so we can associate the two elsewhere
        GameRules.UserIDPlayerID[keys.userid] = pid

        -- functions executed only on a player's first join
        if not player._firstJoin then
            player._firstJoin = true

            -- for each player that connects, give them a random color and store it in GameRules.player_colors
            local red, green, blue = 255, 255, 255
            -- attempt to find a suitable color 100 times before giving up and returning white
            for i=1, 100 do
                local r, g, b = RandomInt(0, 255), RandomInt(0, 255), RandomInt(0, 255)

                local valid = true
                for _, color in pairs(GameRules.player_colors) do
                    if 102 < math.abs(color.x-r) and 102 < math.abs(color.y-g) and 102 < math.abs(color.z-b) then valid=false end
                end

                if valid then
                    red, green, blue = r, g, b
                    break
                end
            end

            -- set the player's color and add it to GameRules.player_colors to keep track of it
            PlayerResource:SetCustomPlayerColor(pid, red, green, blue)
            GameRules.player_colors[pid] = Vector(red, green, blue)
            
            -- add the value to the net table "trapwars_player_colors", "pid", {vector}
            CustomNetTables:SetTableValue("trapwars_player_colors", ""..pid, {Vector(red, green, blue)})
        end
    end)
end

-- called when a player joins\changes teams - bots result with a pid of -1, very annoying
function GameMode:OnPlayerTeam(keys)
    local pid = GameRules.UserIDPlayerID[keys.userid]

    -- if the team is a playing-team (not spectators etc) then add to GameRules.valid_players
    if keys.team >= DOTA_TEAM_FIRST and keys.team <= DOTA_TEAM_CUSTOM_MAX and keys.team ~= DOTA_TEAM_NEUTRALS and keys.team ~= DOTA_TEAM_NOTEAM then
            GameRules.valid_players[pid] = true
            CustomNetTables:SetTableValue("trapwars_valid_players", ""..pid, {true})
    elseif CustomNetTables:GetTableValue("trapwars_valid_players", ""..pid)[1] == true then
        GameRules.valid_players[pid] = nil  -- make sure they are removed if they exit a valid team
        CustomNetTables:SetTableValue("trapwars_valid_players", ""..pid, nil)
    end
end

function GameMode:OnGameRulesStateChange(keys)
    local newState = GameRules:State_Get()
    if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
        self.bSeenWaitForPlayers = true
    elseif newState == DOTA_GAMERULES_STATE_INIT then
        --Timers:RemoveTimer("alljointimer")
    elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
        --GameMode:PostLoadPrecache()
        --GameMode:OnAllPlayersLoaded()
    elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        GameMode:OnGameInProgress()
    end
end