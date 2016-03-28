-- creep format: { name="creepname", count=1, rate=4, owner=OWNER_PLAYER_ID, random=false, items={"itemname", "itemname"} }


-- wrap utility functions in a class to avoid naming issues
if Spawn == nil then
    Spawn = class({})
end

---- Global Variable Dependant Spawning Functions ----
function CreepSpawnThinker( creep_table, creep_spawns, team )
    for k, creep in pairs(creep_table) do
        creep._incr = 0
    end

    Timers:CreateTimer(function()
        for k,creep in pairs(creep_table) do
            if creep.rate <= creep._incr then
                SpawnMultipleCreeps(creep, creep_spawns, team)
                creep._incr = 0
            end
            creep._incr = creep._incr + 1/10
        end

        return 1/10
    end)
end

function SpawnMultipleCreeps( creep, creep_spawns, team )  -- creep = table with creep information, not an actual unit handle
    for i=1,creep.count do
        for k,spawn in pairs(creep_spawns) do
            local c = CreateUnitByName(creep.name, spawn:GetAbsOrigin(), true, nil, nil, team)
            if c then
                -- give items
                if type(creep.items) == "table" then
                    if not c:HasInventory() then c:SetHasInventory(true) end
                    for _, item in pairs(creep.items) do c:AddItemByName(item) end
                end
                -- set initial waypoint
                --c:SetInitialGoalEntity(spawn)
                ExecuteOrderFromTable{
                    UnitIndex = c:entindex(),
                    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
                    Position  = spawn:GetRootMoveParent():GetAbsOrigin(),
                    Queue     = true }
            end
        end
    end
end