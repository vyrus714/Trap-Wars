local GameMode = GameRules.GameMode

---------------------------------------------------------------------------
-- some general team info functions
---------------------------------------------------------------------------
function GameMode:IsPlayerTeam( teamID )
    if  teamID == DOTA_TEAM_GOODGUYS   or  teamID == DOTA_TEAM_BADGUYS or
        teamID >= DOTA_TEAM_CUSTOM_MIN and teamID <= DOTA_TEAM_CUSTOM_MAX then return true end
    return false
end

function GameMode:GetTotalPlayers()
    local totalPlayers = 0
    local addoninfo = LoadKeyValues("addoninfo.txt")

    if addoninfo[GetMapName()] ~= nil and addoninfo[GetMapName()].MaxPlayers ~= nil then
        totalPlayers = addoninfo[GetMapName()].MaxPlayers
    end
    if totalPlayers < 1 or 24 < totalPlayers then totalPlayers = 10 end

    return totalPlayers
end

-- list of teams specific to this map
function GameMode:GetValidTeams()
    -- find teams based on the player start points in the map
    local valid_teams = {}
    for _, pstart in pairs(Entities:FindAllByClassname("info_player_start_dota")) do
        if GameMode:IsPlayerTeam(pstart:GetTeam()) then valid_teams[pstart:GetTeam()]=true end
    end

    -- if valid_teams is out of bounds, use default radiant/dire
    if Util:TableCount(valid_teams) < 1 or 10 < Util:TableCount(valid_teams) then
        valid_teams = {[DOTA_TEAM_GOODGUYS]=true, [DOTA_TEAM_BADGUYS]=true}
    end

    return valid_teams
end

function GameMode:GetSpawners( team )
    local spawners = {}

    for _, ent in pairs(Entities:FindAllByName("Spawn_"..team)) do
        table.insert(spawners, ent:GetEntityIndex())
    end

    return spawners
end

function GameMode:GetPortals( team )
    local portals = {}

    for _, ent in pairs(Entities:FindAllByName("Portal_"..team)) do
        local portal = {}

        -- add the entity id
        portal.entindex = ent:GetEntityIndex()
        -- add the particles for this portal
        portal.particles = {}
        --local part = ParticleManager:CreateParticle("particles/econ/events/fall_major_2015/teleport_end_fallmjr_2015_lvl2.vpcf", PATTACH_CUSTOMORIGIN, nil)
        local part = ParticleManager:CreateParticle("particles/portal.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(part, 0, ent:GetAbsOrigin()+Vector(0,0,-80))
        --ParticleManager:SetParticleControl(part, 1, ent:GetAbsOrigin()+Vector(0,0,-100))
        table.insert(portal.particles, part)

        -- add portal to table
        table.insert(portals, portal)
    end

    return portals
end

function GameMode:GetSharedGrid( team )
    local grid = {}

    for _, ent in pairs(Entities:FindAllByName("Grid_"..team)) do
        table.insert(grid, ent:GetEntityIndex())
    end

    --grid.lines = GameMode:GetGridOutline(grid)
    grid.lines = GameMode:GetGridOutlineNew(grid)

    return grid
end

function GameMode:GetUnclaimedGrids( team )
    local grids = {}

    for i=1, DOTA_MAX_TEAM do  -- max # of players per team   -- FIXME: ok, why is this assuming 1 grid max per player total?
        -- find grid #i for _team_
        local grid = {}
        for _, ent in pairs(Entities:FindAllByName("Grid_"..team.."_"..i)) do
            table.insert(grid, ent:GetEntityIndex())
        end

        -- if the grid has entities in it, add the grid
        if 0 < #grid then
            --grid.lines = GameMode:GetGridOutline(grid)
            grid.lines = GameMode:GetGridOutlineNew(grid)
            table.insert(grids, grid)
        end
    end

    return grids
end

---------------------------------------------------------------------------
-- Per-Player Grid Functions -- if i ever get around to it i'll rename this, since it's slightly(majorly) confusing FIXME
---------------------------------------------------------------------------
function GameMode:IsInEntity( point, entity )
    if entity == nil then return false end

    local min = entity:GetBoundingMins() + entity:GetAbsOrigin()
    local max = entity:GetBoundingMaxs() + entity:GetAbsOrigin()
    max.z = min.z

    if  min.x <= point.x and point.x <= max.x and
        min.y <= point.y and point.y <= max.y then return true end
    return false
end

function GameMode:IsInGrid( point, grid )
    for i=1, #grid do
        if GameMode:IsInEntity(point, EntIndexToHScript(grid[i])) then return true end
    end
    return false
end

-- this one relies on GameRules.player_grids
function GameMode:IsInPlayersGrid( point, player_id )
    if GameRules.player_grids[player_id] == nil then return false end

    for _, grid in pairs(GameRules.player_grids[player_id]) do
        if GameMode:IsInGrid(point, grid) then return true end
    end

    return false
end

-- this one relies on GameRules.team_shared_grid
function GameMode:IsInSharedGrid( point, team )  -- FIXME: remove this, it's redundant now that i stripped out the old shit
    if GameMode:IsInGrid(point, GameRules.team_shared_grid[team]) then return true end
    return false
end

function GameMode:GetGridOutline( grid )
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
                        if GameMode:IsInEntity(point, g) then in_ent = true end
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

function GameMode:GetBoundsOutline( ent )
    local min, max = ent:GetAbsOrigin()+ent:GetBoundingMins(), ent:GetAbsOrigin()+ent:GetBoundingMaxs()
    return {
        Vector(min.x, min.y, min.z),
        Vector(max.x, min.y, min.z),
        Vector(max.x, max.y, min.z),
        Vector(min.x, max.y, min.z)
    }
end

function GameMode:GetGridOutlineNew( grid )
    local grid_lines = {}

    for _, entid in pairs(grid) do
        local ent = EntIndexToHScript(entid)
        local lines = GameMode:GetBoundsOutline(ent)

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
                for _, eid in pairs(grid) do
                    local e = EntIndexToHScript(eid)
                    if not touching and e ~= ent then
                        if GameMode:IsInEntity(ipoint, e) then touching=true end
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
-- FIXME: go over the math in these functions and see if we can switch to full vector operations
-- corner to corner distance
local function GetDiagonal()
    return math.sqrt(GameRules.TileSize*GameRules.TileSize*2)
end

-- the absolute center of the nearest grid tile to _position_
function GameMode:GetGridCenter( position )
    return Vector(   math.floor((position.x+GameRules.TileSize/2)/GameRules.TileSize)*GameRules.TileSize,
                     math.floor((position.y+GameRules.TileSize/2)/GameRules.TileSize)*GameRules.TileSize,
                    (math.floor(position.z/GameRules.TileSize)+0.5)                  *GameRules.TileSize  )
end

-- x and y are centered, z is floored for practicality
function GameMode:Get2DGridCenter( position )
    return Vector(  math.floor((position.x+GameRules.TileSize/2)/GameRules.TileSize)*GameRules.TileSize,
                    math.floor((position.y+GameRules.TileSize/2)/GameRules.TileSize)*GameRules.TileSize,
                    math.floor(position.z/GameRules.TileSize)                       *GameRules.TileSize  )
end

-- find all units whithin a tile
function GameMode:FindUnitsInTile( position )
    local position = GameMode:Get2DGridCenter(position)

    -- filter out non-npc entities, or entities not in the actual tile square
    local ents = Entities:FindAllInSphere(position, GetDiagonal()/2)
    for k, ent in pairs(ents) do
        local pos = ent:GetAbsOrigin()
        if ent.IsDeniable == nil or pos.x < position.x-GameRules.TileSize/2 or pos.x > position.x+GameRules.TileSize/2 or
                                    pos.y < position.y-GameRules.TileSize/2 or pos.y > position.y+GameRules.TileSize/2 then
            ent[k] = nil
        end
    end

    return ents
end

-- find all units not on _team_ within a tile
function GameMode:FindEnemyUnitsInTile( position, team )
    local units = GameMode:FindUnitsInTile(position)

    -- filter out units not in said team
    for k, unit in pairs(units) do
        if unit:GetTeam() ~= team then units[k]=nil end
    end

    return units
end

-- find clear space for units in a tile -- a bit around the tile, since it's cheaper
function GameMode:UnstuckUnitsInTile( position )  -- FIXME: this is not an INFORMATION function, gtfo of this file you imposter!
    local position = GameMode:Get2DGridCenter(position)

    local ents = Entities:FindAllInSphere(position, GetDiagonal()/2)
    for _, ent in pairs(ents) do
        if ent.IsDeniable ~= nil then FindClearSpaceForUnit(ent, ent:GetAbsOrigin(), true) end
    end
end

-- is there a trap in this tile?
function GameMode:IsATrapInTile( position )
    local entities = Entities:FindAllByClassnameWithin("npc_dota_creature", GameMode:Get2DGridCenter(position), GameRules.TileSize/2)
    for _, ent in pairs(entities) do
        if GameRules.npc_traps[ent:GetUnitName()] then return true end
    end

    return false
end


------------------------
-- New Grid Functions --GameRules.GroundGrid
------------------------
function GameMode:SnapToGrid2D(position)
    --return Vector(math.floor(position.x/64)*64+32, math.floor(position.y/64)*64+32, position.z)
    return Vector(position.x-(position.x%64)+32, position.y-(position.y%64)+32, position.z)
end

function GameMode:SnapToGround(position)
    position = GameMode:SnapToGrid2D(position)
    position.z = GetGroundHeight(position, nil)
    return position
end

function GameMode:SnapToAir(position)
    position = GameMode:SnapToGrid2D(position)
    position.z = GetGroundHeight(position, nil) + 128
    return position
end

function GameMode:SnapBoxToGrid2D(position, length, width)
    -- make sure we have a useable length and width (any overlap is counted as taking up that whole tile)
    length, width = math.ceil(length) or 1, math.ceil(width) or 1


    -- align the position of the center to the grid
    if length%2 ~= 0 then
        position.x = position.x-position.x%64+32
    else
        if position.x%64 > 32 then
            position.x = position.x-position.x%64+64
        else
            position.x = position.x-position.x%64
        end
    end

    if width%2 ~= 0 then
        position.y = position.y-position.y%64+32
    else
        if position.y%64 > 32 then
            position.y = position.y-position.y%64+64
        else
            position.y = position.y-position.y%64
        end
    end


    return position
end

function GameMode:GetGridArray()
    local gridnav = {}

    -- find all the pathable gridnav tiles (counting trees as unpathable\non-viable tiles)
    for i=0, GameRules.grid_length*GameRules.grid_width-1 do
        local pos = GameRules.grid_start + Vector(64*(i%GameRules.grid_length), 64*math.floor(i/GameRules.grid_width))
        pos = Vector(pos.x, pos.y, GetGroundHeight(pos, nil))

        if GridNav:IsTraversable(pos) and not GridNav:IsNearbyTree(pos, 1, true) then
            local info = {}
            
            -- get the markers from the map and extract their info. after that's done, remove them
            for _, marker in pairs(Entities:FindAllByNameWithin("plot_marker", pos, 32)) do
                info.team = marker:Attribute_GetIntValue("team", -1)
                info.plot = marker:Attribute_GetIntValue("plot", -1)

                for key, value in pairs(info) do
                    if value < 0 then info[key] = nil end
                end

                -- remove the marker
                marker:Kill()
            end
            -- FIXME: potentially add in the ground height of this tile, since javascript can't get it
            --info.height = pos.z

            -- push this info into the gridnav tile
            gridnav[i] = info
        end
    end

    return gridnav
end

function GameMode:GetGridPosition(index)
    local pos = GameRules.grid_start + Vector(64*(index%GameRules.grid_length), 64*math.floor(index/GameRules.grid_width))
    return Vector(pos.x, pos.y, GetGroundHeight(pos, nil))
end

function GameMode:GetGridIndex(position)
    local delta = Vector(position.x-(GameRules.grid_start.x-32), position.y-(GameRules.grid_start.y-32))

    -- if the passed position is below our min position, or above our max position (it's outside the map)
    if delta.x < 0 or delta.y < 0 or delta.x/64 > GameRules.grid_length or delta.y/64 > GameRules.grid_width then return nil end

    return math.floor(delta.x/64) + math.floor(delta.y/64)*GameRules.grid_length
end

function GameMode:CanTrapGoHere(position, length, width)
    length, width = math.ceil(length), math.ceil(width)
    position = GameMode:SnapBoxToGrid2D(position, length, width)
    local start_index = GameMode:GetGridIndex(position - Vector(length*32, width*32, 0) + Vector(32, 32, 0))

    -- starting at the lower left corner, iterate through the grid tiles in this box
    for i=0, length*width-1 do
        local index = start_index + i%length + math.floor(i/width)*GameRules.grid_length
        local tile = GameRules.GroundGrid[index]

        -- make sure there's no other trap here
        if not tile or (tile.trap and IsValidEntity(EntIndexToHScript(tile.trap))) then return false end  
    end

    return true
end

-- not really that accurate, since different teams can all have a plot of the same #, however i'm checking for teams separately anyway
function GameMode:DoesPlayerHavePlot(playerid, plot_number)
    if not GameRules.player_plots[playerid] then return false end

    for _, plot in pairs(GameRules.player_plots[playerid]) do
        if plot_number == plot then return true end
    end

    return false
end

function GameMode:CanPlayerBuildHere(playerid, position, length, width)
    length, width = math.ceil(length), math.ceil(width)
    position = GameMode:SnapBoxToGrid2D(position, length, width)
    local team = PlayerResource:GetTeam(playerid)
    local start_index = GameMode:GetGridIndex(position - Vector(length*32, width*32, 0) + Vector(32, 32, 0))

    -- starting at the lower left corner, iterate through the grid tiles in this box
    for i=0, length*width-1 do
        local index = start_index + i%length + math.floor(i/width)*GameRules.grid_length
        local tile = GameRules.GroundGrid[index]

        -- if we don't have a tile here, OR the tile's team doesn't match our player's, OR we have a plot # that isn't claimed by our player, then return
        if not tile or tile.team ~= team or (tile.plot and not GameMode:DoesPlayerHavePlot(playerid, tile.plot)) then
            return false
        end
    end

    return true
end