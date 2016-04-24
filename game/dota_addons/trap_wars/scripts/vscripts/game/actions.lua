local GameMode = GameRules.GameMode

function GameMode:SpawnTrap( position, trap_name, player_id )  -- FIXME: setup integer-based return values for feedback
	-- valid player ?
	if not PlayerResource:IsValidTeamPlayer(player_id) then print("1") return false end
	local team, hero = PlayerResource:GetTeam(player_id), PlayerResource:GetPlayer(player_id):GetAssignedHero() or nil

	-- buildable tile for this player?
	if not GameMode:IsInPlayersGrid(position, player_id) and not GameMode:IsInSharedGrid(position, team) then print("2") return false end
	-- make sure there isn't a trap in this tile already
	if GameMode:IsBuildingInTile(position) then print("3") return false end
	-- check if trap name is valid
	if GameRules.npc_traps[trap_name] == nil then return false end


	-- plonk trap
	local trap = CreateUnitByName(trap_name, GameMode:Get2DGridCenter(position), false, nil, hero, team)
	-- add modifiers to the trap (if it has them)
	if GameRules.npc_traps[trap_name].modifiers ~= nil then
		for _, modifier in pairs(GameRules.npc_traps[trap_name].modifiers) do
			trap:AddNewModifier(nil, nil, modifier, {}) 
		end
	end
	-- if this trap isn't phased, move any units out of it
	if not trap:HasModifier("modifier_phased") then GameMode:UnstuckUnitsInTile(position) end


	-- well we made it
	return true
end