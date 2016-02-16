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
        found_grids.shared.lines = Info:GetGridOutline(found_grids.shared)
        for i=1, DOTA_MAX_TEAM do
            local temp = Entities:FindAllByName("Grid_"..team.."_"..i)
            if type(temp) ~= nil and 0 < Util:TableCount(temp) then
                found_grids.unclaimed[i] = temp
                found_grids.unclaimed[i].lines = Info:GetGridOutline(found_grids.unclaimed[i])
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
-- Per-Player Grid Functions -- if i ever get around to it i'll rename this, since it's slightly(majorly) confusing FIXME
---------------------------------------------------------------------------
function Info:IsInEntity(point, entity)
    local min = entity:GetBoundingMins() + entity:GetAbsOrigin()
    local max = entity:GetBoundingMaxs() + entity:GetAbsOrigin()
    max.z = min.z

    if  min.x <= point.x and point.x <= max.x and
        min.y <= point.y and point.y <= max.y then return true end
    return false
end

function Info:IsInGrid(point, grid)
    for i=1, #grid do
        if Info:IsInEntity(point, grid[i]) then return true end
    end
    return false
end

function Info:GetGridOutline( grid )
    local grid_lines = {}

    for _, ent in pairs(grid) do
        local center, max, min = ent:GetAbsOrigin(), ent:GetBoundingMaxs(), ent:GetBoundingMins()
        max.z = min.z

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
                        if Info:IsInEntity(point, g) then in_ent = true end
                    end
                end

                -- if we're drawing a line, stop on in_ent | if not, start on !in_ent
                if drawing then
                    if in_ent or j == iter-1 then
                        drawing = false
                        table.insert(grid_lines, {start=lstart, stop=point})
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

    return grid_lines
end

---------------------------------------------------------------------------
-- Universal Grid Functions -- universal grid will be 128x128 per tile centered at (0, 0, 0)
---------------------------------------------------------------------------
local tile = 128

-- the absolute center of the nearest grid tile to _position_
function Info:GetGridCenter( position )
    return Vector(   math.floor((position.x+tile/2)/tile)*tile,
                     math.floor((position.y+tile/2)/tile)*tile,
                    (math.floor(position.z/tile)+0.5)    *tile  )
end

-- x and y are centered, z is floored for practicality
function Info:Get2DGridCenter( position )
    return Vector(  math.floor((position.x+tile/2)/tile)*tile,
                    math.floor((position.y+tile/2)/tile)*tile,
                    math.floor(position.z/tile)         *tile  )
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