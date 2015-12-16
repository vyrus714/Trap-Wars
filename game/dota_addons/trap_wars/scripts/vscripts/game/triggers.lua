function Activate()  -- called when the game mode is loaded
end

function OnPortal(trigger)  --  trigger.activator, trigger.caller
    -- do NOT want items, or anything else that isn't CDota_BaseNPC, but damned if i can find a way to do that
    local result = {}
    trigger.activator:GatherCriteria( result )
    if result.classname == "dota_item_drop" then return end


    -- only want creeps, nothing else
    if not trigger.activator:IsCreep() then return end

    -- also don't want units controlled by heroes ( trying to score points with player controlled creeps? bad! )
    if trigger.activator:IsOwnedByAnyPlayer() then
        Say( trigger.activator:GetPlayerOwner(), " is a bad boy!", false )
        --sounds/vo/announcer/ann_custom_bad_01.vsnd   ???
        EmitAnnouncerSoundForPlayer( "sounds/vo/announcer/ann_custom_bad_01.vsnd", trigger.activator:GetPlayerOwnerID() )
        return
    end

    -- pass the rest is team specific functions
    if trigger.caller:GetName() == "Portal_Good" then
        OnPortalGood(trigger)
    elseif trigger.caller:GetName() == "Portal_Bad" then
        OnPortalBad(trigger)
    else
        -- someone called this from some other trigger
    end  
end

function OnPortalGood(trigger)
    if trigger.activator:GetTeam() == DOTA_TEAM_GOODGUYS then return end        -- exclude allied creeps from your own spawner
    FireGameEvent("trapwars_score_update", {team=DOTA_TEAM_GOODGUYS, delta_score=-1})  -- change the score
    trigger.activator:Kill(nil, trigger.caller)  -- kill the creep
end

function OnPortalBad(trigger)
    if trigger.activator:GetTeam() == DOTA_TEAM_BADGUYS then return end        -- exclude allied creeps from your own spawner
    FireGameEvent("trapwars_score_update", {team=DOTA_TEAM_BADGUYS, delta_score=-1})  -- change the score
    trigger.activator:Kill(nil, trigger.caller)  -- kill the creep
end