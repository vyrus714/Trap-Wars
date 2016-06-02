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