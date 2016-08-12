GameRules.GameMode = class({})

-- game mode file
require('gamemode')

-- entry point
function Activate()
    GameRules.GameMode:InitGameMode()
end

-- precache resources
function Precache( context )
    --// particles //--
    -- team portals
    PrecacheResource("particle", "particles/portal/portal.vpcf", context)
    PrecacheResource("particle", "particles/units/unit_greevil/loot_greevil_tgt_end.vpcf", context)
    -- building preview particles
    PrecacheResource("particle", "particles/building_ghost/ghost.vpcf", context)
    PrecacheResource("particle", "particles/building_ghost/sell_indicator.vpcf", context)
    PrecacheResource("particle", "particles/building_ghost/preview_dot.vpcf", context)
    PrecacheResource("particle", "particles/ui_mouseactions/range_display.vpcf", context)
    PrecacheResource("particle", "particles/building_ghost/tile_outline_sprite.vpcf", context)


    --// units //--
    -- traps
    PrecacheUnitByNameSync("npc_trapwars_floor_spikes", context)
    PrecacheUnitByNameSync("npc_trapwars_fire_vent", context)
    PrecacheUnitByNameSync("npc_trapwars_wood_fence", context)
    PrecacheUnitByNameSync("npc_trapwars_stone_wall", context)
    -- lane creeps
    PrecacheUnitByNameSync("npc_trapwars_supply_trooper_1", context)
    PrecacheUnitByNameSync("npc_trapwars_supply_trooper_2", context)
    PrecacheUnitByNameSync("npc_trapwars_supply_trooper_3", context)
    PrecacheUnitByNameSync("npc_trapwars_spear_trooper_1", context)
    PrecacheUnitByNameSync("npc_trapwars_spear_trooper_2", context)
    PrecacheUnitByNameSync("npc_trapwars_spear_trooper_3", context)
    PrecacheUnitByNameSync("npc_trapwars_shield_bearer_1", context)
    PrecacheUnitByNameSync("npc_trapwars_shield_bearer_2", context)
    PrecacheUnitByNameSync("npc_trapwars_shield_bearer_3", context)
    PrecacheUnitByNameSync("npc_trapwars_priest_1", context)
    PrecacheUnitByNameSync("npc_trapwars_priest_2", context)
    PrecacheUnitByNameSync("npc_trapwars_priest_3", context)


    --// sounds //--
    -- gamemode sounds FIXME: move these to their own sound event file
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_wisp.vsndevts", context)  -- for portal
    PrecacheResource("soundfile", "soundevents/game_sounds_ui_imported.vsndevts", context)              -- for menu


    --[[
    Precache examples from barebones ... so i can stop looking it up every 2 seconds

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