(function() {
    var panel = $.GetContextPanel();

    // set the info
    var child;

    child = panel.FindChildTraverse("header_image");
    child.style["background-image"] = "url('"+panel._args["image"]+"');";

    child = panel.FindChildTraverse("title_text");
    child.text = $.Localize(panel._args["title"]);

    child = panel.FindChildTraverse("gold_text");
    child.text = $.Localize(panel._args["gold"]);

    child = panel.FindChildTraverse("class_text");
    child.text = $.Localize(panel._args["class"]);
    child.style.color = $.Localize(panel._args["class"]+"_color");

    child = panel.FindChildTraverse("menu_description");
    child.text = $.Localize(panel._args["description"]);
})();