GameEvents.Subscribe("trapwars_sound_event", EmitClientSound);

function EmitClientSound( event )
{
    if( event.sound ) {
        Game.EmitSound(event.sound);
    }
}