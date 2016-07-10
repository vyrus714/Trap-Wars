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
    var trap = CustomNetTables.GetTableValue("npc_traps", keys.name);
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
        var center = SnapBoxToGrid2D(MouseWorldPos(), Config.BuildingGhost.length, Config.BuildingGhost.width);
        if(center) {
            // update the outline tile positions & all particle colors
            var offset_position = [center[0]-Config.BuildingGhost.length*32-32, center[1]-Config.BuildingGhost.width*32-32, center[2]];
            for(var i in Config.BuildingGhost.particles) {
                var pos = isNaN(i) ? center : [offset_position[0]+64*(i%(Config.BuildingGhost.length+2)), offset_position[1]+64*Math.floor(i/(Config.BuildingGhost.width+2)), offset_position[2]];

                // update position
                Particles.SetParticleControl(Config.BuildingGhost.particles[i], 0, pos);

                // update color
                var color = CanIBuildHere(pos) ? [0, 216, 0] : [216, 0, 0];
                if(isNaN(i))
                    color = CanIBuildHere(pos, Config.BuildingGhost.length, Config.BuildingGhost.width) ? [0, 216, 0] : [216, 0, 0];
                Particles.SetParticleControl(Config.BuildingGhost.particles[i], 2, color);
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

    // if last_position and our current mouse world position are in different tiles, send a new buy event      FIXME: update for variable length/width traps
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

function SnapBoxToGrid2D(position_ref, length, width) {
    var position = [position_ref[0], position_ref[1], position_ref[2]];
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

/*
function Distance2D(pos1, pos2) {  // FIXME: remove
    return Math.sqrt(Math.pow(pos1[0]-pos2[0], 2) + Math.pow(pos1[1]-pos2[1], 2));
}

// apparently this is more cpu friendly
function Distance2DSquared(pos1, pos2) {  // FIXME: remove
    return Math.pow(pos1[0]-pos2[0], 2) + Math.pow(pos1[1]-pos2[1], 2);
}

function FindCreaturesInRadius(position_ref, radius) {  // FIXME: remove
    var position = [position_ref[0], position_ref[1], position_ref[2]];
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

function FindTrapsInRadius(position_ref, radius) {  // FIXME: remove
    var position = [position_ref[0], position_ref[1], position_ref[2]];
    var traps = [];

    //var creatures = FindCreaturesInRadius(position, radius);
    var creatures = Entities.GetAllEntitiesByClassname("npc_dota_creature");
    for(var i in creatures) {
        //if(CustomNetTables.GetTableValue("npc_traps", Entities.GetUnitName(creatures[i]))) {
        if(CustomNetTables.GetTableValue("npc_traps", Entities.GetUnitName(creatures[i])) && Distance2DSquared(Entities.GetAbsOrigin(creatures[i]), position) < (radius*radius)) {
            traps.push(creatures[i]);
        }
    }

    return traps;
} */


// build/grid functions

function GetGridIndex(position_ref) {
    var position = [position_ref[0], position_ref[1], position_ref[2]];
    var grid = CustomNetTables.GetTableValue("static_info", "grid");
    grid.start = [grid.start[1], grid.start[2], grid.start[3]];
    var delta = [position[0]-(grid.start[0]-32), position[1]-(grid.start[1]-32)];

    // if the passed position is below our min position, or above our max position (it's outside the map)
    if(delta[0] < 0 || delta[1] < 0 || delta[0]/64 > grid.width || delta[1]/64 > grid.length) {return null;}

    return Math.floor(delta[0]/64) + Math.floor(delta[1]/64)*grid.width;
}

function DoesPlayerHavePlot(playerid, plot_number) {
    var plots = CustomNetTables.GetTableValue("player_plots", ""+playerid);
    if(!plots) {return false;}

    for(var i in plots) {
        if(plot_number == plots[i]) {return true;}
    }

    return false;
}

function CanPlayerBuildHere(playerid, position_ref, length, width) {
    var position = [position_ref[0], position_ref[1], position_ref[2]];
    length = Math.ceil(length), width = Math.ceil(width);
    position = SnapBoxToGrid2D(position, length, width);
    var team = Players.GetTeam(playerid);
    var start_index = GetGridIndex([position[0]-length*32+32, position[1]-width*32+32, position[2]]);

    // starting at the lower left corner, iterate through the grid tiles in this box
    for(i=0; i<length*width; i++) {
        var index = start_index + i%length + Math.floor(i/width)*CustomNetTables.GetTableValue("static_info", "grid").width;
        var tile = CustomNetTables.GetTableValue("ground_grid", ""+index);

        // if we don't have a tile here, OR the tile's team doesn't match our player's,
        // OR we have a plot # that isn't claimed by our player, OR there's a trap here already, THEN return false
        if(!tile || tile.team != team || (tile.plot && !DoesPlayerHavePlot(playerid, tile.plot)) || (tile.trap && Entities.IsValidEntity(tile.trap)))
            return false;
    }

    return true;
}

function CanIBuildHere(position_ref, length, width) {
    return CanPlayerBuildHere(Game.GetLocalPlayerID(), [position_ref[0], position_ref[1], position_ref[2]], length || 1, width || 1);

    // FIXME: add trap detection here? or in CanPlayerBuildHere above
    // this can probably be removed, and folded into ^
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