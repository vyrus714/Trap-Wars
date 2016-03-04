-- global variables, referred to in functions from the game folder
GameRules.npc_units_custom = {}
GameRules.npc_abilities_custom = {}

GameRules.teams = {}
GameRules.player_colors = {}
GameRules.default_lives = 50
GameRules.max_player_grids = 1 -- FIXME: perhaps add some map\player variability to this


-- function state object
if GameMode == nil then
    GameMode = class({})
    GameRules.GameMode = GameMode
end

-- libraries
require('libraries/util')
require('libraries/timers')
-- game functions
require('game/mapinfo')
require('game/spawning')
require('game/traps')
-- main game logic
require('gamemode')


function GameMode:InitGameMode()
    print('[Trap Wars] Setting up Game Mode')

    -- get the KV data from the npc_*_custom files
    GameRules.npc_units_custom = LoadKeyValues("scripts/npc/npc_units_custom.txt")
    GameRules.npc_abilities_custom = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")

    -- list of teams specific to this map
    local valid_teams = {}
    for _, pStart in pairs(Entities:FindAllByClassname("info_player_start_dota")) do
        if Info:IsPlayerTeam(pStart:GetTeam()) then valid_teams[pStart:GetTeam()]=true end
    end

    -- if valid_teams is out of bounds, use default radiant/dire
    if Util:TableCount(valid_teams) < 1 or 10 < Util:TableCount(valid_teams) then
        valid_teams = { DOTA_TEAM_GOODGUYS=true, DOTA_TEAM_BADGUYS=true }
    end

    -- populate GameRules.teams with useful information
    for team, _ in pairs(valid_teams) do
        -- find grids for each team
        local found_grids = {
            unclaimed = {},
            claimed   = {},
            shared    = Entities:FindAllByName("Grid_"..team)
        }
        found_grids.shared.lines = Info:GetGridOutline(found_grids.shared)
        for i=1, DOTA_MAX_TEAM do
            local temp = Entities:FindAllByName("Grid_"..team.."_"..i)
            if type(temp) ~= nil and 0 < Util:TableCount(temp) then
                found_grids.unclaimed[i] = temp
                found_grids.unclaimed[i].lines = Info:GetGridOutline(found_grids.unclaimed[i])
            end
        end

        -- team info
        GameRules.teams[team] = { 
            lives            = GameRules.default_lives,
            portals          = Entities:FindAllByName("Portal_"..team),
            creep_spawns     = Entities:FindAllByName("Spawn_"..team),
            grids            = found_grids,
            creeps           = {}
        }
    end

    -- set the max players for each team (rounds down)
    local max_players = math.floor(Info:GetTotalPlayers() / Util:TableCount(GameRules.teams))
    for team, _ in pairs(GameRules.teams) do 
        GameRules:SetCustomGameTeamMaxPlayers(team, max_players)
    end


    -- other game rules
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
    

    -- setup file listener functions
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnPlayerConnectFull'), self)
    ListenToGameEvent('player_team', Dynamic_Wrap(GameMode, 'OnPlayerTeam'), self)
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)

    -- gamemode file listener functions
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
    ListenToGameEvent("trapwars_score_update", Dynamic_Wrap(GameMode, 'OnTrapWarsScoreUpdated'), self)
    CustomGameEventManager:RegisterListener("trapwars_modify_dummy", Dynamic_Wrap(GameMode, 'OnTrapWarsModifyDummy'))

    CustomGameEventManager:RegisterListener("test_button", Dynamic_Wrap(GameMode, 'OnTestButton'))  -- FIXME TESTING


    -- continue in the gamemode file
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


    -- only execute this the first time they join a team
    if not player._hasJoined then
        player._hasJoined = true

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