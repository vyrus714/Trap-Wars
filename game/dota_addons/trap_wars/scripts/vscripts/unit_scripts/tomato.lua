function Spawn( entityKeyValues )
    ABILILTY_thunder_clap = thisEntity:FindAbilityByName("polar_furbolg_ursa_warrior_thunder_clap")
    thisEntity:SetContextThink( "OnThink", OnThink , 1)
end

function OnThink()
    if not thisEntity:IsAlive() then return end

    if ABILILTY_thunder_clap ~= nil then
        local radius = ABILILTY_thunder_clap:GetSpecialValueFor("radius")
        if radius ~= nil and ABILILTY_thunder_clap:IsFullyCastable() then
            local units = Entities:FindAllInSphere(thisEntity:GetAbsOrigin(), radius)
            for _, unit in pairs(units) do
                if unit.IsDeniable ~= nil and unit:GetTeam() ~= thisEntity:GetTeam() and unit:IsAlive() then
                    thisEntity:CastAbilityNoTarget(ABILILTY_thunder_clap, -1)
                    break
                end
            end
        end
    end

    return 1/4
end