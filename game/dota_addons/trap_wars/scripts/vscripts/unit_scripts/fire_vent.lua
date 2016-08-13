function Spawn( entityKeyValues )
    fireball = thisEntity:FindAbilityByName("firevent_fireball")
    thisEntity:SetContextThink( "OnThink", OnThink , 1)
end

function OnThink()
    if not thisEntity:IsAlive() then return end

    if fireball and fireball:IsFullyCastable() then
        for _, unit in pairs(Entities:FindAllInSphere(thisEntity:GetAbsOrigin(), fireball:GetSpecialValueFor("cast_radius") or 0)) do
            if unit.IsDeniable and unit:GetTeam() ~= thisEntity:GetTeam() and unit:IsAlive() then
                thisEntity:CastAbilityNoTarget(fireball, -1)
                break
            end
        end
    end

    return 1/4
end