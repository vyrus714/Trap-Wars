-- Global Variables - either set to a static value, or initialized to be set in InitGameMode()
TW_TEAMS = {}
TW_PLAYER_COLORS = {}
TW_DEFAULT_LIVES = 50  -- BALANCE


-- global function wrapper
if GameMode == nil then
    GameMode = class({})
end

function GameMode:InitGameMode()
    print('[Trap Wars] Setting up Game Mode')

    -- team info
    TW_TEAMS = Info:SetupTeams(TW_DEFAULT_LIVES)

    -- set the max players for each team (rounds down)
    local max_players = math.floor(Info:GetTotalPlayers() / Util:TableCount(TW_TEAMS))
    for team, _ in pairs(TW_TEAMS) do 
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
    GameModeEntity:SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, TW_DEFAULT_LIVES)  -- FIXME
    GameModeEntity:SetTopBarTeamValue(DOTA_TEAM_BADGUYS, TW_DEFAULT_LIVES)  -- FIXME
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

        -- for each player that connects, give them a random color and store it in TW_PLAYER_COLORS
        local red, green, blue = 255, 255, 255
        -- attempt to find a suitable color 100 times before giving up and returning white
        for i=1, 100 do
            local r, g, b = RandomInt(0, 255), RandomInt(0, 255), RandomInt(0, 255)

            local valid = true
            for _, color in pairs(TW_PLAYER_COLORS) do
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
        -- add color to TW_PLAYER_COLORS
        TW_PLAYER_COLORS[pid] = Vector(red, green, blue)
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