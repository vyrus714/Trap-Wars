// my version of "the wheel" is oval shaped and made out of salami

var Config = GameUI.CustomUIConfig();
Config.BuildingGhost = Config.BuildingGhost || {};


// events
GameUI.CustomUIConfig().Events.SubscribeEvent("show_ghost", OnShowGhost);  //GameUI.CustomUIConfig().Events.FireEvent("show_ghost", {});
GameUI.CustomUIConfig().Events.SubscribeEvent("hide_ghost", OnHideGhost);  //GameUI.CustomUIConfig().Events.FireEvent("hide_ghost", {});

GameUI.SetMouseCallback(OnMouseEvent);


// ************************ //
// *      OnShowGhost     * //
// ************************ //
function OnShowGhost(keys) {
    // run the hide function so we have a clean slate
    OnHideGhost();

    // set the item name (or null if none)
    Config.BuildingGhost.current_item_name = keys.name;

    // create the particle
    Config.BuildingGhost.Particle = Particles.CreateParticle("particles/ghost.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, -1);
    // if there's an entity passed, set it as the particle control entity
    if(keys.entity) {
        Particles.SetParticleControlEnt(Config.BuildingGhost.Particle, 1, keys.entity, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", keys.entity.GetAbsOrigin(), true);
        //(modelParticle, 1, entindex, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", Entities.GetAbsOrigin(entindex), true)
    }

    // lock this particle to the mouse position
    UpdateGhost();
}

function UpdateGhost() {
    // if the particle still exists
    if(Config.BuildingGhost.Particle) {
        // move the particle to the grid position of the cursor
        Particles.SetParticleControl(Config.BuildingGhost.Particle, 0, MouserPosToTilePos());

        // do it all again in 1/60 seconds
        $.Schedule(1/60, UpdateGhost);
    }
}


// ************************ //
// *      OnHideGhost     * //
// ************************ //
function OnHideGhost() {
    if(Config.BuildingGhost.Particle) {
        // clear the item name
        Config.BuildingGhost.current_item_name = null;

        // remove the particles
        Particles.DestroyParticleEffect(Config.BuildingGhost.Particle, true);
        Particles.ReleaseParticleIndex(Config.BuildingGhost.Particle);

        // wipe the variable so we can stop updating
        Config.BuildingGhost.Particle = null;
    }
}


// ************************ //
// *     OnMouserEvent    * //
// ************************ //
function OnMouseEvent(type, key_id) {
    if(type == "pressed" && Config.BuildingGhost.Particle) {
        // left click
        if(key_id == 0) {
            DragEvent();  // begin a mouse drag event
            return true;  // consume the mouse event
        }

        // right click   FIXME: remove when i get the 'oncancel' event working
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
    // when called with no params (expected behavior), we don't want a starting position
    last_tile_position = last_tile_position || [null, null, null];

    // current tile the mouse is hovering over
    var current_tile_position = MouserPosToTilePos();

    // if last_position and our current mouse world position are in different tiles, send a new buy event
    if(last_tile_position[0] != current_tile_position[0] || last_tile_position[1] != current_tile_position[1]) {
        // send the purchase, or sell, event to the server
        if(Config.BuildingGhost.current_item_name == "sell") {
            SellTrap(position);
        } else {
            BuyTrap(Config.BuildingGhost.current_item_name, current_tile_position);
        }
    }


    // keep on chugging
    $.Schedule(1/60, (function(a) {  return function(){DragEvent(a);}  })(current_tile_position));
}


// ************************ //
// *    Other Functions   * //
// ************************ //
function GetTileCenter(position) {
    var tile_size = CustomNetTables.GetTableValue("trapwars_static_info", "generic") ? CustomNetTables.GetTableValue("trapwars_static_info", "generic").tile_size : 128;
    return [
        Math.floor((position[0]+tile_size/2)/tile_size)*tile_size,
        Math.floor((position[1]+tile_size/2)/tile_size)*tile_size,
        Math.floor(position[2]/tile_size)              *tile_size
    ];
}

function MouserPosToTilePos() {
    return GetTileCenter(GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition()));
}

function BuyTrap(trap_name, position) {
    GameEvents.SendCustomGameEventToServer("trapwars_buy_trap", {
        name     : trap_name,
        playerid : Players.GetLocalPlayer(),
        position : position
    });
}

function SellTrap(position) {
    GameEvents.SendCustomGameEventToServer("trapwars_sell_trap", {   // FIXME: implement the lua for this
        playerid : Players.GetLocalPlayer(),
        position : position
    });
}


// update: apparently if a panel has focus, and you hit esc, it triggers an 'oncancel' event, so lets see if we can use that
/*  FIXME: none of this seems to work at all
$.RegisterKeyBind($.GetContextPanel(),"key_escape", OnEscape);

function OnEscape() {
    $.Msg("esc pressed");
}

$.RegisterKeyBind($.GetContextPanel(),"key_n", function() {
    $.Msg("this didn't work either");
});
*/