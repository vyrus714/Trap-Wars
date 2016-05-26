var game_values = CustomNetTables.GetTableValue("trapwars_static_info", "generic");
var tile_size = game_values.tile_size || 128;
var current_item_name = null;

GameUI.CustomUIConfig().Events.SubscribeEvent("show_ghost", OnShowGhost);
GameUI.CustomUIConfig().Events.SubscribeEvent("hide_ghost", OnHideGhost);
//GameUI.CustomUIConfig().Events.FireEvent("show_ghost", {});
//GameUI.CustomUIConfig().Events.FireEvent("hide_ghost", {});

function OnShowGhost(keys) {
    // run the hide function so we have a clean slate
    OnHideGhost();

    // set the item name (or null if none)
    current_item_name = keys.name;

    // create the particle
    GameUI.CustomUIConfig().Ghost = Particles.CreateParticle("particles/ghost.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, -1);
    // if there's an entity passed, set it as the particle control entity
    if(keys.entity) {
        Particles.SetParticleControlEnt(GameUI.CustomUIConfig().Ghost, 1, keys.entity, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", keys.entity.GetAbsOrigin(), true);
        //(modelParticle, 1, entindex, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", Entities.GetAbsOrigin(entindex), true)
    }

    // lock this particle to the mouse position
    UpdateGhost();
}

function OnHideGhost() {
    if(GameUI.CustomUIConfig().Ghost) {
        // clear the item name
        current_item_name = null;

        // remove the particles
        Particles.DestroyParticleEffect(GameUI.CustomUIConfig().Ghost, true);
        Particles.ReleaseParticleIndex(GameUI.CustomUIConfig().Ghost);

        // wipe the variable so we can stop updating
        GameUI.CustomUIConfig().Ghost = null;
    }
}

function UpdateGhost() {
    // if the particle still exists
    if(GameUI.CustomUIConfig().Ghost) {
        // get the mouse world coordinates
        var position = GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition());
        // align this position to the grid
        //position = [ Math.floor((position[0]+tile_size/2)/tile_size)*tile_size,
        //             Math.floor((position[1]+tile_size/2)/tile_size)*tile_size,
        //             Math.floor(position[2]/tile_size)              *tile_size  ];
        position = GetTileCenter(position);

        // move the particle to this position
        Particles.SetParticleControl(GameUI.CustomUIConfig().Ghost, 0, position);

        // do it all again in 1/60 seconds
        $.Schedule(1/60, UpdateGhost);
    }
}



// create a keyboard / mouse listener to hide the ghost
GameUI.SetMouseCallback(OnMouseEvent);
function OnMouseEvent(type, key_id) {
    if(type == "pressed" && GameUI.CustomUIConfig().Ghost) {
        // left click
        if(key_id == 0) {
            // send the purchase event to the server
            GameEvents.SendCustomGameEventToServer("trapwars_buy_trap", {
                name     : current_item_name,
                playerid : Players.GetLocalPlayer(),
                position : GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition())
            });

            // begin a mouse drag event
            $.Schedule(1/60, function() { DragEvent(GetTileCenter(GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition()))); });

            // consume the mouse event
            return true;
        }

        // right click
        if(key_id == 1) {
            // hide the ghost
            GameUI.CustomUIConfig().Events.FireEvent("hide_ghost", {});

            // consume the mouse event
            return true;
        }
    }
}

function DragEvent(last_tile_position) {
    if(!GameUI.IsMouseDown(0)) { return; }

    // current tile the mouse is hovering over
    var current_tile_position = GetTileCenter(GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition()));

    // if last_position and our current mouse world position are in different tiles, send a new buy event
    if(last_tile_position[0] != current_tile_position[0] || last_tile_position[1] != current_tile_position[1]) {
        // send the purchase event to the server
        GameEvents.SendCustomGameEventToServer("trapwars_buy_trap", {
            name     : current_item_name,
            playerid : Players.GetLocalPlayer(),
            position : current_tile_position
        });
    }

    // keep on chugging
    $.Schedule(1/60, (function(a) {  return function(){DragEvent(a);}  })(current_tile_position));
}

function GetTileCenter(position) {
    return [
        Math.floor((position[0]+tile_size/2)/tile_size)*tile_size,
        Math.floor((position[1]+tile_size/2)/tile_size)*tile_size,
        Math.floor(position[2]/tile_size)              *tile_size
    ];
}


/*  FIXME: none of this seems to work at all
$.RegisterKeyBind($.GetContextPanel(),"key_escape", OnEscape);

function OnEscape() {
    $.Msg("esc pressed");
}

$.RegisterKeyBind($.GetContextPanel(),"key_n", function() {
    $.Msg("this didn't work either");
});
*/