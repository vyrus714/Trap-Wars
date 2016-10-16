function SwitchToTab(tab_name) {
	GameUI.CustomUIConfig().Events.FireEvent("switch_tab", {name: tab_name});
}

function OnTabButton1Loaded() {
	// get the button
	var button = $("#tab_button_1");
	if(!button) {return;}

	// set the button to selected
	button.checked = true;

	// set the initial tab, in about 2 frames
	$.Schedule(1/15, function() {SwitchToTab('tab_1');});
}