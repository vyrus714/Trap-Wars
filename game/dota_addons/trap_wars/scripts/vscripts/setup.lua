-- Global Variables - either set to a static value, or initialized to be set in InitGameMode()
TW_TEAMS  = {}
TW_CREEPS = {}

TW_DEFAULT_LIVES = 50  -- BALANCE


-- global function wrapper
if GameMode == nil then
    GameMode = class({})
end

function GameMode:InitGameMode()
    print('[Trap Wars] Setting up Game Mode')

    -- set up teams
    SetupTeams(TW_TEAMS, TW_DEFAULT_LIVES)
    local max_players  = math.floor(GetTotalPlayers() / TableCount(TW_TEAMS))
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
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)

    -- gamemode file listener functions
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
    ListenToGameEvent("trapwars_score_update", Dynamic_Wrap(GameMode, 'OnTrapWarsScoreUpdated'), self)
    CustomGameEventManager:RegisterListener("trapwars_modify_dummy", Dynamic_Wrap(GameMode, 'OnTrapWarsModifyDummy'))

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