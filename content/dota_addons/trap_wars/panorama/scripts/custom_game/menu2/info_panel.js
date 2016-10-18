// boilerplate
var Config = GameUI.CustomUIConfig();


function OnUpgradeButton() {
    // FIXME: yea, do something with this
}

function OnSellButton() {
    // open the sell indicator
    Config.Events.FireEvent("show_ghost", {name: "sell"});
}