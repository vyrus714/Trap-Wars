local GameMode = GameRules.GameMode

function GameMode:SpawnTrap(name, position, team, owner)
    -- make sure this is a valid trap
    if not GameRules.npc_traps[name] then return nil end
    -- make sure there's no building here already
    if GameMode:IsBuildingInTile(position) then return nil end
    -- make sure it's a valid team
    if team < DOTA_TEAM_FIRST or DOTA_TEAM_CUSTOM_MAX < team then return end


    -- plonk trap
    local trap = CreateUnitByName(name, GameMode:Get2DGridCenter(position), false, nil, owner, team)

    -- add modifiers to the trap (if it has them)
    if GameRules.npc_traps[name].modifiers then
        for _, modifier in pairs(GameRules.npc_traps[name].modifiers) do
            trap:AddNewModifier(nil, nil, modifier, {}) 
        end
    end
    -- if this trap isn't phased, move any units out of it
    if not trap:HasModifier("modifier_phased") then GameMode:UnstuckUnitsInTile(position) end


    return trap
end

function GameMode:SpawnTrapForPlayer(name, position, playerid)
    -- make sure we were passed a valid player
    if not PlayerResource:IsValidTeamPlayer(playerid) then return end
    -- make sure the player is allowed to make a trap here
    if not GameMode:IsInPlayersGrid(position, playerid) and not GameMode:IsInSharedGrid(position, PlayerResource:GetTeam(playerid)) then return end


    -- create the trap
    return GameMode:SpawnTrap(name, position, PlayerResource:GetTeam(playerid), PlayerResource:GetSelectedHeroEntity(playerid))
end