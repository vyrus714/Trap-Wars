"use strict";

function TestButton( button_number ) {
  //$.Msg("JS: "+button_number)
  GameEvents.SendCustomGameEventToServer("test_button", { id: button_number });
}

function PrintObject( object, space ) {
	if( typeof space === 'undefined' ) {
		var space = "   ";
		$.Msg( "PrintObject():" );
	}
	else {
		var space = space + "   ";
	}

	for (var key in object) {
  		if(!object.hasOwnProperty(key)) {continue}

  		if(typeof object[key] !== 'undefined') {
  			if(typeof object[key] === 'object') {
  				$.Msg( space + "["+key+"].." );
  				PrintObject(object[key], space);
  			}
  			else { 
  				$.Msg( space + "["+key+"]" + object[key] );
  			}
  		}
  	}
}

function SpawnUnit() {
    var unit = $('#UnitText').text;
    GameEvents.SendCustomGameEventToServer("test_button", { id: 5, unit: unit });
}

function InspectElement( element_name ) {
    $.Msg(Object.keys($('#'+element_name)))
}

function HidePanel(panel_name) {
    var panel = $('#'+panel_name);
    if(panel.enabled) {
        panel.enabled = false;
        panel.style.visibility = "collapse";
    } else {
        panel.enabled = true;
        panel.style.visibility = "visible";
    }


}