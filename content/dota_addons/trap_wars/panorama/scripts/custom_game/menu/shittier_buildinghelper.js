// my version of "the wheel" is oval shaped and made out of salami

var Config = GameUI.CustomUIConfig();
Config.BuildingGhost = Config.BuildingGhost || {};


// events
GameUI.CustomUIConfig().Events.SubscribeEvent("buy_ghost" , OnBuyGhost );  //GameUI.CustomUIConfig().Events.FireEvent("buy_ghost" , {});
GameUI.CustomUIConfig().Events.SubscribeEvent("sell_ghost", OnSellGhost);  //GameUI.CustomUIConfig().Events.FireEvent("sell_ghost", {});
GameUI.CustomUIConfig().Events.SubscribeEvent("hide_ghost", OnHideGhost);  //GameUI.CustomUIConfig().Events.FireEvent("hide_ghost", {});
GameUI.SetMouseCallback(OnMouseEvent);


// ************************ //
// *      OnBuyGhost      * //
// ************************ //
function OnBuyGhost(keys) {
    // run the hide function so we have a clean slate
    OnHideGhost();


    // set the item name
    Config.BuildingGhost.current_item_name = keys.name;

    // set the draw conditional to true
    Config.BuildingGhost.draw_ghost = true;


    // create the particle(s)  FIXME: prepped for multiple particles here, not handled yet though
    Config.BuildingGhost.particles = [
        Particles.CreateParticle("particles/ghost.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, -1)
    ];
    // if there's an entity passed, set it as the particle control entity  FIXME
    if(keys.entity) {
        Particles.SetParticleControlEnt(Config.BuildingGhost.particles[0], 1, keys.entity, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", keys.entity.GetAbsOrigin(), true);
        //(modelParticle, 1, entindex, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", Entities.GetAbsOrigin(entindex), true)
    }

    // lock this particle to the mouse position
    UpdateGhost();
}

function UpdateGhost() {
    // if the particles still exist
    if(Config.BuildingGhost.draw_ghost) {
        // move the particle to the grid position of the cursor    FIXME: multiple particles
        Particles.SetParticleControl(Config.BuildingGhost.particles[0], 0, MousePosToTilePos());

        // do it all again in 1/60 seconds
        $.Schedule(1/60, UpdateGhost);
    }
}


// ************************ //
// *      OnSellGhost     * //       FIXME: Right now this doesn't make sense, however i DO plan on adding something to the mouse, and this could be useful
// ************************ //              for that. Otherwise, these can probably be scrapped and folded into one 'buy\sell' event function.
function OnSellGhost() {
    // run the hide function so we have a clean slate
    OnHideGhost();


    // set the item name - for a sell event, it's fixed at "sell"
    Config.BuildingGhost.current_item_name = "sell";

    // set the draw conditional to true
    Config.BuildingGhost.draw_ghost = true;


    // create the particle(s)
    Config.BuildingGhost.particles = [
        Particles.CreateParticle("particles/overhead_flame.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, -1)
    ];

    // update the particle(s)
    UpdateSellGhost();
}

function UpdateSellGhost() {
    // if the particles still exist
    if(Config.BuildingGhost.draw_ghost) {
        // move the particle to the cursor position
        Particles.SetParticleControl(Config.BuildingGhost.particles[0], 0, GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition()));
        //Particles.SetParticleControl(Config.BuildingGhost.particles[0], 0, GameUI.GetCursorPosition());

        // do it all again in 1/60 seconds
        $.Schedule(1/60, UpdateSellGhost);
    }
}


// ************************ //
// *      OnHideGhost     * //
// ************************ //
function OnHideGhost() {
    if(Config.BuildingGhost.draw_ghost) {
        // clear the draw condition
        Config.BuildingGhost.draw_ghost = false;

        // clear the item name
        Config.BuildingGhost.current_item_name = null;


        // remove the particles
        Particles.DestroyParticleEffect(Config.BuildingGhost.particles[0], true);
        Particles.ReleaseParticleIndex(Config.BuildingGhost.particles[0]);
        Config.BuildingGhost.particles = [];
    }
}


// ************************ //
// *     OnMouserEvent    * //
// ************************ //
function OnMouseEvent(type, key_id) {
    if(type == "pressed" && Config.BuildingGhost.draw_ghost) {
        // left click
        if(key_id == 0) {
            // sell\buy stuff
            if(Config.BuildingGhost.current_item_name == "sell") {
                DragSell();
            } else {
                DragBuy();
            }

            // consume the mouse event
            return true;
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

function DragSell() {
    if(!GameUI.IsMouseDown(0)) {
        if(!GameUI.IsShiftDown()) {
            GameUI.CustomUIConfig().Events.FireEvent("hide_ghost", {});
        }
        return;
    }

    // get the entity under the cursor
    var ent_array = GameUI.FindScreenEntities(GameUI.GetCursorPosition());
    var ent_index = (ent_array[0] && ent_array[0].entityIndex) ? ent_array[0].entityIndex : null;

    // if it exists, and isn't owned by someone else, attempt to buy it
    if(ent_index && Entities.IsCreep(ent_index) && !Entities.IsEnemy(ent_index)) {
        SellTrap(ent_index);
    }

    // keep on chugging
    $.Schedule(1/60, function() {DragSell();});
}

function DragBuy(last_tile_position) {
    if(!GameUI.IsMouseDown(0)) {
        if(!GameUI.IsShiftDown()) {
            GameUI.CustomUIConfig().Events.FireEvent("hide_ghost", {});
        }
        return;
    }

    // when called with no params (expected behavior), we don't want a starting position
    last_tile_position = last_tile_position || [null, null, null];

    // current tile the mouse is hovering over
    var current_tile_position = MousePosToTilePos();


    // if last_position and our current mouse world position are in different tiles, send a new buy event
    if(last_tile_position[0] != current_tile_position[0] || last_tile_position[1] != current_tile_position[1]) {
        BuyTrap(Config.BuildingGhost.current_item_name, current_tile_position);
    }

    // keep on chugging
    $.Schedule(1/60, (function(a) {  return function(){DragBuy(a);}  })(current_tile_position));
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

function MousePosToTilePos() {
    return GetTileCenter(GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition()));
}

function BuyTrap(trap_name, position) {
    GameEvents.SendCustomGameEventToServer("trapwars_buy_trap", {
        name     : trap_name,
        playerid : Players.GetLocalPlayer(),
        position : position
    });
}

function SellTrap(entity_index) {  // FIXME: change this to entity index rather than position - much gooder!
    GameEvents.SendCustomGameEventToServer("trapwars_sell_trap", {   // FIXME: implement the lua for this
        playerid : Players.GetLocalPlayer(),
        entindex : entity_index
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