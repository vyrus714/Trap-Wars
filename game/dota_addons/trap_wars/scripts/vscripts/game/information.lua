local GameMode = GameRules.GameMode

---------------------------------------------------------------------------
-- some general team info functions
---------------------------------------------------------------------------
function GameMode:IsPlayerTeam(teamID)
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

function GameMode:GetSpawners(team)
    local spawners = {}

    for _, ent in pairs(Entities:FindAllByName("Spawn_"..team)) do
        table.insert(spawners, ent:GetEntityIndex())
    end

    return spawners
end

function GameMode:GetPortals(team)
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


--------------------
-- Grid Functions --
--------------------
function GameMode:SnapTo32(number)
    return math.floor((number+32)/64)*64
end

function GameMode:SnapTo64(number)
    if number < 0 then
        return math.ceil(number/64)*64 - 32
    end

    return math.floor(number/64)*64 + 32
end

function GameMode:SnapToGrid2D(position)
    return Vector(GameMode:SnapTo64(position.x), GameMode:SnapTo64(position.y), position.z)
end

function GameMode:SnapToGround(position)
    position = GameMode:SnapToGrid2D(position)
    position.z = GetGroundHeight(position, nil)
    return position
end

function GameMode:SnapToAir(position)
    return GameMode:SnapToGround(position) + Vector(0, 0, 128)
end

function GameMode:SnapBoxToGrid2D(position, length, width)
    -- make sure we have a useable length and width (any overlap is counted as taking up that whole tile)
    length, width = math.ceil(length) or 1, math.ceil(width) or 1

    -- align the position of the center to the grid
    if math.fmod(length, 2) == 0 then  -- even
        position.x = GameMode:SnapTo32(position.x)
    else                               -- odd
        position.x = GameMode:SnapTo64(position.x)
    end

    if math.fmod(width, 2) == 0 then  -- even
        position.y = GameMode:SnapTo32(position.y)
    else                              -- odd
        position.y = GameMode:SnapTo64(position.y)
    end

    return position
end

function GameMode:GetGridArray()
    local gridnav = {}

    -- find all the pathable gridnav tiles (counting trees as unpathable\non-viable tiles)
    for i=0, GameRules.grid_width*GameRules.grid_length-1 do
        local pos = GameRules.grid_start + Vector(64*(i%GameRules.grid_width), 64*math.floor(i/GameRules.grid_length))
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
    local pos = GameRules.grid_start + Vector(64*(index%GameRules.grid_width), 64*math.floor(index/GameRules.grid_length))
    return Vector(pos.x, pos.y, GetGroundHeight(pos, nil))
end

function GameMode:GetGridIndex(position)
    local delta = Vector(position.x-(GameRules.grid_start.x-32), position.y-(GameRules.grid_start.y-32))

    -- if the passed position is below our min position, or above our max position (it's outside the map)
    if delta.x < 0 or delta.y < 0 or delta.x/64 > GameRules.grid_width or delta.y/64 > GameRules.grid_length then return nil end

    return math.floor(delta.x/64) + math.floor(delta.y/64)*GameRules.grid_width
end

function GameMode:DoesPlayerHavePlot(playerid, plot_number)
    if GameRules.Plots[plot_number] == playerid then return true end
    return false
end

function GameMode:CanPlayerBuildHere(playerid, position, length, width)
    length, width = math.ceil(length), math.ceil(width)
    position = GameMode:SnapBoxToGrid2D(position, length, width)
    local team = PlayerResource:GetTeam(playerid)
    local start_index = GameMode:GetGridIndex(position - Vector(length*32, width*32, 0) + Vector(32, 32, 0))

    -- starting at the lower left corner, iterate through the grid tiles in this box
    for i=0, length*width-1 do
        local index = start_index + i%length + math.floor(i/width)*GameRules.grid_width
        local tile = GameRules.GroundGrid[index]

        -- if we don't have a tile here, OR the tile's team doesn't match our player's, OR we have a plot # that isn't claimed by our player, then return
        if not tile or tile.team ~= team or (tile.plot and not GameMode:DoesPlayerHavePlot(playerid, tile.plot)) or (tile.trap and IsValidEntity(EntIndexToHScript(tile.trap))) then
            return false
        end
    end

    return true
end