function Spawn( entityKeyValues )
    ABILILTY_firevent_fireball = thisEntity:FindAbilityByName("firevent_fireball")
    thisEntity:SetContextThink( "OnThink", OnThink , 1)
end

function OnThink()
    if not thisEntity:IsAlive() then return end

    if ABILILTY_firevent_fireball ~= nil then
        local radius = ABILILTY_firevent_fireball:GetSpecialValueFor("cast_radius")
        if radius ~= nil then
            if ABILILTY_firevent_fireball:IsFullyCastable() then
                local units = Entities:FindAllInSphere(thisEntity:GetAbsOrigin(), radius)
                for _, unit in pairs(units) do
                    if unit.IsDeniable ~= nil and unit:GetTeam() ~= thisEntity:GetTeam() and unit:IsAlive() then
                        thisEntity:CastAbilityNoTarget(ABILILTY_firevent_fireball, -1)
                        break
                    end
                end
            end
        end
    end

    return 1/4
end