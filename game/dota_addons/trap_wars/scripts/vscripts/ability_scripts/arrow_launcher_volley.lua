if not arrow_launcher_volley then arrow_launcher_volley = class({}) end

if IsServer() then
	function arrow_launcher_volley:OnSpellStart()
		local caster = self:GetCaster();

		-- emit the bow 'wind-up' sound: was fiddley, but this works OK-ish
		for i=1, 3 do
			Timers:CreateTimer(i*0.16, function()
			--Timers:CreateTimer(i*0.1, function()
				--EmitSoundOn("trap.arrowLauncher.volleyCharge2", caster)
				EmitSoundOn("trap.arrowLauncher.volleyCharge", caster)
			end)
		end

		-- wind-up particle effects   - this effect sucks, scrapping it for now; we'll see if animations are good
        --local part = ParticleManager:CreateParticle("particles/traps/arrow_launcher/launcher_charge.vpcf", PATTACH_CUSTOMORIGIN, nil)
        --ParticleManager:SetParticleControl(part, 0, caster:GetAbsOrigin())
	end

	function arrow_launcher_volley:OnChannelFinish()
		local caster = self:GetCaster()

		-- for each arrow
		for i=1, self:GetSpecialValueFor("count") do
			Timers:CreateTimer(RandomFloat(0, 0.2), function()
				-- play the launch sound effect
				EmitSoundOn("trap.arrowLauncher.volleyLaunch", caster)

				-- create the projectile
				local projectile = ProjectileManager:CreateLinearProjectile{
					Ability 			= self,
					Source 				= caster,
					EffectName			= "particles/traps/arrow_launcher/arrow.vpcf",
					iUnitTargetTeam		= self:GetAbilityTargetTeam(),
					iUnitTargetFlags	= self:GetAbilityTargetFlags(),
					iUnitTargetType		= self:GetAbilityTargetType(),
					fDistance			= self:GetSpecialValueFor("range"),
					-- spawn in cyllinder:            origin           random cirlce offset             height offset +\- random height
					vSpawnOrigin		= caster:GetAbsOrigin() + RandomVector(RandomFloat(0, 64)) + Vector(0, 0, 96+RandomFloat(-32, 32)),
					vVelocity			= caster:GetForwardVector()*1400,
					fStartRadius		= 16,
					fEndRadius			= 16,
					bHasFrontalCone		= false,
					bReplaceExisting	= false,
					bDeleteOnHit		= false,
					bProvidesVision 	= true,
				 	iVisionRadius 		= 128,
					iVisionTeamNumber 	= caster:GetTeamNumber(),
				}
			end)
		end
	end

	function arrow_launcher_volley:OnProjectileHit(target, location)
		if target then
			local caster = self:GetCaster()

			-- deal damage
			ApplyDamage{
				victim      = target,
				attacker    = caster,
				damage      = self:GetSpecialValueFor("damage"),
				damage_type = self:GetAbilityDamageType(),
			}

			-- apply a 0 dmg right click to proc any relevant abilities     FIXME: make this work (also, do i actually want to proc things?)
			--[[
			local base_damage_min = caster:GetBaseDamageMin()
			local base_damage_max = caster:GetBaseDamageMax()
			caster:SetBaseDamageMin(0)
			caster:SetBaseDamageMax(0)

			--void PerformAttack(handle hTarget, bool bUseCastAttackOrb, bool bProcessProcs, bool bSkipCooldown, bool bIgnoreInvis, bool bUseProjectile)
			caster:PerformAttack(target, true, true, true, false, false)

			caster:SetBaseDamageMin(base_damage_min)
			caster:SetBaseDamageMax(base_damage_max)
			]]

			-- damage effect (blood splatter)
            local part = ParticleManager:CreateParticle("particles/generic_gameplay/generic_hit_blood.vpcf", PATTACH_CUSTOMORIGIN, nil)
            ParticleManager:SetParticleControl(part, 0, location)         -- position
            ParticleManager:SetParticleControl(part, 1, Vector(1, 0, 0))  -- scale
		end
	end
end