-- function state object
if GameMode == nil then
    GameMode = class({})
    GameRules.GameMode = GameMode
end

-- libraries
require('libraries/util')
require('libraries/timers')
require('libraries/attachments')
-- game functions
require('game/info')
require('game/traps')
-- main game logic
require('gamemode')


function GameMode:InitGameMode()
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
    GameRules.valid_teams      = Info:GetValidTeams()
    --GameRules.valid_players  FIXME, do this? yes no?

    ---------------------------------------------
    -- Player Specific Values | key = playerid --
    ---------------------------------------------
    GameRules.player_colors = {}  -- filled when the player gets their playerid, detected in GameMode:OnPlayerTeam() below
    GameRules.player_grids  = {}  -- store grids per-player ala vvvv  FIXME
    GameRules.player_creeps = {}  -- store creeps per-player, rather than a jumbled mess per team  FIXME

    ----------------------------------------------
    -- Team Specific Values | key = team number --
    ----------------------------------------------
    GameRules.team_lives       = {}
    GameRules.team_portals     = {}
    GameRules.team_spawners    = {}
    GameRules.team_shared_grid = {}
    GameRules.team_open_grids  = {}

    -- fill up those tables with info
    for team, _ in pairs(GameRules.valid_teams) do
        GameRules.team_lives       [team] = GameRules.default_lives
        GameRules.team_portals     [team] = Entities:FindAllByName("Portal_"..team)
        GameRules.team_spawners    [team] = Entities:FindAllByName("Spawn_"..team)
        GameRules.team_shared_grid [team] = Info:GetSharedGrid(team)
        GameRules.team_open_grids  [team] = Info:GetUnclaimedGrids(team)
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

    -- set the max players for each team (rounds down if given an odd # of players for the map)
    local max_players = math.floor(Info:GetTotalPlayers() / Util:TableCount(GameRules.valid_teams))
    for team, _ in pairs(GameRules.valid_teams) do 
        GameRules:SetCustomGameTeamMaxPlayers(team, max_players)
    end

    ------------------------------
    -- Setup specific Listeners --
    ------------------------------
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnPlayerConnectFull'), self)
    ListenToGameEvent('player_team', Dynamic_Wrap(GameMode, 'OnPlayerTeam'), self)
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)

    ------------------------
    -- GameMode Listeners --
    ------------------------
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
    ListenToGameEvent("trapwars_score_update", Dynamic_Wrap(GameMode, 'OnTrapWarsScoreUpdated'), self)
    CustomGameEventManager:RegisterListener("trapwars_modify_dummy", Dynamic_Wrap(GameMode, 'OnTrapWarsModifyDummy'))

    CustomGameEventManager:RegisterListener("test_button", Dynamic_Wrap(GameMode, 'OnTestButton'))  -- FIXME TESTING


    -- setup complete, continue in the gamemode file
    print('[Trap Wars] Setup Complete.')
    GameMode:OnInitGameMode()
end

---------------------------------------------------------------------------
-- Listener Functions
---------------------------------------------------------------------------

function GameMode:OnPlayerConnectFull()
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
end

-- called when a player joins\changes teams - bots result with a pid of -1, very annoying
function GameMode:OnPlayerTeam(keys)
    -- the player in question
    local player = PlayerInstanceFromIndex(keys.userid)
    -- if (for some reason) it's not actually a player, gtfo
    if not player:IsPlayer() then return end
    -- get the player id
    local pid = player:GetPlayerID()


    -- only execute this the first time they join a team: basically on connect, when they get their PID
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
        --print("setting player "..pid.."'s color to: ("..red.." "..green.." "..blue..")")
        -- set the player's color
        PlayerResource:SetCustomPlayerColor(pid, red, green, blue)
        -- add color to GameRules.player_colors
        GameRules.player_colors[pid] = Vector(red, green, blue)
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