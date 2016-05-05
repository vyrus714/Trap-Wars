function OnAbilityPhaseStart(event)
    -- emit the warning sound effect when cast point starts
    EmitSoundOn("trap.floorSpikes.depressed", event.caster)
end

function OnSpellStart(event)
    -- emit the casting sound effect when cast point ends and ability is cast
    EmitSoundOn("trap.floorSpikes.spikes", event.caster)
end

function UpdateStackCount(event)
    -- get the modifier
    local modifier = event.target:FindModifierByName("broken_armor") or event.ability:ApplyDataDrivenModifier(event.caster, event.target, "broken_armor", {})
    -- paranoia check
    if modifier == nil or event.armor_reduction == nil then return end
    -- add the armor reduction to the stack count for this modifier
    modifier:SetStackCount((modifier:GetStackCount() or 0) + event.armor_reduction)
end