function Spawn( entityKeyValues )
    spikes_activate = thisEntity:FindAbilityByName("floor_spikes_activate")
    thisEntity:SetContextThink( "OnThink", OnThink , 1)
end

function OnThink()
    if not thisEntity:IsAlive() then return end

    if spikes_activate and spikes_activate:IsFullyCastable() then
        for _, unit in pairs(Entities:FindAllInSphere(thisEntity:GetAbsOrigin(), spikes_activate:GetSpecialValueFor("radius") or 0)) do
            if unit.IsDeniable and unit:GetTeam() ~= thisEntity:GetTeam() and unit:IsAlive() then
                thisEntity:CastAbilityNoTarget(spikes_activate, -1)
                break
            end
        end
    end

    return 1/4
end