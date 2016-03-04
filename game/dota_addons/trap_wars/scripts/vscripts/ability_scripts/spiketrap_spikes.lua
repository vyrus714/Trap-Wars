function OnAbilityPhaseStart( event )
    EmitSoundOn("trap.spiketrap.depressed", event.caster)
end

function OnSpellStart( event )
    EmitSoundOn("trap.spiketrap.spikes", event.caster)
end