--[[
values for a spawner:         NOTE that you MUST place these in this order in the default values below, otherwise it will parse wrong
1   string  name:         The spawner's entity name from the map (i used info_target entities but it doesnt matter much, it just grabs the position vector)
                          NOTE: the waypoints for each spawner should be the same name as the spawner, but with a '_#' added to the end, where the #
                          indicates the order of the waypoint (_1, _2, _3 ...) EX:  name: Spawner_1  waypoints: Spawner_1_1, Spawner_1_2, Spawner_1_3 ...
2   bool    enabled:      Whether or not to start the spawner on or off (true = on)
3   int     team:         The team number of the spawner, from here: https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting/API#DOTATeam_t
4   table   creeps:       This table contains the default creep type and amount of said creep
        string  name:     Name of the creep from datadriven files
        int     count:    Amount of this creep
        table   items:    Optional table that lets you add items to the creep's inventory, 6 slots max, unless you've modified the creep somehow
                          NOTE: the creep will not display the item in its inventory unless it has the KeyValue "HasInventory" "1", but it will get the effects
            string:       Item name
            ...
        handle  owner:    Optional, the owner that this creep will belong to, this has to be a player entity handle
5   Vector  origin:       The position of the spawner, only needed in the default values if you're not getting those from entities placed in the map
6   table   path:         A table of Vector position values for creeps to use as order waypoints; like the origin, only define if you aren't using hammer
        Vector pos:       Position Vector
        ... 
--]]
-- an example of some default values: 
SPAWNER_DEFAULT_VALUES = {}
SPAWNER_DEFAULT_VALUES[1] = {"Good_Spawn_1", true, DOTA_TEAM_GOODGUYS, {{name="npc_dota_creep_goodguys_melee",  count=3}}  }
SPAWNER_DEFAULT_VALUES[2] = {"Good_Spawn_1", true, DOTA_TEAM_GOODGUYS, {{name="npc_dota_creep_goodguys_melee",  count=1},
                                                                        {name="npc_dota_creep_goodguys_ranged", count=2}}  }
SPAWNER_DEFAULT_VALUES[3] = {"Bad_Spawn",    true, DOTA_TEAM_BADGUYS,  {{name="npc_dota_creep_badguys_melee",   count=6, 
                                                                        items={"item_desolator", "item_moon_shard"}    }}  }

if Spawners == nil then
  print ( '[Spawners] creating Spawners' )
  Spawners = {}
  Spawners.__index = Spawners
end

-- Run this function once after you've loaded the map (using bmd's barebones it should go in GameMode:InitGameMode())
-- it returns a table of creep spawners, make sure to save it so you can modify them later
function Spawners:CreateSpawners( defaults )
    local defaults = defaults or SPAWNER_DEFAULT_VALUES  -- the values to create spawners with
    local spawners = {}

    for k,value in ipairs(defaults) do
        local spawn = Entities:FindByName(nil, value[1])
        if spawn then  -- make sure the spawner exists
            -- get the waypoints for this spawner
            local i,points = 1,{}
            while true do
                local point = Entities:FindByName(nil, value[1].."_"..i)
                if point==nil then break end
                points[i] = point:GetAbsOrigin()
                i=i+1
            end
            -- set all the values for this spawner - the key will be the name, but that's hard to use sometimes so there's a name field as well
            spawners[k] = {
                name    = value[1],
                enabled = value[2],
                team    = value[3],
                creeps  = value[4],
                origin  = spawn:GetAbsOrigin(),
                path    = points
            }
        else
            -- did not find that spawner in the map, check if there's an origin value
            if value[5] then
                spawners[k] = {
                    name    = value[1],
                    enabled = value[2],
                    team    = value[3],
                    creeps  = value[4],
                    origin  = value[5]
                }
                -- ok, so we have a lua-based spawner, do we have lua-based path coordinates?
                if value[6] then spawners[k].path = value[6] end
            end
        end
    end

    return spawners
end

-- this is the code that actually spawns the creeps, pass it the table of spawners from GetSpawnerData()
-- i left it without a timer on it, so you have to add one (allows flexibility this way)
function Spawners:SpawnCreeps( spawners )
    if type(spawners)~="table" then return end  -- check to make sure it exists
    for i,spawn in pairs(spawners) do           -- go through each spawner
        if spawn.enabled then                   -- is the spawner on?
            for j,creep in pairs(spawn.creeps) do
                for a=1,creep.count do
                    -- spawn the creep
                    local npc = CreateUnitByName(creep.name, spawn.origin, true, creep.owner, creep.owner, spawn.team)
                    -- give the creep items
                    if creep.items then
                        if not npc:HasInventory() then npc:SetHasInventory(true) end  -- if it doesn't have an inventory, give it one
                        for k,item in pairs(creep.items) do
                            npc:AddItem(CreateItem(item, nil, nil))
                        end
                    end
                    -- set the creep's waypoints
                    for k=1,#spawn.path do
                        npc:SetThink( function()  -- this needs a delay, otherwise it will do all of these on the same frame, with a random order
                            ExecuteOrderFromTable{
                                UnitIndex = npc:entindex(),
                                OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,  -- add this into the spawner.creeps table? no way of setting per point, so not now
                                Position  = spawn.path[k],
                                Queue     = true  }
                        end, "t_"..k, (0.03*k) )
                    end
                end
            end
        end
    end
end

-- this will spawn creeps after <statdelay>, and then again every <interval> (times in seconds)
-- for more complex uses, I recommend bmd's Tiemrs library: 
-- https://github.com/bmddota/barebones/blob/source2/game/dota_addons/barebones/scripts/vscripts/libraries/timers.lua
function Spawners:SpawnCreepsOnInterval( spawners, startdelay, interval )
    local startdelay = startdelay or 0
    local interval   = interval   or 0

    if spawners == nil then return false end

    -- small rounding function, just saving space - effectively gets us the closest second marker in game time
    local function round(num) return math.floor(num+0.5) end

    -- align our passed times to game time
    local nextTime = round(GameRules:GetGameTime()+startdelay)

    -- the timer
    GameRules:GetGameModeEntity():SetThink( function()
        local currentTime = round( GameRules:GetGameTime() )
        if nextTime-currentTime < 1 then
            -- spawn the creeps
            Spawners:SpawnCreeps(spawners)
            -- set the time of the next spawn & make sure we're still aligned to the game time
            nextTime = round(currentTime+interval)
        end

        -- run this thinker every second
        return 1
    end, startdelay )
end

--[[ same as above (mostly), but using bmd's Timers library
function Spawners:SpawnCreepsOnInterval( spawners, startdelay, interval )
    Timers:CreateTimer(startdelay, function() Spawners:SpawnCreeps(spawners) return interval end)
end  ]]

-- add a creep type to a spawner
-- creepcount and items are optional: it will just add 1 creep, and no items. however if you want items you will need a value for creepcount
-- items can be either a table of strings (up to 6) OR a single string for just one item
function Spawners:AddCreep( spawner, creepname, creepcount, creepitems )
    creepcount = creepcount or 1
    creepitems = creepitems or nil
    if type(creepitems) == "string" then creepitems = { creepitems } end  -- make sure creepitems is in table format when added
    if spawner == nil then return false end

    local indx = nil
    for i,v in ipairs(spawner.creeps) do  -- find the lowest free index
        if spawner.creeps[i] == nil then
            spawner.creeps[i] = { name=creepname, count=creepcount, items=creepitems }
            return
        end
        indx = i
    end
    -- ok, if we got here, then the lowest free index was at the end of the table
    spawner.creeps[indx+1] = { name=creepname, count=creepcount, items=creepitems }
end

-- get the index of a creep by name: will return nil if it didnt find it, int if there's only 1, and a table of int if there are multiple by that name
function Spawners:GetCreepID( spawner, creepname )
    local i,idtable = 1,{}
    for k,v in ipairs(spawner.creeps) do
        if v.name == creepname then
            idtable[i]=k
            i=i+1
        end
    end
    if #idtable < 1 then 
        return nil
    elseif #idtable == 1 then
        return idtable[1]
    else
        return idtable
    end
end

-- add an item to a specific creep, true on success, false on fail
function Spawners:AddCreepItem( spawner, creepid, itemname )
    if #spawner.creeps[creepid].items >= 6 then return false end  -- make sure there will be room in the inventory
    local i = nil
    -- find the first available index
    for k,v in ipairs(spawner.creeps[creepid].items) do
        if v == nil then
            spawner.creeps[creepid].items[k] = itemname
            return true
        end
        i = k  -- save the value of k when the loop ends
    end
    -- there was no index free until the end of the table
    spawner.creeps[creepid].items[i+1] = itemname
    return true
end

-- remove an item from a creep, true on success, false on fail
function Spawners:RemoveCreepItem( spawner, creepid, itemname )
    if spawner.creeps[creepid].items == nil then return false end  -- no items on this creep, no deal
    if #spawner.creeps[creepid].items < 1 then  -- less than 1 item on this creep? empty table, remove it and no deal
        spawner.creeps[creepid].items = nil
        return false
    end

    for k,v in ipairs(spawner.creeps[creepid].items) do
        if v == itemname then
            spawner.creeps[creepid].items[k] = nil
            if #spawner.creeps[creepid].items < 1 then spawner.creeps[creepid].items = nil end  -- we now have no items in table, remove it
            return true
        end
    end
    return false  -- no item by that name
end
