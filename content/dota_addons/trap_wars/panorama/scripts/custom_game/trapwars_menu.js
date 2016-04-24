/**********************/
/* First Time Startup */
/**********************/

// get netnettable values
var game_values = CustomNetTables.GetTableValue("trapwars_static_info", "generic");
var npc_creeps  = GetAllNetTableValues("trapwars_npc_herocreeps");
var npc_traps   = GetAllNetTableValues("trapwars_npc_traps");
// dynamic values:
var player_creeps = CustomNetTables.GetTableValue("trapwars_player_creeps", ""+Players.GetLocalPlayer());
CustomNetTables.SubscribeNetTableListener("trapwars_player_creeps", OnPlayerCreepChange);


function GetAllNetTableValues( table_name ) {
    var table = CustomNetTables.GetAllTableValues(table_name);
    var new_table = {};

    for(var k in table) {
        new_table[table[k].key] = table[k].value;
    }

    return new_table;
}

// set up some panels on UI creation
$.Schedule(0.1, function() {
    // generate menu content based on nettable values //
    // set up trap list
    var incr = 1;
    for(var k in npc_traps) {
        // create the panel
        var panel = $.CreatePanel("Button", $("#list1"), k);
        panel.BLoadLayout("file://{resources}/layout/custom_game/trapwars_menu_list_item.xml", false, false);

        // get info from the data table
        var info = npc_traps[k];
        if(typeof info.Image !== "string") { info.Image="file://{images}/custom_game/empty_slot_avatar.png"; }
        if(typeof info.Class !== "string") { info.Class="c_unknown"; }
        if(typeof info.GoldCost !== "number") { info.GoldCost=0; }

        // add the icon
        var child = panel.FindChildTraverse("icon");
        child.SetImage(info.Image);
        // add the title text
        child = panel.FindChildTraverse("title");
        child.text = $.Localize(k);
        if(child.text.slice(0,3) === "npc") { child.text="Unknown Item"; }
        // add the class text
        child = panel.FindChildTraverse("class");
        child.text = $.Localize(info.Class);
        child.style.color = $.Localize(info.Class+"_color");  // FIXME: ??? part of info i guess, don't know
        // add the gold amount
        child = panel.FindChildTraverse("gold");
        child.text = info.GoldCost;
        // add the description text
        child = panel.FindChildTraverse("description");
        child.text = $.Localize(k+"_description");
        if(child.text.slice(0,3) === "npc") { child.text="No description."; }

        // set the action to perform when someone clicks on this list item
        panel.SetPanelEvent("onactivate", (function(j){return function(){ ShowListItem(j); }}(panel.id)) );

        // display_item for this list_item
        var display_item = $.CreatePanel("Panel", $("#display1"), k+"_display");
        display_item.BLoadLayout("file://{resources}/layout/custom_game/trapwars_menu_display_item.xml", false, false);
        var temp = display_item.FindChildTraverse("button_text");
        if(temp != null) { temp.text=k; }

        // remove the margin-bottom for the last item
        if(incr == Object.keys(npc_creeps).length) { panel.style["margin-bottom"]="0px"; }
        incr++;
    }

    // Set up creep list
    incr=1;
    for(var k in npc_creeps) {
        // create the panel
        var panel = $.CreatePanel("Button", $("#list2"), k);
        panel.BLoadLayout("file://{resources}/layout/custom_game/trapwars_menu_list_item.xml", false, false);

        // get info from the data table
        var info = npc_creeps[k];
        if(typeof info.Image !== "string") { info.Image="file://{images}/custom_game/empty_slot_avatar.png"; }
        if(typeof info.Class !== "string") { info.Class="c_unknown"; }
        if(typeof info.GoldCost !== "number") { info.GoldCost=0; }

        // add the icon
        var child = panel.FindChildTraverse("icon");
        child.SetImage(info.Image);
        // add the title text
        child = panel.FindChildTraverse("title");
        child.text = $.Localize(k);
        if(child.text.slice(0,3) === "npc") { child.text="Unknown Item"; }
        // add the class text
        child = panel.FindChildTraverse("class");
        child.text = $.Localize(info.Class);
        child.style.color = $.Localize(info.Class+"_color");  // FIXME: ??? part of info i guess, don't know
        // add the gold amount
        child = panel.FindChildTraverse("gold");
        child.text = info.GoldCost;
        // add the description text
        child = panel.FindChildTraverse("description");
        child.text = $.Localize(k+"_description");
        if(child.text.slice(0,3) === "npc") { child.text="No description."; }

        // set the action to perform when someone clicks on this list item
        panel.SetPanelEvent("onactivate", (function(j){return function(){ ShowListItem(j); }}(panel.id)) );

        // display_item for this list_item
        var display_item = $.CreatePanel("Panel", $("#display2"), k+"_display");
        display_item.BLoadLayout("file://{resources}/layout/custom_game/trapwars_menu_display_item.xml", false, false);
        var temp = display_item.FindChildTraverse("button_text");
        if(temp != null) { temp.text=k; }

        // remove the margin-bottom for the last item
        if(incr == Object.keys(npc_creeps).length) { panel.style["margin-bottom"]="0px"; }
        incr++;
    }

    // generate creep slots based on nettable values
    for(var i=0; i<game_values.max_player_creeps; i++) {
        // creep slot
        var creep_slot = $.CreatePanel("RadioButton", $("#slot_container"), "slot_"+(i+1));
        creep_slot.AddClass("creep_slot");
        creep_slot.group = "slots";
        creep_slot.style["background-image"] = "url('file://{images}/custom_game/empty_slot_avatar.png')";

        // set the action to perform when someone clicks on this list item
        creep_slot.SetPanelEvent("onactivate", (function(j){return function(){ SwitchToCreepTab(j+1); }}(i)) );


        // creep_tab for this creep slot
        var creep_tab = $.CreatePanel("Panel", $("#upgrades"), "creep_tab_"+(i+1));
        creep_tab.AddClass("creep_tab");

        // display_item for this creep slot
        var display_item = $.CreatePanel("Panel", $("#display3"), "tree_item_"+(i+1));
        display_item.BLoadLayout("file://{resources}/layout/custom_game/trapwars_menu_display_item.xml", false, false);


        // set the initial panels to visible:
        if(i==0) {
            creep_slot.AddClass("creep_slot_first");
            creep_slot.checked = true;
            creep_tab.AddClass("creep_tab_visible");
            display_item.AddClass("display_item_visible");
        }
        if(i == game_values.max_player_creeps-1) { creep_slot.AddClass("creep_slot_last"); }

        // FIXME: remove this, debug code only
        var test = $.CreatePanel("Label", creep_slot, "");
        test.AddClass("button_text");
        test.text = i+1;
        test = $.CreatePanel("Label", creep_tab, "");
        test.AddClass("button_text");
        test.text = i+1;
        test = display_item.FindChildTraverse("button_text");
        if(test != null) { test.text=i+1; }
    }


    // set some panels as selected at ui startup
    // tab button
    var panel = $("#tab1_btn");
    if(panel != null) { panel.checked=true; }
    
    // list_items
    var parent = $("#list1");
    if(parent != null) {
        panel = parent.GetChild(0);
        if(panel != null) {
            panel.checked = true;
            ShowListItem(panel.id);
        }
    }
    parent = $("#list2");
    if(parent != null) {
        panel = parent.GetChild(0);
        if(panel != null) {
            panel.checked = true;
            ShowListItem(panel.id);
        }
    }

    // set the creep slots/info on startup
    OnPlayerCreepChange();

    // more stuff! (when i get to it)
})

/**********************/
/* Nettable Listeners */
/**********************/
function OnPlayerCreepChange() {
    // update our local copy of this player's creeps
    player_creeps = CustomNetTables.GetTableValue("trapwars_player_creeps", ""+Players.GetLocalPlayer());

    // re-set all of the information based on player creeps
    for(var i=0; i<game_values.max_player_creeps; i++) {
        // set the creep slot icons
        var image = "url('file://{images}/custom_game/empty_slot_avatar.png')";
        if(player_creeps[i+1] != 0 && npc_creeps[player_creeps[i+1]] != null && npc_creeps[player_creeps[i+1]].Image != null) {
            image = "url('"+npc_creeps[player_creeps[i+1]].Image+"')"; }
        var creep_slot = $("#slot_"+(i+1));
        if(creep_slot != null) { creep_slot.style["background-image"]=image; }

        // set the creep display contents
        

        // set the creep upgrade tab contents
    }
}


/****************/
/* UI Functions */
/****************/

function ShowThisSiblingPanel( panel, visible_class ) {
    //remove visibility from all tabs
    var parent = panel.GetParent();
    var panels = parent.FindChildrenWithClassTraverse(visible_class);
    for(var i in panels) {
        panels[i].RemoveClass(visible_class);
    }
    // set the given tab as visible
    panel.AddClass(visible_class);
}

function SwitchToBodyTab( tab_id ) {
    var tab = $("#"+tab_id);
    if(tab == null) { return; }
    ShowThisSiblingPanel(tab, "body_tab_visible");
}

function SwitchToCreepTab( tab_number ) {
    // switch to this slot's tab in the upgrade tree
    var creep_tab = $("#creep_tab_"+tab_number);
    if(creep_tab != null) { ShowThisSiblingPanel(creep_tab, "creep_tab_visible"); }

    // if this slot has a creep in it, show its upgrade tree and display item 
    if(player_creeps[tab_number] != 0) {
        // show the upgrade tree
        ShowUpgrades();
        // show the display item
        var display_item = $("#tree_item_"+tab_number);
        if(display_item != null) { ShowThisSiblingPanel(display_item, "display_item_visible"); }
        // swap displays to the upgrades display
        $("#display2").RemoveClass("display_creeps_visible");
        $("#display3").AddClass("display_creeps_visible");
    } else {
        // hide the upgrade tree
        HideUpgrades();
        // swap displays back to the list display
        $("#display2").AddClass("display_creeps_visible");
        $("#display3").RemoveClass("display_creeps_visible");
    }
}

function ShowListItem( item_id ) {
    // get the item
    var item = $("#"+item_id);
    // get the current list
    var list = item.GetParent();
    if(list.id != "list1" && list.id != "list2") { $.Msg("no joy"); return; }


    // hide highlighting of the other list items in this list
    var list_items = list.Children();
    for(var i in list_items) { list_items[i].checked=false; }
    // show highlighting on this list item
    item.checked = true;


    // get this item's display panel, if we can't find it, then we're done here i guess
    var display;
    if(list.GetParent().FindChild("display1")) {
        display = list.GetParent().FindChild("display1");
    } else if(list.GetParent().FindChild("display2")) {
        display = list.GetParent().FindChild("display2");
    } else { return; }

    // hide all of the children of the display panel
    var display_items = display.Children();
    for(var i in display_items) {
        display_items[i].RemoveClass("display_item_visible");
    }

    // un-hide the desired child
    var current_item = display.FindChild(item_id+"_display");
    current_item.AddClass("display_item_visible");
}

function ShowUpgrades() {
    $("#list2").AddClass("list_hidden");
    $("#upgrades").AddClass("creep_upgrades_visible");
    $("#upgrades_btn").AddClass("creep_upgrades_button_toggled");
}

function HideUpgrades() {
    $("#list2").RemoveClass("list_hidden");
    $("#upgrades").RemoveClass("creep_upgrades_visible");
    $("#upgrades_btn").RemoveClass("creep_upgrades_button_toggled");
}

function ToggleUpgrades() {
    $("#list2").ToggleClass("list_hidden");
    $("#upgrades").ToggleClass("creep_upgrades_visible");
    $("#upgrades_btn").ToggleClass("creep_upgrades_button_toggled");
}

function ToggleMenu() {
    var menu = $('#menu');
    var toggle = $('#menu_toggle');

    if(toggle.checked) {
        toggle.checked = false;
        menu.style.position = "0px 0px 0px";
    } else {
        toggle.checked = true;
        menu.style.position = "419px 0px 0px";
    }
}




/****************/
/* misc / debug */
/****************/

// useful for finding out what is things
function DeepPrintObject( object, indent ) {
    if(typeof indent === "undefined") { indent="    "; $.Msg("{"); }

    for(var k in object) {
        if(typeof object[k] === "object") {
            $.Msg(indent+k+" {");
            DeepPrintObject(object[k], indent+"    ");
            $.Msg(indent+"}");
        } else {
            $.Msg(indent+k+": "+object[k]);
        }
    }

    if(indent === "    ") { $.Msg("}"); }
}