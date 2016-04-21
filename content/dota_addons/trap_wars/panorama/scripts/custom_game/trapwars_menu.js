/**********************/
/* First Time Startup */
/**********************/

// get netnettable values
var npc_herocreeps = GetAllNetTableValues("trapwars_npc_herocreeps");
var npc_traps = GetAllNetTableValues("trapwars_npc_traps");

function GetAllNetTableValues( table_name ) {
    var table = CustomNetTables.GetAllTableValues(table_name);
    var new_table = {};

    for(var k in table) {
        new_table[table[k].key] = table[k].value;
    }

    return new_table;
}

// mess with some panel stuff on UI creation
$.Schedule(0.1, function() {
    // set the default tab-button, since xml was buggy
    var panel = $("#tab1_btn");
    if(panel === undefined || panel === null) {return;}
    panel.checked = true;


    // generate menu content based on nettable values
    SetupList($("#list1"), npc_traps);
    SetupList($("#list2"), npc_herocreeps);

    function SetupList( list_container, data_table ) {
        for(var k in data_table) {
            // create the panel
            var panel = $.CreatePanel("Panel", list_container, k);
            panel.BLoadLayout("file://{resources}/layout/custom_game/trapwars_menu_list_item.xml", false, false);

            // get info from the data table
            var info = data_table[k];
            if(typeof info.image !== "string") { info.image="file://{images}/custom_game/empty_slot_avatar.png"; }
            if(typeof info.class !== "string") { info.class="c_unknown"; }

            // add the icon
            var child = panel.FindChildTraverse("icon");
            child.SetImage(info.image);

            // add the title text
            child = panel.FindChildTraverse("title");
            child.text = $.Localize(k);

            // add the class text
            child = panel.FindChildTraverse("class");
            child.text = $.Localize(info.class);
            child.style["color"] = "red";  // FIXME: ??? part of info i guess, don't know

            // add the description text
            child = panel.FindChildTraverse("description");
            child.text = $.Localize(k+"_description");


            // test thing, brain make slow time
            //DeepPrintObject(panel);
            panel.SetPanelEvent("onactivate", function(){ TestFunc("now it works, sucker"); } );
        }
    }
})

function TestFunc( text ) { $.Msg(text); }



/****************/
/* UI Functions */
/****************/

function SwitchToTab( tab_id ) {
    // these are our tabs and buttons, make sure they line up
    var tabs = ["tab1",     "tab2"];
    var btns = ["tab1_btn", "tab2_btn"];

    // make sure the passed tab is real
    var foundtab = false;
    for(i=0; i<tabs.length; i++) {
        if(tab_id === tabs[i]) { foundtab=true; }
    }
    if(!foundtab) { return; }

    // get the panel of said tab
    var panel = $('#'+tab_id);
    if(panel == null) { return; }  // something fucked up ¯\_(ツ)_/¯

    // remove visibility from all of the tabs
    for(i=0; i<tabs.length; i++) {
        var temp_panel = $('#'+tabs[i]);
        if(temp_panel != null) { temp_panel.RemoveClass("body_tab_visible"); }
    }

    // add visibility to this specific tab
    panel.AddClass("body_tab_visible");
}

function ExpandUpgrades() {
    var upgrade_panel = $("#upgrades");
    var list_panel = $("#list2");
    var upgrade_btn = $("#upgrades_btn");

    upgrade_panel.ToggleClass("creep_upgrades_visible");
    list_panel.ToggleClass("list_hidden");
    upgrade_btn.ToggleClass("creep_upgrades_button_toggled");
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