GameUI.CustomUIConfig().Events.SubscribeEvent("show_tooltip", OnShowTooltip);
GameUI.CustomUIConfig().Events.SubscribeEvent("hide_tooltip", OnHideTooltip);

function OnShowTooltip(keys) {
    if(keys.id == null || keys.layout == null) {return;}

    // if there's no panel by this id, make one
    var panel = $("#"+keys.id);
    if(panel == null) {panel = $.CreatePanel("Panel", $.GetContextPanel(), keys.id);}
    // pass any parameters to the panel
    panel._args = keys.args || {};
    // load the specified layout
    panel.BLoadLayout(keys.layout, false, false);

    // show the panel
    panel.enabled = true;
    panel.visible = true;
}

function OnHideTooltip(keys) {
    if(keys.id == null) {return;}

    // if there is a panel by this id, hide it
    var panel = $("#"+keys.id);
    if(panel != null) {
        panel.enabled = false;
        panel.visible = false;
    }
}