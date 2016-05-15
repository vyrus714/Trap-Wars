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

    // *** set up trap menu *** //
    for(var k in npc_traps) {
        // info about this trap, with fallbacks
        var info = {
            "image": npc_traps[k].Image || "file://{images}/custom_game/empty_slot_avatar.png",
            "title": k || "unknown_item",
            "gold" : npc_traps[k].GoldCost || 0,
            "class": npc_traps[k].Class || "c_unknown",
            "description": k+"_description" || "unknown_item",
            "health": npc_traps[k].StatusHealth || "",
            "mana"  : npc_traps[k].StatusMana || "",
            "damage": (npc_traps[k].AttackDamageMin+npc_traps[k].AttackDamageMax)/2 || "",
            "armor" : npc_traps[k].ArmorPhysical || "-",
            "speed" : npc_traps[k].MovementSpeed || "-"
        }
        info.abilities = [];
        for(var j=0; j<npc_traps[k].AbilityLayout; j++) {
            var ability = npc_traps[k]["Ability"+(j+1)];
            if(typeof ability == "string" && ability.length > 0) {info.abilities.push(ability);}
        }


        // find the parent
        var fake_parent = $("#list1");
        if(!fake_parent) {continue;}

        if     (info.class == "c_damage") {var real_parent = fake_parent.FindChild("column_1");}
        else if(info.class == "c_stun"  ) {var real_parent = fake_parent.FindChild("column_2");}
        else if(info.class == "c_slow"  ) {var real_parent = fake_parent.FindChild("column_3");}
        else if(info.class == "c_move"  ) {var real_parent = fake_parent.FindChild("column_4");}
        else                              {var real_parent = fake_parent.FindChild("column_5");}
        if(!real_parent) {continue;}

        // now create the panel
        var panel = $.CreatePanel("Button", real_parent, k);
        panel.AddClass("list_trap_item");
        // if we have an image for this trap (we should), override the base image
        if(typeof npc_traps[k].Image === "string") { panel.style["background-image"]="url('"+npc_traps[k].Image+"');"; }

        // create tooltips and pass them info
        panel.SetPanelEvent("onmouseover", (function(a, b) {return function() {
            GameUI.CustomUIConfig().Events.FireEvent("show_tooltip", {id:a, layout:"file://{resources}/layout/custom_game/tooltips/menu_list_item_tooltip.xml", args:b});
            GameUI.CustomUIConfig().Events.FireEvent("show_tooltip", {id:"help_tooltip", layout:"file://{resources}/layout/custom_game/tooltips/item_help_tooltip.xml"});
        }})(panel.id+"_tooltip", info));
        panel.SetPanelEvent("onmouseout", (function(a) {return function() {
            GameUI.CustomUIConfig().Events.FireEvent("hide_tooltip", {id:a});
            GameUI.CustomUIConfig().Events.FireEvent("hide_tooltip", {id:"help_tooltip"});
        }})(panel.id+"_tooltip"));

        // set the action on left click (onactivate)
        panel.SetPanelEvent("onactivate", (function(a){ return function(){
            ShowListItem(a);
        }}(panel.id)));
        // set the action on right click (oncontextmenu)
        panel.SetPanelEvent("oncontextmenu", (function(b){ return function(){
            GameUI.CustomUIConfig().Events.FireEvent("show_ghost", {
                //entity: a,
                name: b
            });
        }}(k)));  // FIXME: buy trap etc etc


        // create the display
        var display_item = $.CreatePanel("Panel", $("#display1"), k+"_display");
        display_item.BLoadLayout("file://{resources}/layout/custom_game/menu/menu_display_item.xml", false, false);

        // fill it with info
        SetChildPropAndGreyOutParent(display_item, "health", "text", info.health);
        SetChildPropAndGreyOutParent(display_item, "mana"  , "text", info.mana  );
        SetChildPropAndGreyOutParent(display_item, "damage", "text", info.damage);
        SetChildPropAndGreyOutParent(display_item, "armor" , "text", info.armor );
        SetChildPropAndGreyOutParent(display_item, "speed" , "text", info.speed );

        // add ability icons and tooltips
        for(var j=0; j<info.abilities.length; j++) {
            // get the skill panel, or create a new one if we're past 4 skills (FIXME: implement scrolling to display >4 skills)
            var skill;
            if(j < 4) {
                skill = display_item.FindChildTraverse("skill_"+(j+1));
            } else {
                skill = $.CreatePanel("DOTAAbilityImage", display_item.FindChildTraverse("skills"), "skill_"+(j+1));
                skill.AddClass("display_info_skill");
            }
            // set the icon
            skill.abilityname = info.abilities[j];
            // add the tooltips
            skill.SetPanelEvent("onmouseover", (function(a, b) {return function(){ $.DispatchEvent("DOTAShowAbilityTooltip", a, b); }})(skill, info.abilities[j]));
            skill.SetPanelEvent("onmouseout", (function(a, b) {return function(){ $.DispatchEvent("DOTAHideAbilityTooltip"); }})());
        }
    }

    // *** Set up creep list *** //
    incr=1;
    for(var k in npc_creeps) {
        // create the panel
        var panel = $.CreatePanel("Button", $("#list2"), k);
        panel.BLoadLayout("file://{resources}/layout/custom_game/menu/menu_list_item.xml", false, false);

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
        display_item.BLoadLayout("file://{resources}/layout/custom_game/menu/menu_list_item.xml", false, false);
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
        display_item.BLoadLayout("file://{resources}/layout/custom_game/menu/menu_display_item.xml", false, false);


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


    // select the trap tab button
    var panel = $("#tab1_btn");
    if(panel != null) { panel.checked=true; }

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
    for(var i=0; i<Object.keys(player_creeps).length; i++) {
        var creep_id = player_creeps[i+1];

        // set the creep slot icons
        var image = "url('file://{images}/custom_game/empty_slot_avatar.png')";
        if(creep_id != 0 && npc_creeps[creep_id] != null && npc_creeps[creep_id].Image != null) {
            image = "url('"+npc_creeps[player_creeps[i+1]].Image+"')"; }
        var creep_slot = $("#slot_"+(i+1));
        if(creep_slot != null) { creep_slot.style["background-image"]=image; }

        // set the creep display contents
        

        // set the creep upgrade tab contents

    }
}


/*******************/
/* Setup Functions */
/*******************/
function SetChildProperty(parent, child_id, property_name, property_value) {
    if(parent == null) {return false;}

    // get the child
    var child = parent.FindChildTraverse(child_id);
    if(child == null) {return false;}

    // if the property exists, set it 
    if(child[property_name] == null) {return false;}
    child[property_name] = property_value;

    return true;
}

function SetChildPropAndGreyOutParent(parent, child_id, property_name, property_value) {
    var test = SetChildProperty(parent, child_id, property_name, property_value);
    if(test && (property_value <= 0 || property_value == "" || property_value == "-")) {
        parent.FindChildTraverse(child_id).GetParent().style.opacity = 0.8;
        parent.FindChildTraverse(child_id).GetParent().style.brightness = 0.2;
        parent.FindChildTraverse(child_id).GetParent().style.saturation = 0;
    }
}


/****************/
/* UI Functions */
/****************/

function ShowThisSiblingPanel(panel, visible_class) {
    //remove visibility from all tabs
    var parent = panel.GetParent();
    var panels = parent.FindChildrenWithClassTraverse(visible_class);
    for(var i in panels) {
        panels[i].RemoveClass(visible_class);
    }
    // set the given tab as visible
    panel.AddClass(visible_class);
}

function SwitchToBodyTab(tab_id) {
    var tab = $("#"+tab_id);
    if(tab == null) { return; }
    ShowThisSiblingPanel(tab, "body_tab_visible");
}

function SwitchToCreepTab(tab_number) {
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

function ShowListItem(item_id) {
    // get the item
    var item = $("#"+item_id);

    // get the current list
    var list_column = item.GetParent();
    if(list_column == null) {return false;}
    var list = list_column.GetParent();
    if(list == null) {return false;}


    // find the items in this list
    var list_items;
    if(list.id == "list1") {
        list_items = list.FindChildrenWithClassTraverse("list_trap_item");
    } else if (list.id == "list2") {
        list_items = list.FindChildrenWithClassTraverse("list_item")
    } else {return false;}

    // hide highlighting of the other list items
    for(var i in list_items) { list_items[i].checked=false; }
    // show highlighting on this list item
    item.checked = true;


    // get this item's display panel, if we can't find it, then we're done here i guess
    var display;
    if(list.GetParent().FindChild("display1")) {
        display = list.GetParent().FindChild("display1");
    } else if(list.GetParent().FindChild("display2")) {
        display = list.GetParent().FindChild("display2");
    } else {return;}


    // hide all of the children of the display panel
    var display_items = display.Children();
    for(var i in display_items) {
        display_items[i].RemoveClass("display_item_visible");
    }

    // un-hide the desired child
    var current_item = display.FindChild(item_id+"_display");
    if(current_item != null) {
        current_item.AddClass("display_item_visible");
    }
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
function DeepPrintObject(object, indent) {
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