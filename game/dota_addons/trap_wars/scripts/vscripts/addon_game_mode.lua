-- setup file
require('setup')

-- precache resources
function Precache( context )
    -- models
    PrecacheModel( "models/items/alchemist/alchemeyerflask/alchemeyerflask.vmdl", context)
  	PrecacheModel( "models/props_structures/good_statue001.vmdl", context)
  	PrecacheModel( "models/props_structures/radiant_statue001.vmdl", context)
  	PrecacheModel( "models/props_structures/radiant_statue002.vmdl", context)
    -- particles
  	PrecacheResource("particle", "particles/line_stars_continuous.vpcf", context)
  	PrecacheResource("particle", "particles/line_stars_burst.vpcf", context)
  	PrecacheResource("particle", "particles/overhead_indicator_1.vpcf", context)
    PrecacheResource("particle", "particles/overhead_indicator_1_b.vpcf", context)
    PrecacheResource("particle", "particles/overhead_flame.vpcf", context)
    -- units
    PrecacheUnitByNameSync("npc_trapwars_trap_spike", context)
    PrecacheUnitByNameSync("npc_trapwars_trap_firevent", context)
    PrecacheUnitByNameSync("npc_trapwars_creep_kobol_basic", context)
    PrecacheUnitByNameSync("npc_trapwars_creep_kobol_spear", context)

    --[[ Precache examples from baresbones ... so i can stop looking it up every 2 seconds
    -- Particles can be precached individually or by folder
    -- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
    PrecacheResource("particle", "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", context)
    PrecacheResource("particle_folder", "particles/test_particle", context)

    -- Models can also be precached by folder or individually
    -- PrecacheModel should generally used over PrecacheResource for individual models
    PrecacheResource("model_folder", "particles/heroes/antimage", context)
    PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
    PrecacheModel("models/heroes/viper/viper.vmdl", context)

    -- Sounds can precached here like anything else
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)

    -- Entire items can be precached by name
    -- Abilities can also be precached in this way despite the name
    PrecacheItemByNameSync("example_ability", context)
    PrecacheItemByNameSync("item_example_item", context)

    -- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
    -- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
    PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
    PrecacheUnitByNameSync("npc_dota_hero_enigma", context)
    ]]
end

-- Create the game mode when we activate
function Activate()
  	GameRules.GameMode:InitGameMode()
end