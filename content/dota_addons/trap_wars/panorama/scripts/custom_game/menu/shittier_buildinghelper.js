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

    // get the length and width of this trap
    var trap = CustomNetTables.GetTableValue("trapwars_npc_traps", keys.name);
    Config.BuildingGhost.length = trap.Length || 1;
    Config.BuildingGhost.width  = trap.Width  || 1;

    // create the particle(s)
    Config.BuildingGhost.particles = [];

    // ghost
    Config.BuildingGhost.particles.ghost = Particles.CreateParticle("particles/building_ghost/ghost.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, -1);
    Particles.SetParticleControl(Config.BuildingGhost.particles.ghost, 4, [Config.BuildingGhost.length, Config.BuildingGhost.width, 1]);

    // tile outline
    var length = Config.BuildingGhost.length+2, width = Config.BuildingGhost.width+2;
    for(i=0; i<length*width; i++) {
        if(i%length == 0 || (i+1)%length == 0 || Math.floor(i/width) == 0 || Math.floor(i/width) == width-1) {
            Config.BuildingGhost.particles[i] = Particles.CreateParticle("particles/building_ghost/square.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, -1);
            Particles.SetParticleControl(Config.BuildingGhost.particles[i], 1, [0.2, 0, 0]);
        }
    }

    // if there's an entity passed, set it as the particle control entity for the ghost particle   FIXME
    if(keys.entity) {
        Particles.SetParticleControlEnt(Config.BuildingGhost.particles[4], 1, keys.entity, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", keys.entity.GetAbsOrigin(), true);
        //(modelParticle, 1, entindex, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", Entities.GetAbsOrigin(entindex), true)
    }

    // lock this particle to the mouse position
    UpdateGhost();
}

function UpdateGhost() {
    // if the particles still exist
    if(Config.BuildingGhost.draw_ghost) {
        // update the box particle position
        //offset_position = [offset_position[0]-64, offset_position[1]-64, offset_position[2]];
        var offset_position = SnapBoxToGrid2D(MouseWorldPos(), Config.BuildingGhost.length, Config.BuildingGhost.width);
        if(offset_position) {
            Particles.SetParticleControl(Config.BuildingGhost.particles.ghost, 0, offset_position);

            // update the outline tile positions & all particle colors
            offset_position = [offset_position[0]-Config.BuildingGhost.length*32-32, offset_position[1]-Config.BuildingGhost.width*32-32, offset_position[2]];
            for(var i in Config.BuildingGhost.particles) {
                if(!isNaN(i)) {
                    var pos = [offset_position[0] + 64*(i%(Config.BuildingGhost.length+2)), offset_position[1] + 64*Math.floor(i/(Config.BuildingGhost.width+2)), offset_position[2]];
                    Particles.SetParticleControl(Config.BuildingGhost.particles[i], 0, pos);
                }

                var traps = FindTrapsInRadius(pos, 32)  // FIXME: needs more sophistication now
                if(traps.length > 0) {
                    Particles.SetParticleControl(Config.BuildingGhost.particles[i], 2, [216, 0, 0]);
                } else {
                    Particles.SetParticleControl(Config.BuildingGhost.particles[i], 2, [0, 216, 0]);
                }
            }
        }

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

        // clear the length and width
        Config.BuildingGhost.length = null;
        Config.BuildingGhost.width  = null;


        // remove the particles
        for(var i in Config.BuildingGhost.particles) {
            Particles.DestroyParticleEffect(Config.BuildingGhost.particles[i], true);
            Particles.ReleaseParticleIndex(Config.BuildingGhost.particles[i]);
        }
        Config.BuildingGhost.particles = [];
    }
}


// ************************ //
// *     OnMouseEvent     * //
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

function DragSell() {  // FIXME: put these two into one function
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

    // mouse positions
    last_tile_position = last_tile_position || [];  //[null, null, null];
    var current_tile_position = SnapToGrid2D(MouseWorldPos());

    // if last_position and our current mouse world position are in different tiles, send a new buy event
    if(last_tile_position[0] != current_tile_position[0] || last_tile_position[1] != current_tile_position[1]) {
        BuyTrap(Config.BuildingGhost.current_item_name, MouseWorldPos());
    }

    // keep on chugging
    $.Schedule(1/60, (function(a) {  return function(){DragBuy(a);}  })(current_tile_position));
}


// ************************ //
// *    Grid Functions    * //
// ************************ //

function SnapTo32(number) {
    return Math.floor((number+32)/64)*64;
}

function SnapTo64(number) {
    if(number < 0)
        return Math.ceil(number/64)*64 - 32;

    return Math.floor(number/64)*64 + 32;
}

function SnapToGrid2D(position) {
    return [SnapTo64(position[0]), SnapTo64(position[1]), position[2]];
}

// SnapToGround(position)    no ground height detection in javascript api
// SnapToAir(position)

function SnapBoxToGrid2D(position, length, width) {
    // make sure we have a useable length and width (any overlap is counted as taking up that whole tile)
    length = Math.ceil(length) || 1, width = Math.ceil(width) || 1;

    // align the position of the center to the grid
    if(length%2 == 0)  // even
        position[0] = SnapTo32(position[0]);
    else               // odd
        position[0] = SnapTo64(position[0]);

    if(width%2 == 0)  // even
        position[1] = SnapTo32(position[1]);
    else              // odd
        position[1] = SnapTo64(position[1]);

    return position;
}


// ************************ //
// *    Other Functions   * //
// ************************ //

function MouseWorldPos() {
    return GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition());
}

function BuyTrap(trap_name, position) {
    GameEvents.SendCustomGameEventToServer("trapwars_buy_trap", {
        name     : trap_name,
        playerid : Players.GetLocalPlayer(),
        position : position
    });
}

function SellTrap(entity_index) {
    GameEvents.SendCustomGameEventToServer("trapwars_sell_trap", {
        playerid : Players.GetLocalPlayer(),
        entindex : entity_index
    });
}

function Distance2D(pos1, pos2) {
    return Math.sqrt(Math.pow(pos1[0]-pos2[0], 2) + Math.pow(pos1[1]-pos2[1], 2));
}

// apparently this is more cpu friendly
function Distance2DSquared(pos1, pos2) {
    return Math.pow(pos1[0]-pos2[0], 2) + Math.pow(pos1[1]-pos2[1], 2);
}

function FindCreaturesInRadius(position, radius) {
    var found_creatures = [];

    var creatures = Entities.GetAllEntitiesByClassname("npc_dota_creature");
    for(var i in creatures) {
        //if(Distance2D(Entities.GetAbsOrigin(creatures[i]), position) < radius) {
        if(Distance2DSquared(Entities.GetAbsOrigin(creatures[i]), position) < (radius*radius)) {
            found_creatures.push(creatures[i]);
        }
    }

    return found_creatures;
}

function FindTrapsInRadius(position, radius) {
    var traps = [];

    //var creatures = FindCreaturesInRadius(position, radius);
    var creatures = Entities.GetAllEntitiesByClassname("npc_dota_creature");
    for(var i in creatures) {
        //if(CustomNetTables.GetTableValue("trapwars_npc_traps", Entities.GetUnitName(creatures[i]))) {
        if(CustomNetTables.GetTableValue("trapwars_npc_traps", Entities.GetUnitName(creatures[i])) && Distance2DSquared(Entities.GetAbsOrigin(creatures[i]), position) < (radius*radius)) {
            traps.push(creatures[i]);
        }
    }

    return traps;
}


// update2: vv that didn't work - stole all focus from everything, back go square 1
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