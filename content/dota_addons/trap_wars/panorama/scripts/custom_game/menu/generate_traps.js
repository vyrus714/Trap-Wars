var Config = GameUI.CustomUIConfig();


(function() {
    for(var k in Config.GetAllNetTableValues("trapwars_npc_traps")) {
        var trap = CustomNetTables.GetTableValue("trapwars_npc_traps", k);
        if(!trap) {continue;}


        // info about this trap for the UI
        var info = {
            "description": k+"_description" || "unknown_item",
            "title" : k                     || "unknown_item",
            "image" : trap.Image            || "file://{images}/custom_game/empty_slot_avatar.png",
            "gold"  : trap.GoldCost         || 0,
            "class" : trap.Class            || "c_unknown",
            "health": trap.StatusHealth     || "",
            "mana"  : trap.StatusMana       || "",
            "armor" : trap.ArmorPhysical    || "-",
            "speed" : trap.MovementSpeed    || "-",
            "damage": (trap.AttackDamageMin+trap.AttackDamageMax)/2 || "",
        }

        // any abilities that this trap might have
        info.abilities = [];
        for(var j=0; j<(trap.AbilityLayout || 16); j++) {
            var ability = trap["Ability"+(j+1)];
            if(typeof ability == "string" && ability.length > 0) {info.abilities.push(ability);}
        }


        // find the list panel
        var list = $("#trap_list");
        if(!list) {continue;}

        // get the column panel for this class of trap  FIXME: removme colums and use (x, Y) floating positions directly under the list panel
        if     (info.class == "c_damage") {var column = list.FindChild("column_1");}
        else if(info.class == "c_stun"  ) {var column = list.FindChild("column_2");}
        else if(info.class == "c_slow"  ) {var column = list.FindChild("column_3");}
        else if(info.class == "c_move"  ) {var column = list.FindChild("column_4");}
        else                              {var column = list.FindChild("column_5");}
        if(!column) {continue;}


        // now create the panel
        var panel = $.CreatePanel("Button", column, k);
        panel.AddClass("list_item");

        // if we have an image for this trap (we should), override the base image
        if(typeof trap.Image === "string") { panel.style["background-image"]="url('"+trap.Image+"');"; }

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
        panel.SetPanelEvent("onactivate", (function(a){ return function(){
            ShowListItem(a);
        }}(panel.id)));

        // set the right-click action
        panel.SetPanelEvent("oncontextmenu", (function(b){ return function(){
            Config.Events.FireEvent("show_ghost", {
                //entity: a,
                name: b
            });
        }}(k)));  // FIXME: buy trap etc etc <-- hmm, i might have done this in ghost.js accidentally, fuck


        // create the "display" info panel
        var display_item = $.CreatePanel("Panel", $("#trap_display"), k+"_display");
        display_item.BLoadLayout("file://{resources}/layout/custom_game/menu/menu_display_item.xml", false, false);

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
            skill.SetPanelEvent("onmouseover", (function(a, b) {return function(){ $.DispatchEvent("DOTAShowAbilityTooltip", a, b); }})(skill, info.abilities[j]));
            skill.SetPanelEvent("onmouseout", (function(a, b) {return function(){ $.DispatchEvent("DOTAHideAbilityTooltip"); }})());
        }
    }
}());