function Spawn( entityKeyValues )
    ABILILTY_spiketrap_spikes = thisEntity:FindAbilityByName("floor_spikes_activate")
    thisEntity:SetContextThink( "OnThink", OnThink , 1)
end

function OnThink()
    if not thisEntity:IsAlive() then return end

    if ABILILTY_spiketrap_spikes ~= nil then
        local radius = ABILILTY_spiketrap_spikes:GetSpecialValueFor("radius")
        if radius ~= nil then
            if ABILILTY_spiketrap_spikes:IsFullyCastable() then
                local units = Entities:FindAllInSphere(thisEntity:GetAbsOrigin(), radius)
                for _, unit in pairs(units) do
                    if unit.IsDeniable ~= nil and unit:GetTeam() ~= thisEntity:GetTeam() and unit:IsAlive() then
                        thisEntity:CastAbilityNoTarget(ABILILTY_spiketrap_spikes, -1)
                        break
                    end
                end
            end
        end
    end

    return 1/4
end