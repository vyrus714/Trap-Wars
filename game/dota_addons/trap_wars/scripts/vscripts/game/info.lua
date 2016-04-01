-- wrap utility functions in a class to avoid naming issues
if Info == nil then
    Info = class({})
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

-- list of teams specific to this map
function Info:GetValidTeams()
    -- find teams based on the player start points in the map
    local valid_teams = {}
    for _, pstart in pairs(Entities:FindAllByClassname("info_player_start_dota")) do
        if Info:IsPlayerTeam(pstart:GetTeam()) then valid_teams[pstart:GetTeam()]=true end
    end

    -- if valid_teams is out of bounds, use default radiant/dire
    if Util:TableCount(valid_teams) < 1 or 10 < Util:TableCount(valid_teams) then
        valid_teams = { DOTA_TEAM_GOODGUYS=true, DOTA_TEAM_BADGUYS=true }
    end

    return valid_teams
end

function Info:GetSharedGrid( team )
    local grid = Entities:FindAllByName("Grid_"..team)
    --grid.lines = Info:GetGridOutline(grid)
    grid.lines = Info:GetGridOutlineNew(grid)

    return grid
end

function Info:GetUnclaimedGrids( team )
    local grids = {}

    for i=1, DOTA_MAX_TEAM do  -- max # of players per team            -- FIXME: ok, why is this assuming 1 grid max per player total?
        local grid = Entities:FindAllByName("Grid_"..team.."_"..i)    -- FIXME: ... ok, i rly need a better way of doing this
        if type(grid) == "table" and 0 < Util:TableCount(grid) then
            --grid.lines = Info:GetGridOutline(grid)
            grid.lines = Info:GetGridOutlineNew(grid)
            table.insert(grids, grid)
        end
    end

    return grids
end

---------------------------------------------------------------------------
-- Per-Player Grid Functions -- if i ever get around to it i'll rename this, since it's slightly(majorly) confusing FIXME
---------------------------------------------------------------------------
function Info:IsInEntity( point, entity )
    if entity == nil then return false end

    local min = entity:GetBoundingMins() + entity:GetAbsOrigin()
    local max = entity:GetBoundingMaxs() + entity:GetAbsOrigin()
    max.z = min.z

    if  min.x <= point.x and point.x <= max.x and
        min.y <= point.y and point.y <= max.y then return true end
    return false
end

function Info:IsInGrid( point, grid )
    for i=1, #grid do
        if Info:IsInEntity(point, grid[i]) then return true end
    end
    return false
end

-- this one relies on GameRules.player_grids
function Info:IsInPlayersGrid( point, player_id )
    if GameRules.player_grids[player_id] == nil then return false end

    for _, grid in pairs(GameRules.player_grids[player_id]) do
        if Info:IsInGrid(point, grid) then return true end
    end

    return false
end

-- this one relies on GameRules.team_shared_grid
function Info:IsInSharedGrid( point, team )  -- FIXME: remove this, it's redundant now that i stripped out the old shit
    if Info:IsInGrid(point, GameRules.team_shared_grid[team]) then return true end
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

function Info:GetBoundsOutline( ent )
    local min, max = ent:GetAbsOrigin()+ent:GetBoundingMins(), ent:GetAbsOrigin()+ent:GetBoundingMaxs()
    return {
        Vector(min.x, min.y, min.z),
        Vector(max.x, min.y, min.z),
        Vector(max.x, max.y, min.z),
        Vector(min.x, max.y, min.z)
    }
end

function Info:GetGridOutlineNew( grid )
    local grid_lines = {}

    for _, ent in pairs(grid) do
        local lines = Info:GetBoundsOutline(ent)

        for i, point in pairs(lines) do
            -- get the end point for this line
            local epoint = Vector(0, 0, 0)
            if i >= #lines then
                epoint = lines[1]
            else
                epoint = lines[i+1]
            end

            -- get the change in the x and y directions
            local dx, dy = epoint.x-point.x, epoint.y-point.y

            -- find out which direction we'll be moving
            local count = math.abs(dy)
            if dy == 0 then count=math.abs(dx) end
            count = math.floor(count+0.5)


            -- loop over every point on this line and create lines when we're on an empty (not touching another trigger ent) edge
            local drawing, start = false, point+0
            for j=0, count-1 do
                -- find the iteration point
                local ipoint = point+0
                if dy == 0 then
                    ipoint.x = point.x + j
                    if dx < 0 then ipoint.x=point.x-j end
                else
                    ipoint.y = point.y + j
                    if dy < 0 then ipoint.y=point.y-j end
                end

                -- are we touching another trigger entity?
                local touching = false
                for _, e in pairs(grid) do
                    if not touching and e ~= ent then
                        if Info:IsInEntity(ipoint, e) then touching=true end
                    end
                end

                -- if we're touching another trigger & drawing a line, stop drawing | if not either, start drawing
                if drawing then
                    if touching or j == count-1 then
                        drawing = false
                        table.insert(grid_lines, {start=start, stop=ipoint})
                    end
                else
                    if not touching then
                        drawing = true
                        start = ipoint+0
                    end
                end
            end
        end
    end

    return grid_lines
end

---------------------------------------------------------------------------
-- Universal Grid Functions -- tile size: 128^2 -- offset so one tile is centered on (0, 0, 0) to match hammer
---------------------------------------------------------------------------
local tile = 128
local diagonal = math.sqrt(tile*tile*2)  -- corner to corner distance

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

-- find all units whithin a tile
function Info:FindUnitsInTile( position )
    local position = Info:Get2DGridCenter(position)

    -- filter out non-npc entities, or entities not in the actual tile square
    local ents = Entities:FindAllInSphere(position, diagonal/2)
    for k, ent in pairs(ents) do
        local pos = ent:GetAbsOrigin()
        if ent.IsDeniable == nil or pos.x < position.x-tile/2 or pos.x > position.x+tile/2 or
                                    pos.y < position.y-tile/2 or pos.y > position.y+tile/2 then
            ent[k] = nil
        end
    end

    return ents
end

-- find all units not on _team_ within a tile
function Info:FindEnemyUnitsInTile( position, team )
    local units = Info:FindUnitsInTile(position)

    -- filter out units not in said team
    for k, unit in pairs(units) do
        if unit:GetTeam() ~= team then units[k]=nil end
    end

    return units
end

-- find clear space for units in a tile -- a bit around the tile, since it's cheaper
function Info:UnstuckUnitsInTile( position )  -- FIXME: this is not an INFORMATION function, gtfo of this file you imposter!
    local position = Info:Get2DGridCenter(position)

    local ents = Entities:FindAllInSphere(position, diagonal/2)
    for _, ent in pairs(ents) do
        if ent.IsDeniable ~= nil then FindClearSpaceForUnit(ent, ent:GetAbsOrigin(), true) end
    end
end

-- is there an "npc_dota_building" in this tile?
function Info:IsBuildingInTile( position )
    if Entities:FindByClassnameWithin(nil, "npc_dota_building", Info:Get2DGridCenter(position), tile/2) == nil then return false end
    return true
end

---------------------------------------------------------------------------
-- creep table functions
---------------------------------------------------------------------------
function Info:AddCreep( creep_table, cname, cowner, crate, ccount, citems )  -- FIXME: this does not belong here, move to spawning.lua
    local ccount = ccount or 1
    local citems = citems  -- or nil

    -- test parameters
    if type(creep_table) ~= "table" or type(cname) ~= "string" or type(cowner) ~= "number" or type(crate) ~= "number" then return end

    -- test the creep
    if GameRules.npc_units_custom[cname] == nil then return end

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
    if creep_to_modify ~= nil then
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