////////////////////////
// First Time Startup //
////////////////////////

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
$.Schedule(0.1, function(){
    // set the default tab-button, since xml was buggy
    var panel = $('#tab1_btn');
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
            var info = data_table[k].info;
            if(typeof info === "undefined") {
                info = {image: "file://{images}/custom_game/empty_slot_avatar.png", class: "#unknown"};
            } else {
                if(typeof info.image !== "string") { info.image="file://{images}/custom_game/empty_slot_avatar.png"; }
                if(typeof info.class !== "string") { info.class="#unknown"; }
            }

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
        }
    }
})



//////////////////
// UI Functions //
//////////////////

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

    // ok should be good! now set all of the other tabs in _tabs_ fully transparent
    for(i=0; i<tabs.length; i++) {
        var temp_panel = $('#'+tabs[i]);
        if(panel != temp_panel) {
            temp_panel.style["z-index"] = 0;
            temp_panel.style.opacity = 0;
        }
    }

    // and set our specific panel to fully opaque
    panel.style["z-index"] = 1;
    panel.style.opacity = 1;
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