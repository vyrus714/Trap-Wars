var Config = GameUI.CustomUIConfig();

// create the traps!
GenerateTraps();
function GenerateTraps() {
    // get the top-level panel for this element
    var parent = $.GetContextPanel();
    if(!parent) {return;}

    // for each trap we know about, make a panel
    var known_creeps = CustomNetTables.GetAllTableValues("npc_herocreeps");
    for(var k in known_creeps) {
        if(!known_creeps[k].key || !known_creeps[k].value) {continue;}
        (function(a, b) {  // enclose each iteration of the loop within its own scope to stop JS schenanigans
            // get the trap information
            var trap_name = b[a].key;
            var trap_info = b[a].value;


            // create the panel & assign its class
            var trap_panel = $.CreatePanel("RadioButton", parent, trap_name);
            trap_panel.AddClass("grid_item");


            // set the panel position
            if(typeof trap_info.MenuX == "number" && typeof trap_info.MenuY == "number") {
                var position_string = "";
                position_string += Math.floor(trap_info.MenuX) * 65 + "px ";  // see tab_traps.css for these values
                position_string += Math.floor(trap_info.MenuY) * 65 + "px ";
                position_string += "0px;";

                trap_panel.style.position = position_string; 
            }
    

            // override the panel's background image if we have one on file
            if(trap_info.Image) {
                trap_panel.style["background-image"] = "url('" + trap_info.Image + "');";
            }


            // add the tooltip  FIXME: the tooltips are majorly broken, kill them with fire
            trap_panel.SetPanelEvent("onmouseover", function() {
                Config.Events.FireEvent("show_tooltip", {
                    id: trap_name+"_menu2",
                    layout: "file://{resources}/layout/custom_game/tooltips/menu_list_item_tooltip.xml",
                    args: {
                        reference: trap_panel,
                        image: trap_info.Image,
                        title: trap_name,
                        class: trap_info.Class || "c_unknown",
                        gold : trap_info.GoldCost,
                        description: trap_name+"_description",
                    },
                });
            });
            trap_panel.SetPanelEvent("onmouseout", function() {
                Config.Events.FireEvent("hide_tooltip", {id: trap_name+"_menu2"});
            });


            // left-click action: view the info for the panel down below
            trap_panel.SetPanelEvent("onactivate", function() {
                var on_activate_info = {
                    title   : trap_name,
                    gold    : trap_info.GoldCost,
                    class   : trap_info.Class,
                    health  : trap_info.StatusHealth,
                    mana    : trap_info.StatusMana,
                    damage  : (trap_info.AttackDamageMin+trap_info.AttackDamageMax)/2,
                    armor   : trap_info.ArmorPhysical,
                    speed   : trap_info.MovementSpeed,
                }

                // add any abilities that we find
                for(var i=0; i<(trap_info.AbilityLayout || 16); i++) {  // FIXME: find a constant for max hero abilities
                    var ability = trap_info["Ability"+(i+1)];  // FIXME: add a check for hidden abilities?
                    if(typeof ability == "string" && ability.length > 0) {on_activate_info["skill_"+(i+1)] = ability;}
                }

                // fire off the event
                Config.Events.FireEvent("update_info_panel", on_activate_info);
            });



            // right-click action: initiate the building ui
            trap_panel.SetPanelEvent("oncontextmenu", function() {
                Config.Events.FireEvent("show_ghost", {name: trap_name});
            });


        }) (k, known_creeps);
    }
}