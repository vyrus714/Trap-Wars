require('libraries/util')
require('libraries/timers')

--require('game/grid')
require('game/spawning')
require('game/mapinfo')

require('setup')
require('gamemode')

function Precache( context )
	PrecacheModel( "models/items/alchemist/alchemeyerflask/alchemeyerflask.vmdl", context)
  	PrecacheModel( "models/props_structures/good_statue001.vmdl", context)
  	PrecacheModel( "models/props_structures/radiant_statue001.vmdl", context)
  	PrecacheModel( "models/props_structures/radiant_statue002.vmdl", context)

  	--PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_announcer.vsndevts", context)
end

-- Create the game mode when we activate
function Activate()
  	GameRules.GameMode = GameMode()
  	GameRules.GameMode:InitGameMode()
end