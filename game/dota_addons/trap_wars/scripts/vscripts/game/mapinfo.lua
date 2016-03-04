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

---------------------------------------------------------------------------
-- Per-Player Grid Functions -- if i ever get around to it i'll rename this, since it's slightly(majorly) confusing FIXME
---------------------------------------------------------------------------
function Info:IsInEntity( point, entity )
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

-- this one relies on the global info in GameRules.teams
function Info:IsInPlayersGrid( point, player_id )
    local team = PlayerResource:GetTeam(player_id)
    if  GameRules.teams[team] == nil or GameRules.teams[team].grids == nil or GameRules.teams[team].grids.claimed == nil or
        GameRules.teams[team].grids.claimed[player_id] == nil then return false end

    for _, grid in pairs(GameRules.teams[team].grids.claimed[player_id]) do
        if Info:IsInGrid(point, grid) then return true end
    end

    return false
end

-- as does this one
function Info:IsInSharedGrid( point, team )
    if GameRules.teams[team] == nil or GameRules.teams[team].grids == nil or GameRules.teams[team].grids.shared == nil then return false end
    if Info:IsInGrid(point, GameRules.teams[team].grids.shared) then return true end
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
function Info:UnstuckUnitsInTile( position )
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