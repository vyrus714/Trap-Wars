var Config = GameUI.CustomUIConfig();
var Ghost  = {
	mouse_parts : [],
	grid_parts  : [],
	other_parts : [],
	//name        : null,  // (starts empty)
	length      : 1,
	width       : 1,
	rotation    : 0,  // rotation * 90 = rotation in degrees
	local_pid   : Game.GetLocalPlayerID()
};


/********************/
/*  Event Handlers  */
/********************/
Config.Events.SubscribeEvent("show_ghost", OnShowGhost);
Config.Events.SubscribeEvent("hide_ghost", OnHideGhost);
GameUI.SetMouseCallback(OnMouseEvent);


function OnShowGhost(keys) {
	if(typeof keys.name != "string") {return;}

	// run the hide function to make sure we're starting fresh
	Config.Events.FireEvent("hide_ghost", {});

	// set the current ghost information
	var trap = CustomNetTables.GetTableValue("npc_traps", keys.name);

	Ghost.name = keys.name;
	Ghost.length = (trap && trap.Length) ? trap.Length : 1;
	Ghost.width  = (trap && trap.Width ) ? trap.Width  : 1;


	// mouse particles
	var dummy = CustomNetTables.GetTableValue("static_info", "ghost_dummies")[Ghost.name];
    Ghost.mouse_parts.ghost = Particles.CreateParticle((Ghost.name == "sell") ? "particles/building_ghost/sell_indicator.vpcf" : "particles/building_ghost/ghost.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, -1);
    Particles.SetParticleControlEnt(Ghost.mouse_parts.ghost, 1, dummy || -1, ParticleAttachment_t.PATTACH_CUSTOMORIGIN, "start_at_customorigin", [0, 0, 0], true);
    if(dummy) {
    	// override the model
    	Particles.SetParticleControlEnt(Ghost.mouse_parts.ghost, 1, dummy, ParticleAttachment_t.PATTACH_CUSTOMORIGIN, "start_at_customorigin", [0, 0, 0], true);

    	// set the model scale
    	var scale = trap.ModelScale || 1;
	    Particles.SetParticleControl(Ghost.mouse_parts.ghost, 4, [scale, scale, scale]);
    } else {
    	Particles.SetParticleControl(Ghost.mouse_parts.ghost, 4, [Ghost.length*1.9, Ghost.width*1.9, 1]);
    }

    // add a grid around the ghost if we're buying
    if(keys.name != "sell") {
	    for(i=0; i<(Ghost.length+4)*(Ghost.width+4); i++) {
	    	// skip the corner pieces
	    	if(i == 0 || i == Ghost.length+3 || i == (Ghost.length+4)*(Ghost.width+4)-Ghost.length-4 || i == (Ghost.length+4)*(Ghost.width+4)-1) {continue;}
	    	// skip the spots our ghost is in
	    	if(i%(Ghost.length+4) > 1 && i%(Ghost.length+4) < Ghost.length+2 && Math.floor(i/(Ghost.width+4)) > 1 && Math.floor(i/(Ghost.width+4)) < Ghost.width+2) {continue;}

	        // the rest of the grid is filled with particles
	        Ghost.mouse_parts[i] = Particles.CreateParticle("particles/building_ghost/preview_dot.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, -1);
	    }
	}

    // add a range indicator around the hero showing where you can currently build
    var build_range = CustomNetTables.GetTableValue("static_info", "generic").build_distance;
    if(build_range) {
		Ghost.range_indicator = Particles.CreateParticle("particles/building_ghost/range_indicator.vpcf", ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, Players.GetPlayerHeroEntityIndex(Ghost.local_pid));    
	    Particles.SetParticleControl(Ghost.range_indicator, 1, [build_range, 1, 1]);
	}

	// calculate and store the positions of each valid grid tile and what their draw color should be
	Ghost.grid_table = [];
	for(var i in Config.GetAllNetTableValues("ground_grid")) {
		var tile = CustomNetTables.GetTableValue("ground_grid", i);
		var index = Number(i);
		if(tile && tile.team && !Ghost.other_parts[index]) {
            // set the table variables
			Ghost.grid_table[index] = [
				GetGridPosition(index),  // position
				(tile.team == Players.GetTeam(Ghost.local_pid)) ? [255, 255, 255] : [255, 0, 0]  // color
			];

			// if this tile is owned by someone, override the color with their player color
            if(tile.plot) {
                var plot = CustomNetTables.GetTableValue("plots", ""+tile.plot);
                if(plot && typeof plot.pid == "number")
                	Ghost.grid_table[index][1] = CustomNetTables.GetTableValue("player_colors", ""+plot.pid);
            }
		}
	}

	// update particle positions, colors, and visibility every frame
	UpdateGhost();	
	function UpdateGhost() {
		if(Ghost.name) {
			//** mouse particles **//
			var center = MouseWorldPos();
			if(Ghost.name == "sell") {
				if(!GameUI.IsMouseDown(0)) {
			        // if there's a trap on this team under the cursor, use it's origin as the position instead of the mouse world position
			        var ent_array = GameUI.FindScreenEntities(GameUI.GetCursorPosition());
			        var ent_index = (ent_array[0] && ent_array[0].entityIndex) ? ent_array[0].entityIndex : null;
			        if(ent_index && CustomNetTables.GetTableValue("npc_traps", Entities.GetUnitName(ent_index)) && !Entities.IsEnemy(ent_index))
			            center = Entities.GetAbsOrigin(ent_index);
			    }
			} else {
				center = SnapBoxToGrid2D(center, Ghost.length, Ghost.width);
			}

            // update the outline tile positions & all particle colors
            var min = [center[0]-Ghost.length*32-96, center[1]-Ghost.width*32-96, center[2]];
            for(var i in Ghost.mouse_parts) {
                var pos = isNaN(i) ? center : [min[0]+64*(i%(Ghost.length+4)), min[1]+64*Math.floor(i/(Ghost.width+4)), min[2]];

                // update position
                Particles.SetParticleControl(Ghost.mouse_parts[i], 0, pos);

                // update rotation (only on the Ghost.mouse_parts.ghost particle though)   FIXME: use a sine function, you lazy ass
                if(isNaN(i))
                	Particles.SetParticleControlForward(Ghost.mouse_parts[i], 0, [(Ghost.rotation%2 == 0) ? ((Ghost.rotation == 0) ? 1 : -1) : 0, (Ghost.rotation%2 == 0) ? 0 : ((Ghost.rotation > 1) ? -1 : 1), 0]);

                // update color
                var color = CanPlayerBuildHere(Ghost.local_pid, pos, isNaN(i) ? Ghost.length : 1, isNaN(i) ? Ghost.width : 1) ? [0, 182, 0] : [182, 0, 0];
                if(Ghost.name == "sell") {color = [255, 230, 60];}
			    var build_range = CustomNetTables.GetTableValue("static_info", "generic").build_distance;
			    var hero_pos = Entities.GetAbsOrigin(Players.GetPlayerHeroEntityIndex(Ghost.local_pid) || -1);
			    if(build_range && hero_pos && Math.pow(build_range, 2) < Math.pow(pos[0]-hero_pos[0], 2)+Math.pow(pos[1]-hero_pos[1], 2))
			    	color = [color[0]/2, color[1]/2, color[2]/2];  // if this particle is out of the build range, darken it

			   	Particles.SetParticleControl(Ghost.mouse_parts[i], 2, color);
            }

			//** grid particles **//
			for(var i in Ghost.grid_table) {
				if(IsOnScreen(Ghost.grid_table[i][0])) {  // if this tile is on screen
					if(!Ghost.grid_parts[i]) {  // and there isn't a particle for it already
			            // create the particle
			            var part = Particles.CreateParticle("particles/building_ghost/tile_outline_sprite.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, -1);
			            Particles.SetParticleControl(part, 0, Ghost.grid_table[i][0]);
			            Particles.SetParticleControl(part, 2, Ghost.grid_table[i][1]);

			            // store the particle
			            Ghost.grid_parts[i] = part;
			        }
				} else {  // otherwise remove the particle since it's off-screen
					if(Ghost.grid_parts[i]) {  // you know - if it's there
						// remove the particle
		        		Particles.DestroyParticleEffect(Ghost.grid_parts[i], true);
        				Particles.ReleaseParticleIndex(Ghost.grid_parts[i]);

        				// mark this array position as having no particle
        				Ghost.grid_parts[i] = null;
					}
				}
			}

			// run this function 60 times a second
			$.Schedule(1/60, UpdateGhost);
		}
	}
}

function OnHideGhost() {
    // clear the current ghost name
    Ghost.name = null;

    // clear the length and width
    Ghost.length = 1;
    Ghost.width  = 1;

    // remove the mouse & grid particles
    RemoveParticles(Ghost.range_indicator);
    RemoveParticles(Ghost.mouse_parts);
    RemoveParticles(Ghost.grid_parts );
    Ghost.range_indicator = null;
    Ghost.mouse_parts = [];
    Ghost.grid_parts  = [];

    function RemoveParticles(part_array) {
    	if(typeof part_array == "number")
    		part_array = [part_array];
    	for(var i in part_array) {
    		if(!part_array[i]) {continue;}  // if we already removed this particle
	        Particles.DestroyParticleEffect(part_array[i], true);
	        Particles.ReleaseParticleIndex(part_array[i]);
	    }
    }
}

function OnMouseEvent(type, key_id) {
	if(Ghost.name) {
	    if(type == "pressed" && (key_id == 0 || key_id == 1)) {
	        // left click: buy\sell
	        if(key_id == 0)
	            Drag();

	        // right click: cancel   FIXME: remove when(if) i get the 'oncancel' event working
	        if(key_id == 1)
	            Config.Events.FireEvent("hide_ghost", {});

	        // consume the mouse event
	        return true;
	    }

	    if(type == "wheeled") {      // FIXME: i can't override zooming in\out with scroll, so maybe some backup keys for this function?
	    	// wheel up - rotate counterclockwise
	    	if(key_id > 0) {
	    		Ghost.rotation += 1;
	    		Ghost.rotation = (Ghost.rotation > 3) ? 0 : Ghost.rotation;
	    	}
	    	// wheel down - rotate clockwise
	    	else if(key_id < 0) {
	    		Ghost.rotation -= 1;
	    		Ghost.rotation = (Ghost.rotation < 0) ? 3 : Ghost.rotation;
	    	}

	        // consume the mouse event
	        return true;
	    }
	}

    function Drag() {
	    if(!GameUI.IsMouseDown(0) || !Ghost.name) {
	        if(!GameUI.IsShiftDown())
	            Config.Events.FireEvent("hide_ghost", {});
	        Ghost.last_pos = null;
	        return;
	    }

	    if(Ghost.name == "sell") {
		    // get the entity under the cursor
		    var ent_array = GameUI.FindScreenEntities(GameUI.GetCursorPosition());
		    var ent_index = (ent_array[0] && ent_array[0].entityIndex) ? ent_array[0].entityIndex : null;

		    // if it exists, is a trap, and isn't owned by -someone-else- the enemy?, attempt to sell it
		    if(ent_index && CustomNetTables.GetTableValue("npc_traps", Entities.GetUnitName(ent_index)) && !Entities.IsEnemy(ent_index))
		        SellTrap(ent_index);
	    } else {
	    	var current_pos = SnapBoxToGrid2D(MouseWorldPos(), Ghost.length, Ghost.width);
	    	if((!Ghost.last_pos || Math.abs(Ghost.last_pos[0]-current_pos[0]) >= Ghost.length*64 || Math.abs(Ghost.last_pos[1]-current_pos[1]) >= Ghost.width*64) &&
	    	CanPlayerBuildHere(Ghost.local_pid, current_pos, Ghost.length, Ghost.width)) {
	    		BuyTrap(Ghost.name, current_pos, Ghost.rotation);
				Ghost.last_pos = current_pos;
	    	}
	    }

	    // keep on chugging
	    $.Schedule(1/60, function() {Drag();});
    }
}



/****************************/
/*  Supplemental Functions  */
/****************************/
function MouseWorldPos() {
	var position = GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition());
	if(!position)
		position = [1000000, 1000000, 1000000];  // if we don't have a position, we basically want to return something off the map
    return position;
}

function IsOnScreen(position_ref) {
    var screen_x = Game.WorldToScreenX(position_ref[0], position_ref[1], position_ref[2]);
    var screen_y = Game.WorldToScreenY(position_ref[0], position_ref[1], position_ref[2]);

    if(screen_x < 0 || Game.GetScreenWidth() < screen_x || screen_y < 0 || Game.GetScreenHeight() < screen_y)
        return false;
    return true;
}

function BuyTrap(trap_name, position, rotation) {
    GameEvents.SendCustomGameEventToServer("trapwars_buy_trap", {
        name     : trap_name,
        playerid : Players.GetLocalPlayer(),
        position : position,
        rotation : rotation
    });
}

function SellTrap(entity_index) {
    GameEvents.SendCustomGameEventToServer("trapwars_sell_trap", {
        playerid : Players.GetLocalPlayer(),
        entindex : entity_index
    });
}



/****************************/
/*  Grid Related Functions  */
/****************************/
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

function GetGridPosition(index) {
    var grid = CustomNetTables.GetTableValue("static_info", "grid");
    var position = [grid.start[1] + 64*(index%grid.width), grid.start[2] + 64*Math.floor(index/grid.length)];
    // FIXME: right now there's no way to get the ground height in javascript
    //return [position[0], position[1], FIXME_GROUND_HEIGHT(position)];

    // particle initalizer "Position Modify Place On Ground" will only work if said particle is above the current ground height
    // therefore we'll just return this height as a really high number
    //return [position[0], position[1], 10000];

    // scratch that, doing particle schenanigans
    return [position[0], position[1], 0];
}

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
    var plot = CustomNetTables.GetTableValue("plots", ""+plot_number);

    if(plot && typeof plot.pid == "number" && plot.pid == playerid) {return true;}
    return false;
}

function CanPlayerBuildHere(playerid, position_ref, length, width) {
    length = Math.ceil(length), width = Math.ceil(width);
    var position    = SnapBoxToGrid2D([position_ref[0], position_ref[1], position_ref[2]], length, width);
    var start_index = GetGridIndex([position[0]-length*32+32, position[1]-width*32+32, position[2]]);

    // starting at the lower left corner, iterate through the grid tiles in this box
    for(i=0; i<length*width; i++) {
        var index = start_index + i%length + Math.floor(i/width)*CustomNetTables.GetTableValue("static_info", "grid").width;
        var tile = CustomNetTables.GetTableValue("ground_grid", ""+index);

        // if we don't have a tile here, OR the tile's team doesn't match our player's,
        // OR we have a plot # that isn't claimed by our player, OR there's a trap here already, THEN return false
        if(!tile || tile.team != Players.GetTeam(playerid) || (tile.plot && !DoesPlayerHavePlot(playerid, tile.plot)) || (tile.trap && Entities.IsValidEntity(tile.trap)))
            return false;
    }

    return true;
}