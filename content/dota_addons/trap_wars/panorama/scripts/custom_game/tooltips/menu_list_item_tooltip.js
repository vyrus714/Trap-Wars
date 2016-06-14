(function() {
    var Config = GameUI.CustomUIConfig();
    var panel = $.GetContextPanel();

    // set the info
    Config.SetChildTextTraverse(panel, "title_text"      , $.Localize(panel._args.title      ));
    Config.SetChildTextTraverse(panel, "gold_text"       , $.Localize(panel._args.gold       ));
    Config.SetChildTextTraverse(panel, "class_text"      , $.Localize(panel._args.class      ));
    Config.SetChildTextTraverse(panel, "menu_description", $.Localize(panel._args.description));

    Config.SetChildStyleTraverse(panel, "class_text", "color", $.Localize(panel._args["class"]+"_color"));
    Config.SetChildStyleTraverse(panel, "header_image", "background-image", "url('"+panel._args.image+"');");

    // set the position if it's passed  FIXME: possibly abstract this out to a separate file (and do the space stuff below if so) - fine as is, noone else needs custom tooltips anyway
    if(panel._args && panel._args.reference) {
        var position = panel._args.reference.GetPositionWithinWindow();
        var width = panel._args.reference.actuallayoutwidth;
        //var height = panel._args.reference.actuallayoutheight;
        //var pan_height = panel.actuallayoutheight;

        if(position && width) { //&& height && pan_height) {
            // FIXME: add in a $.Schedule to wait until the tooltip has been created so we can check its dimensions
            // for available screen space, and switch around the side of the panel
            panel.style.position = (position.x + width) + "px " + position.y + "px 0px";
        }
    }
})();