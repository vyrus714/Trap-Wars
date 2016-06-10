var Config = GameUI.CustomUIConfig();


(function() {
    // generate panels for each trap
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

        // now create the panel
        var panel = $.CreatePanel("RadioButton", list, k);
        panel.BLoadLayoutFromString("<root><Panel class='list_item' group='traps' /></root>", false, false);

        // if we have an image for this trap (we should), override the base image
        panel.style["background-image"] = "url('"+info.image+"');";

        // set the position based on KV, if not given a position, slap it somewhere on the bottom
        var x = -100, y = -100;
        if(typeof trap.MenuX == "number" && typeof trap.MenuY == "number") {
            // SIMPLE HARDCODED VARS, ACTULALY SET IN CSS FILE!  ( box dimensions: 59px^2, padded by 10px )
            x = Math.floor(trap.MenuX*59 + trap.MenuX*9);  // FIXME: should be 10 ... but 9 looks 'better' - have to see when more shit is added
            y = Math.floor(trap.MenuY*59 + trap.MenuY*9);
        }
        panel.style["position"] = x+"px "+y+"px 0px;";


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
            $("#"+a+"_display").checked = true;
        }}(panel.id)));

        // set the right-click action
        panel.SetPanelEvent("oncontextmenu", (function(b){ return function(){
            Config.Events.FireEvent("show_ghost", {
                //entity: a,
                name: b
            });
        }}(k)));  // FIXME: buy trap etc etc <-- hmm, i might have done this in ghost.js accidentally, fuck


        // create the "display" info panel
        var display_item = $.CreatePanel("RadioButton", $("#trap_display"), k+"_display");
        display_item.BLoadLayoutFromString("<root><Panel class='display_item' group='trap_display_items' /></root>", false, false);
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
            skill.SetPanelEvent("onmouseover", (function(a, b) {return function(){ $.DispatchEvent("DOTAShowAbilityTooltip", a, b); }})(skill, info.abilities[j]));
            skill.SetPanelEvent("onmouseout", (function(a, b) {return function(){ $.DispatchEvent("DOTAHideAbilityTooltip"); }})());
        }
    }
}());