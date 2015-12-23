---------------------------------------------------------------------------
-- Setup for team information
---------------------------------------------------------------------------
function SetupTeams( team_table, default_lives )
	-- list of teams specific to this map
    local valid_teams = {}
    for _, pStart in pairs(Entities:FindAllByClassname("info_player_start_dota")) do
        if IsPlayerTeam(pStart:GetTeam()) then valid_teams[pStart:GetTeam()]=true end
    end

    -- if valid_teams is out of bounds, use default radiant/dire
    if TableCount(valid_teams) < 1 or 10 < TableCount(valid_teams) then
        valid_teams = { DOTA_TEAM_GOODGUYS=true, DOTA_TEAM_BADGUYS=true }
    end

	-- populate team_table with useful information
	for team, _ in pairs(valid_teams) do
		team_table[team] = { 
			lives        = default_lives,
			portals      = Entities:FindAllByName("Portal_"..team),
			creep_spawns = Entities:FindAllByName("Spawn_"..team),
			creeps       = {}
		}
	end
end

function IsPlayerTeam( teamID )
    if  teamID == DOTA_TEAM_GOODGUYS or teamID == DOTA_TEAM_BADGUYS or teamID >= DOTA_TEAM_CUSTOM_MIN and teamID <= DOTA_TEAM_CUSTOM_MAX then
        return true end
    return false
end

function GetTotalPlayers()
    local totalPlayers = 0
    local addoninfo = LoadKeyValues("addoninfo.txt")

    if addoninfo[GetMapName()] ~= nil and addoninfo[GetMapName()].MaxPlayers ~= nil then
        totalPlayers = addoninfo[GetMapName()].MaxPlayers
    end
    if totalPlayers < 1 or 24 < totalPlayers then totalPlayers = 10 end

    return totalPlayers
end

---------------------------------------------------------------------------
-- Modify creep table
---------------------------------------------------------------------------
function AddCreep( creep_table, cname, cowner, crate, ccount, citems )
    local ccount = ccount or 1
    local citems = citems  -- or nil

    -- test parameters
    if type(creep_table) ~= "table"  then return end
    if type(cname)       ~= "string" then return end
    if type(cowner)      ~= "number" then return end
    if type(crate)       ~= "number" then return end

    -- test the creep
    local test_creep = CreateUnitByName(cname, Vector(0,0,-1024), false, nil, nil, DOTA_TEAM_NOTEAM)
    if test_creep == nil then return end
    test_creep:Kill(nil, nil)

    -- check if there's a creep with these attributes already
    local creep_to_modify = nil
    for _, creep in pairs(creep_table) do
        -- if all of these components match for this creep, set this creep as our 'creep to modify'
        if creep.name == cname and creep.owner == cowner and creep.rate == crate then
            -- no items for either creep
            if type(citems) == "nil" and type(creep.items) == "nil" then
                creep_to_modify = creep
                break
            end
            -- both creeps have the same items
            if type(citems) == "table" and type(creep.items) == "table" and ShallowTableCompareLoose(citems, creep.items) then
                creep_to_modify = creep
                break
            end
        end
    end

    -- if we have a creep to modify, do that now, otherwise create a new creep
    if type(creep_to_modify) ~= "nil" then
        creep_to_modify.count = creep_to_modify.count + ccount
    else
        table.insert(creep_table, {
            name  = cname,
            owner = cowner,
            count = ccount,
            rate  = crate,
            items = citems,
            _incr = 0
        })
    end
end