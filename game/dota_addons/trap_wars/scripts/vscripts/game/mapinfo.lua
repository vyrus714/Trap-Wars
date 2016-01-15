-- wrap utility functions in a class to avoid name issues
if Info == nil then
    Info = class({})
end

---------------------------------------------------------------------------
-- Setup for team information
---------------------------------------------------------------------------
function Info:SetupTeams( default_lives )
	-- list of teams specific to this map
    local valid_teams = {}
    for _, pStart in pairs(Entities:FindAllByClassname("info_player_start_dota")) do
        if Info:IsPlayerTeam(pStart:GetTeam()) then valid_teams[pStart:GetTeam()]=true end
    end

    -- if valid_teams is out of bounds, use default radiant/dire
    if Util:TableCount(valid_teams) < 1 or 10 < Util:TableCount(valid_teams) then
        valid_teams = { DOTA_TEAM_GOODGUYS=true, DOTA_TEAM_BADGUYS=true }
    end

	-- populate team_table with useful information
    local team_table = {}
	for team, _ in pairs(valid_teams) do
        -- find grids for each team
        local found_grids = {
            unclaimed = {},
            claimed   = {},
            shared    = Entities:FindAllByName("Grid_"..team)
        }
        Info:GetGridOutline(found_grids.shared)
        for i=1, DOTA_MAX_TEAM do
            local temp = Entities:FindAllByName("Grid_"..team.."_"..i)
            if type(temp) ~= nil and 0 < Util:TableCount(temp) then
                found_grids.unclaimed[i] = temp
                Info:GetGridOutline(found_grids.unclaimed[i])
            end
        end

        -- team info
		team_table[team] = { 
			lives            = default_lives,
			portals          = Entities:FindAllByName("Portal_"..team),
			creep_spawns     = Entities:FindAllByName("Spawn_"..team),
            grids            = found_grids,
            max_player_grids = 1, -- FIXME ?just a default value, need to implement this functionality somewhere
			creeps           = {}
		}
	end

    -- output value
    return team_table
end

---------------------------------------------------------------------------
-- some general team info functions
---------------------------------------------------------------------------
function Info:IsPlayerTeam( teamID )
    if  teamID == DOTA_TEAM_GOODGUYS   or  teamID == DOTA_TEAM_BADGUYS or
        teamID >= DOTA_TEAM_CUSTOM_MIN and teamID <= DOTA_TEAM_CUSTOM_MAX then return true end
    return false
end

function Info:GetTotalPlayers()
    local totalPlayers = 0
    local addoninfo = LoadKeyValues("addoninfo.txt")

    if addoninfo[GetMapName()] ~= nil and addoninfo[GetMapName()].MaxPlayers ~= nil then
        totalPlayers = addoninfo[GetMapName()].MaxPlayers
    end
    if totalPlayers < 1 or 24 < totalPlayers then totalPlayers = 10 end

    return totalPlayers
end

---------------------------------------------------------------------------
-- grid table functions
---------------------------------------------------------------------------
function Info:ClaimGrid( team_grids, grid_key, player_id )
    -- make sure the info given is good
    if  type(team_grids.claimed)   ~= "table" or type(grid_key)  ~= "number" or
        type(team_grids.unclaimed) ~= "table" or type(player_id) ~= "number" then return end

    -- create the player's table if it doesn't exist
    if not team_grids.claimed[player_id] then team_grids.claimed[player_id]={} end

    -- add the grid to the player's table
    table.insert(team_grids.claimed[player_id], team_grids.unclaimed[grid_key])

    -- remove the grid from the unclaimed table
    table.remove(team_grids.unclaimed, grid_key)
end

function Info:UnClaimGrid( team_grids, grid_key, player_id )
    -- make sure the info given is good
    if  type(team_grids.claimed)   ~= "table" or type(grid_key)  ~= "number" or
        type(team_grids.unclaimed) ~= "table" or type(player_id) ~= "number" then return end

    -- add the grid to the unclaimed table
    table.insert(team_grids.unclaimed, team_grids.claimed[player_id][grid_key])

    -- remove the grid from the player's table
    table.remove(team_grids.claimed[player_id], grid_key)
end

--local function IsInEntity(point, entity) end
function Info:IsInGrid(point, grid)
    local min = grid:GetBoundingMins() + grid:GetAbsOrigin()
    local max = grid:GetBoundingMaxs() + grid:GetAbsOrigin()
    max.z = min.z

    if  min.x <= point.x and point.x <= max.x and
        min.y <= point.y and point.y <= max.y then return true end
    return false
end

function Info:GetGridOutline( grid )
    for _, ent in pairs(grid) do
        local center, max, min = ent:GetAbsOrigin(), ent:GetBoundingMaxs(), ent:GetBoundingMins()
        max.z = min.z

        ent.lines = {}
        local lines = {
            {start=center+max*Vector(-1,1,1), stop=center+max},
            {start=center+max*Vector(1,-1,1), stop=center+max},
            {start=center+min, stop=center+min*Vector(-1,1,1)},
            {start=center+min, stop=center+min*Vector(1,-1,1)}
        }

        for _, line in pairs(lines) do
            local dx = math.floor(0.5+(line.stop.x-line.start.x))
            local dy = math.floor(0.5+(line.stop.y-line.start.y))
            local slope = dy/dx

            local iter, usex = 0, true
            if math.abs(dx) > math.abs(dy) then
                iter = math.abs(dx)
            else
                iter = math.abs(dy)
                usex = false
            end

            local lstart, point, drawing = line.start, line.stop, false
            for j=0, iter-1 do
                -- find the point on the line
                if usex then
                    point = Vector(line.start.x+j, j*slope+line.start.y, line.start.z)
                else
                    if slope == 1/0 or slope == -1/0 then
                        point = Vector(line.start.x, line.start.y+j, line.start.z)
                    else
                        point = Vector(j/slope+line.start.x, line.start.y+j, line.start.z)
                    end
                end

                -- are we in any other boxes?
                local in_ent = false
                for _, g in pairs(grid) do
                    if not in_ent and g ~= ent then
                        if Info:IsInGrid(point, g) then in_ent = true end
                    end
                end

                -- if we're drawing a line, stop on in_ent | if not, start on !in_ent
                if drawing then
                    if in_ent or j == iter-1 then
                        drawing = false
                        table.insert(ent.lines, {start=lstart, stop=point})
                    end
                else
                    if not in_ent then
                        drawing = true
                        lstart = point
                    end
                end
            end
        end
    end
end

function Info:DrawGridLines( team_table )
    for _, team in pairs(team_table) do
        -- shared grids
        Info:DrawGridLine(team.grids.shared, Vector(0, 0, 0))
        -- unclaimed grids
        for _, grid in pairs(team.grids.unclaimed) do
            Info:DrawGridLine(grid, Vector(255, 255, 255))
        end
        -- claimed grids
        for player_id, grid in pairs(team.grids.claimed) do
            Info:DrawGridLine(grid, PlayerResource:GetPlayer(player_id):GetCustomPlayerColor())  -- FIXME valve declined to give us this function
        end
    end
end

function Info:DrawGridLine( grid, color )
    if type(grid.particles) ~= "table" then grid.particles={} end

    for _, ent in pairs(grid) do
        if type(ent.lines) == "table" then
            for _, line in pairs(ent.lines) do
                local part = ParticleManager:CreateParticle("particles/line.vpcf", PATTACH_WORLDORIGIN, nil)
                ParticleManager:SetParticleControl(part, 0, line.start)
                ParticleManager:SetParticleControl(part, 1, line.stop)
                ParticleManager:SetParticleControl(part, 2, color)
                table.insert(grid.particles, part)

                --DebugDrawLine(line.start+Vector(0,0,8), line.stop+Vector(0,0,8), color.x, color.y, color.z, false, -1)
            end
        end
    end
end

---------------------------------------------------------------------------
-- creep table functions
---------------------------------------------------------------------------
function Info:AddCreep( creep_table, cname, cowner, crate, ccount, citems )
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
            if type(citems) == "table" and type(creep.items) == "table" and Util:ShallowTableCompareLoose(citems, creep.items) then
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