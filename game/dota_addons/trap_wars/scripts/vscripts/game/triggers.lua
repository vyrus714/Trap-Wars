function Activate()  -- called when the game mode is loaded
end

function OnPortal(trigger)  --  trigger.activator, trigger.caller
    -- do NOT want items, or anything else that isn't CDota_BaseNPC, but damned if i can find a way to do that
    local result = {}
    trigger.activator:GatherCriteria(result)
    if result.classname == "dota_item_drop" then return end
    -- only creeps
    if not trigger.activator:IsCreep() then return end
    -- don't want units controlled by heroes
    if trigger.activator:IsOwnedByAnyPlayer() then return end


    -- get the team of the portal, we're assuming the name is formatted: <SomeName>_#
    local team = tonumber(trigger.caller:GetName():match('_(%d+).?'))
    -- if the creep is on the same team as the portal, disregaurd
    if trigger.activator:GetTeam() == team then return end


    -- send the score event
    FireGameEvent("trapwars_score_update", {team=team, delta_score=-1})
    -- kill the creep
    trigger.activator:Kill(nil, trigger.caller)
end

function OnEnteredGrid(trigger)
end

function OnExitedGrid(trigger)
end