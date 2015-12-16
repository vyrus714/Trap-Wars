-- creep format: { name="creepname", team=TEAM_ID_NUMBER, count=1, rate=4, owner=OWNER_PLAYER_ID, random=false, items={"itemname", "itemname"} }

-- *** Global Variable Dependant Spawning Functions ***
function CreepSpawnThinker( creeptable )
    for k,creep in pairs(creeptable) do
        creep._incr = 0
    end

    Timers:CreateTimer(function()
        for k,creep in pairs(creeptable) do
            if creep.rate <= creep._incr then
                SpawnMultipleCreeps(creep)
                creep._incr = 0
            end
            creep._incr = creep._incr + 1/10
        end

        return 1/10
    end)
end

function SpawnMultipleCreeps( creep )  -- creep = table with creep information, not an actual unit handle
    for i=1,creep.count do
        for k,spawn in pairs(TW_SPAWNERS[creep.team]) do
            local c = SpawnCreep(creep.name, spawn, creep.team)
            if c then
                GiveItems(c, creep.items)
                if creep.team == DOTA_TEAM_GOODGUYS then SetWaypoint(c, TW_PORTALS[DOTA_TEAM_BADGUYS])
                elseif creep.team == DOTA_TEAM_BADGUYS then SetWaypoint(c, TW_PORTALS[DOTA_TEAM_GOODGUYS]) end
            end
        end
    end
end

-- *** Generic Spawning Functions ***
function SpawnCreep( name, point, team )
    local creep = CreateUnitByName(name, point, true, nil, nil, team)
    return creep
end

function GiveItems( creep, items )
    if not creep or not items then return end
    if not creep:HasInventory() then creep:SetHasInventory(true) end
    for i,item in ipairs(items) do
        creep:AddItemByName(item)
    end
end

function SetWaypoint( creep, point )
    if not creep then return end
    ExecuteOrderFromTable{
        UnitIndex = creep:entindex(),
        OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
        Position  = point,
        Queue     = true
    }
end