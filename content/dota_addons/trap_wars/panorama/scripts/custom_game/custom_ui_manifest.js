// scope for global functions and variables
var Config = GameUI.CustomUIConfig();

// Uncomment any of the following lines in order to disable that portion of the default UI

//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false );             //Time of day (clock).
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false );                //Heroes and team score at the top of the HUD.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false );         //Lefthand flyout scoreboard.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, false );              //Hero actions UI.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, false );            //Minimap.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, false );           //Entire Inventory UI
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false );            //Shop portion of the Inventory.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_ITEMS, false );           //Player items.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false );        //Quickbuy.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );         //Courier controls.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );         //Glyph.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD, false );            //Gold display.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, false );       //Suggested items shop panel.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_TEAMS, false );      //Hero selection Radiant and Dire player lists.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_GAME_NAME, false );  //Hero selection game mode name display.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_CLOCK, false );      //Hero selection clock.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_MENU_BUTTONS, false );          //Top-left menu buttons in the HUD.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false );                   //Endgame scoreboard.    
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_BACKGROUND, false );        //Top-left menu buttons in the HUD.


// local scope
/*(function(){  <-- Opting out of using this, going to pull values from the nettable on use
    // initialize local variables for our net table values
    Config.game_values = CustomNetTables.GetTableValue("trapwars_static_info", "generic") || {};
    Config.npc_creeps  = GetAllNetTableValues("trapwars_npc_herocreeps") || {};
    Config.npc_traps   = GetAllNetTableValues("trapwars_npc_traps") || {};
    Config.player_creeps = CustomNetTables.GetTableValue("trapwars_player_creeps", ""+Players.GetLocalPlayer()) || {};

    // register callbacks for values that need updating
    CustomNetTables.SubscribeNetTableListener("trapwars_player_creeps", OnPlayerCreepChange);
})();*/



// unfortunately CustomNetTables.GetAllTableValues() returns a table of key\value objects instead of the root table
Config.GetAllNetTableValues = function(table_name) {
    var table = CustomNetTables.GetAllTableValues(table_name);
    var new_table = {};

    for(var k in table) {
        new_table[table[k].key] = table[k].value;
    }

    return new_table;
};

// set the text value of a child panel
Config.SetChildTextTraverse = function(panel, child_name, text) {
    var child = panel.FindChildTraverse(child_name);
    if(!child) {return false;}

    child.text = text;
    return true;
}

// set a style property of a child panel
Config.SetChildStyleTraverse = function(panel, child_name, style_name, value) {
    var child = panel.FindChildTraverse(child_name);
    if(!child) {return false;}

    child.style[style_name] = value;
    return true;
}

// if a panel's text meets certain criteria, remove the dimming from it and its parent
Config.RemoveDimming = function(panel) {
    if(panel.text && 0 < panel.text && panel.text != "" && panel.text != "-") {
        panel.RemoveClass("dim_panel");
        panel.GetParent().RemoveClass("dim_panel");

        return true;
    }

    return false;
}


// Debug //

Config.PrintObject = function(object) {
    $.Msg("{");

    for(var k in object) {
        if(typeof object[k] == "function") {
            $.Msg("    ",k,": ",typeof object[k]);
        } else {
            $.Msg("    ",k,": ",object[k]);
        }
    }

    $.Msg("}");
};

Config.DeepPrintObject = function(object, indent) {
    if(typeof indent === "undefined") { indent="    "; $.Msg("{"); }

    for(var k in object) {
        if(typeof object[k] === "object") {
            $.Msg(indent+k+" {");
            this.DeepPrintObject(object[k], indent+"    ");
            $.Msg(indent+"}");
        } else {
            $.Msg(indent+k+": "+object[k]);
        }
    }

    if(indent === "    ") { $.Msg("}"); }
};