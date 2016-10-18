// boilerplate
var Config = GameUI.CustomUIConfig();


// subscribe to some events
Config.Events.SubscribeEvent("switch_tab", OnTabSwitched);
Config.Events.SubscribeEvent("toggle_menu", OnMenuToggled);
Config.Events.SubscribeEvent("update_info_panel", OnInfoPanelUpdated);

function OnTabSwitched(args) {
	// make sure we have a tab to switch to
	if(!args.name) {return;}

	// find the tab container, if we can't find it, return
	var tab_container = $("#tab_container");
	if(!tab_container) {return;}

	// find the tab we want to switch to, as a child of the tab container, if we can't find it, return
	var tab = tab_container.FindChild(args.name);
	if(!tab) {return;}

	// set the tab as the selected tab (they're RadioButton panels, so this switches the css :selected block on)
	tab.checked = true;
}

function OnMenuToggled(args) {
	// FIXME: implement this shiz
}

function OnInfoPanelUpdated(args) {  // args: title, gold, class, health, mana, damage, armor, speed, skill_[1-4]
	// get the info panel
	var panel = $("#info_panel");
	if(!panel) {return;}

	// set the default values we expect from the args table
	var defaults = {
		title : "unknown_item",
		gold  : "0",
		class : "c_unknown",
		bars  : "",
		stats : "-",
		skill : "transparent_ability_icon"
	};

    // fill in the info
    Config.SetChildTextTraverse (panel, "title",       $.Localize(args.title || defaults.title));
    Config.SetChildTextTraverse (panel, "title_gold",             args.gold  || defaults.gold  );
    Config.SetChildTextTraverse (panel, "title_class", $.Localize(args.class || defaults.class));
    Config.SetChildStyleTraverse(panel, "title_class", "color", $.Localize((args.class || defaults.class)+"_color"));

    Config.SetChildTextTraverse(panel, "bar_health", args.health || defaults.bars);
    Config.SetChildTextTraverse(panel, "bar_mana",   args.mana   || defaults.bars);

    Config.SetChildTextTraverse(panel, "stat_damage", args.damage || defaults.stats);
    Config.SetChildTextTraverse(panel, "stat_armor",  args.armor  || defaults.stats);
    Config.SetChildTextTraverse(panel, "stat_speed",  args.speed  || defaults.stats);

    Config.SetChildAbilitynameTraverse(panel, "skill_1", args.skill_1 || defaults.skill);
    Config.SetChildAbilitynameTraverse(panel, "skill_2", args.skill_2 || defaults.skill);
    Config.SetChildAbilitynameTraverse(panel, "skill_3", args.skill_3 || defaults.skill);
    Config.SetChildAbilitynameTraverse(panel, "skill_4", args.skill_4 || defaults.skill);

    // add tooltips to any ability icons that we have
    SetTooltip("skill_1", args.skill_1);
    SetTooltip("skill_2", args.skill_2);
    SetTooltip("skill_3", args.skill_3);
    SetTooltip("skill_4", args.skill_4);

	// set dimming for bars \ stats
	SetDimmingLevel( "bar_health" );
	SetDimmingLevel( "bar_mana"   );

	SetDimmingLevel( "stat_damage");
	SetDimmingLevel( "stat_armor" );
	SetDimmingLevel( "stat_speed" );


	// temp funcs
	function SetTooltip(sub_panel_name, skill_name) {
		// get the sub panel
		var sub_panel = panel.FindChildTraverse(sub_panel_name);
		if(!sub_panel) {return;}

		// if we have a skill name, use it to set the tooltip, otherwise remove any existing tooltip
		if(skill_name) {
        	sub_panel.SetPanelEvent("onmouseover", (function(a, b) {return function(){ $.DispatchEvent("DOTAShowAbilityTooltip", a, b); }})(sub_panel, skill_name));
        	sub_panel.SetPanelEvent("onmouseout", (function(a, b) {return function(){ $.DispatchEvent("DOTAHideAbilityTooltip"); }})());
    	} else {
    		sub_panel.ClearPanelEvent("onmouseover");
    		sub_panel.ClearPanelEvent("onmouseout");
    	}
	}

	function SetDimmingLevel(sub_panel_name) {
		// get the sub panel
		var sub_panel = panel.FindChildTraverse(sub_panel_name);
		if(!sub_panel) {return;}

		// get the sub panel's text
		var text = sub_panel.text;

		// determine whether or not the text is one of the defaults
		var is_default = false;
		for(var k in defaults) {
			if(text == defaults[k]) {is_default = true;}
		}

		// if the text is one of the defaults, turn on dimming, otherwise turn off dimming (diming parent\container)
		var parent = sub_panel.GetParent();
		if(!parent) {return;}

		parent.SetHasClass("dim_panel", is_default);
	}
}

// local functions
function LoadLayout(panel_name, layout_file) {
	// get the panel
	var panel = $('#' + panel_name);
	if(!panel) {return;}

	// attempt to load the layout
	panel.BLoadLayout(layout_file, false, false);
}

function OnLoadTabButtons() {LoadLayout("tab_buttons", "file://{resources}/layout/custom_game/menu2/tab_selection_buttons.xml");}
function OnLoadTab1      () {LoadLayout("tab_1"      , "file://{resources}/layout/custom_game/menu2/tab_traps.xml"     		  );}
function OnLoadTab2      () {LoadLayout("tab_2"      , "file://{resources}/layout/custom_game/menu2/tab_creeps.xml"    		  );}
function OnLoadInfoPanel () {LoadLayout("info_panel" , "file://{resources}/layout/custom_game/menu2/info_panel.xml" 		  );}