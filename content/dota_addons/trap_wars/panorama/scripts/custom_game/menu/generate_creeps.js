var Config = GameUI.CustomUIConfig();


(function() {
    // generate panels for each creep
    for(var k in Config.GetAllNetTableValues("trapwars_npc_herocreeps")) {
        var creep = CustomNetTables.GetTableValue("trapwars_npc_herocreeps", k);
        if(!creep) {continue;}


        // info about this creep for the UI
        var info = {
            "description": k+"_description"  || "unknown_item",
            "title" : k                      || "unknown_item",
            "image" : creep.Image            || "file://{images}/custom_game/empty_slot_avatar.png",
            "gold"  : creep.GoldCost         || 0,
            "class" : creep.Class            || "c_unknown",
            "health": creep.StatusHealth     || "",
            "mana"  : creep.StatusMana       || "",
            "armor" : creep.ArmorPhysical    || "-",
            "speed" : creep.MovementSpeed    || "-",
            "damage": (creep.AttackDamageMin+creep.AttackDamageMax)/2 || "",
        }

        // any abilities that this creep might have
        info.abilities = [];
        for(var j=0; j<(creep.AbilityLayout || 16); j++) {
            var ability = creep["Ability"+(j+1)];
            if(typeof ability == "string" && ability.length > 0) {info.abilities.push(ability);}
        }



        // find the list panel
        var list = $("#creep_list");
        if(!list) {continue;}


        // get the column panel for this class of creep  FIXME: removme colums and use (x, Y) floating positions directly under the list panel
        if     (info.class == "c_damage" || info.class == "c_heal") {var column = list.FindChild("column_1");}
        else if(info.class == "c_stun"  ) {var column = list.FindChild("column_2");}
        else if(info.class == "c_heavy" ) {var column = list.FindChild("column_3");}
        else if(info.class == "c_rush"  ) {var column = list.FindChild("column_4");}
        else                              {var column = list.FindChild("column_5");}
        if(!column) {continue;}


        // now create the panel
        var panel = $.CreatePanel("RadioButton", column, k);
        panel.BLoadLayoutFromString("<root><Panel class='list_item' group='creeps' /></root>", false, false);

        // if we have an image for this creep (we should), override the base image
        panel.style["background-image"] = "url('"+info.image+"');";

        // create tooltips and pass them info
        panel.SetPanelEvent("onmouseover", (function(a, b) {return function() {
            Config.Events.FireEvent("show_tooltip", {id:a, layout:"file://{resources}/layout/custom_game/tooltips/menu_list_item_tooltip.xml", args:b});
            Config.Events.FireEvent("show_tooltip", {id:"help_tooltip", layout:"file://{resources}/layout/custom_game/tooltips/item_help_tooltip.xml"});
        }})(panel.id+"_tooltip", info));
        panel.SetPanelEvent("onmouseout", (function(a) {return function() {
            Config.Events.FireEvent("hide_tooltip", {id:a});
            Config.Events.FireEvent("hide_tooltip", {id:"help_tooltip"});
        }})(panel.id+"_tooltip"));

        // set the left-click action
        panel.SetPanelEvent("onactivate", (function(a) {return function() {
            $("#"+a+"_display").checked = true;
        }}(panel.id)));

        // set the right-click action
        panel.SetPanelEvent("oncontextmenu", (function(b) {return function() {
            // FIXME: buy creep (not written yet)
        }}()));


        // create the "display" info panel
        var display_item = $.CreatePanel("RadioButton", $("#creep_display"), k+"_display");
        display_item.BLoadLayoutFromString("<root><Panel class='display_item' group='creep_display_items' /></root>", false, false);
        var display_item_child = $.CreatePanel("Panel", display_item, "");
        display_item_child.BLoadLayout("file://{resources}/layout/custom_game/menu/menu_display_item.xml", false, false);

        // fill it with info
        Config.SetChildTextTraverse(display_item, "health", info.health);
        Config.SetChildTextTraverse(display_item, "mana",   info.mana  );
        Config.SetChildTextTraverse(display_item, "damage", info.damage);
        Config.SetChildTextTraverse(display_item, "armor",  info.armor );
        Config.SetChildTextTraverse(display_item, "speed",  info.speed );

        // remove the dimming on panels with info in them
        Config.RemoveDimming(display_item.FindChildTraverse("health"));
        Config.RemoveDimming(display_item.FindChildTraverse("mana"  ));
        Config.RemoveDimming(display_item.FindChildTraverse("damage"));
        Config.RemoveDimming(display_item.FindChildTraverse("armor" ));        
        Config.RemoveDimming(display_item.FindChildTraverse("speed" ));

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
            skill.SetPanelEvent("onmouseover", (function(a, b) {return function() {$.DispatchEvent("DOTAShowAbilityTooltip", a, b);}})(skill, info.abilities[j]));
            skill.SetPanelEvent("onmouseout", (function(a, b) {return function() {$.DispatchEvent("DOTAHideAbilityTooltip");}})());
        } 
    }


    // generate panels for the creep slots
    var upgrade_panel = $("#upgrades");

    for(var i=0; i<(CustomNetTables.GetTableValue("trapwars_static_info", "generic").max_player_creeps || 6); i++) {
        // create the slot
        var slot = $.CreatePanel("RadioButton", $("#slot_container"), "slot_"+(i+1));
        slot.BLoadLayoutFromString("<root><Panel class='creep_slot' group='creeps' /></root>", false, false);
        // set the background image  FIXME: move entirely to creep_slot class; it's here for no reason
        slot.style["background-image"] = "url('file://{images}/custom_game/empty_slot_avatar.png')";
        // set the left click action
        //onactivate='$(\"#slot_"+(i+1)+"\").checked = true; $(\"#upgrade_"+(i+1)+"\").checked = true;'
        slot.SetPanelEvent("onactivate", (function(a) {return function() {
            $("#upgrade_"+a).checked = true;
            $("#slot_"+a+"_display").checked = true;
        }}(i+1)));

        // if it's not the last slot, add a spacer
        var spacer = $.CreatePanel("Panel", $("#slot_container"), "spacer");
        spacer.AddClass("creep_slot_spacer");


        // create the upgrade tab for this slot
        var upgrade = $.CreatePanel("RadioButton", $("#upgrades"), "upgrade_"+(i+1));
        upgrade.BLoadLayoutFromString("<root><Panel class='creep_tab' group='upgrades' /></root>", false, false);
        //FIXME: this is for testing only
        var testpanel = $.CreatePanel("Label", upgrade, "testpanel");
        testpanel.AddClass("button_text");
        testpanel.text = "Upgrade Tab #"+(i+1);

        // create the display panel for this slot
        var display_item = $.CreatePanel("RadioButton", $("#creep_display"), "slot_"+(i+1)+"_display");
        display_item.BLoadLayoutFromString("<root><Panel class='display_item' group='creep_display_items' /></root>", false, false);
        var display_item_child = $.CreatePanel("Panel", display_item, "");
        display_item_child.BLoadLayout("file://{resources}/layout/custom_game/menu/menu_display_item.xml", false, false);
    }
}());

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