phenx_egg = class({})
LinkLuaModifier( "modifier_phenx_egg_caster", "heroes/hero_phenx/phenx_egg.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_phenx_egg_form", "heroes/hero_phenx/phenx_egg.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_phenx_egg_burn", "heroes/hero_phenx/phenx_egg.lua", LUA_MODIFIER_MOTION_NONE )

function phenx_egg:IsStealable()
    return true
end

function phenx_egg:IsHiddenWhenStolen()
    return false
end

function phenx_egg:OnSpellStart()
    local caster = self:GetCaster()

    EmitSoundOn("Hero_Phoenix.SuperNova.Cast", caster)

    local egg = caster:CreateSummon("npc_dota_phoenix_sun", caster:GetAbsOrigin(), self:GetTalentSpecialValueFor("duration"))
	
	local hp = self:GetTalentSpecialValueFor("max_hero_attacks")
	egg:SetBaseMaxHealth(hp)
	egg:SetMaxHealth(hp)
	egg:SetHealth(hp)
	
    egg:AddNewModifier(caster, self, "modifier_phenx_egg_form", {Duration = self:GetTalentSpecialValueFor("duration")})
    EmitSoundOn("Hero_Phoenix.SuperNova.Begin", egg)

    caster:AddNewModifier(caster, self, "modifier_phenx_egg_caster", {Duration = self:GetTalentSpecialValueFor("duration")})
    egg:ModifyThreat(caster:GetThreat())
    caster:SetThreat(0)
end

modifier_phenx_egg_caster = class({})
function modifier_phenx_egg_caster:OnCreated(table)
    if IsServer() then
        self:GetCaster():AddNoDraw()
    end
end

function modifier_phenx_egg_caster:OnRemoved()
    if IsServer() then
        self:GetCaster():RemoveNoDraw()
        self:GetCaster():StartGesture(ACT_DOTA_INTRO)
    end
end

function modifier_phenx_egg_caster:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
					[MODIFIER_STATE_MAGIC_IMMUNE] = true,
					[MODIFIER_STATE_PROVIDES_VISION] = true,
					[MODIFIER_STATE_NO_HEALTH_BAR] = true,
					[MODIFIER_STATE_UNTARGETABLE] = true,
                    [MODIFIER_STATE_OUT_OF_GAME] = true,
                    [MODIFIER_STATE_SILENCED] = true
                }
    return state
end

modifier_phenx_egg_form = class({})

function modifier_phenx_egg_form:OnCreated(table)
    if IsServer() then
        self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_egg.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt(self.nfx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), false)
        ParticleManager:SetParticleControlEnt(self.nfx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), false)

        self.maxAttacks = self:GetTalentSpecialValueFor("max_hero_attacks")
		self:GetParent().supernova_numAttacked = 0
        self:StartIntervalThink(0.5)
    end
end

function modifier_phenx_egg_form:OnIntervalThink()
	local egg = self:GetParent()
	local caster = self:GetCaster()
	
    egg:ModifyThreat(self:GetTalentSpecialValueFor("threat_gain"))
    GridNav:DestroyTreesAroundPoint(egg:GetAbsOrigin(), self:GetTalentSpecialValueFor("radius"), false)
	
	egg:ModifyThreat( caster:GetThreat() )
	caster:SetThreat(0)
	
    if self:GetCaster():HasTalent("special_bonus_unique_phenx_egg_2") then
        local newRadi = self:GetTalentSpecialValueFor("radius")
        for i=1,5 do
            pointRando = egg:GetAbsOrigin() + ActualRandomVector(self:GetTalentSpecialValueFor("radius"))

            ParticleManager:FireParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf", PATTACH_POINT, egg, {[0]=pointRando})
            local enemies = self:GetCaster():FindEnemyUnitsInRadius(pointRando, 275)
            for _,enemy in pairs(enemies) do
                self:GetAbility():DealDamage(self:GetCaster(), enemy, self:GetTalentSpecialValueFor("damage_per_sec") * self:GetCaster():FindTalentValue("special_bonus_unique_phenx_egg_2"), {}, 0)
            end
        end
    end
end

function modifier_phenx_egg_form:CheckState()
    local state = { [MODIFIER_STATE_ROOTED] = true,
                    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                    [MODIFIER_STATE_FLYING] = true,
                }
    return state
end

function modifier_phenx_egg_form:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_HEALING,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    }
end

function modifier_phenx_egg_form:GetDisableHealing()
    return 1
end


function modifier_phenx_egg_form:GetModifierIncomingDamage_Percentage(params)
	ParticleManager:FireParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_hit.vpcf", PATTACH_POINT, params.target, {})
	
	local egg = self:GetParent()
	local attacker = params.attacker
	local numAttacked = egg.supernova_numAttacked or 0
	numAttacked = numAttacked + 1
	egg.supernova_numAttacked = numAttacked

	if numAttacked >= self.maxAttacks then
		-- Now the egg has been killed.
		egg:ForceKill(true)
		egg.supernova_lastAttacker = attacker
		self:GetCaster():RemoveModifierByName("modifier_phenx_egg_caster")
		egg:RemoveModifierByName("modifier_phenx_egg_form")
	else
		egg:SetHealth( egg:GetHealth() - 1 )
	end
	return -999
end

function modifier_phenx_egg_form:OnRemoved()
    if IsServer() then
		local egg       = self:GetParent()
        local hero      = self:GetCaster()
        local ability   = self:GetAbility()

        ParticleManager:DestroyParticle(self.nfx, false)
        local isDead = egg.supernova_numAttacked >= self.maxAttacks

        if isDead then
            hero:ForceKill(true)
        else
            hero:SetHealth( hero:GetMaxHealth() )
            hero:SetMana( hero:GetMaxMana() )

            -- Strong despel
            local RemovePositiveBuffs = true
            local RemoveDebuffs = true
            local BuffsCreatedThisFrameOnly = false
            local RemoveStuns = true
            local RemoveExceptions = true
            hero:Purge( RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions )

            for i=0,3 do
                local abil = self:GetCaster():GetAbilityByIndex(i)
                if abil ~= self then
                    abil:EndCooldown()
                end
            end

            local enemies = hero:FindEnemyUnitsInRadius(hero:GetAbsOrigin(), self:GetTalentSpecialValueFor("radius"))
            for _,enemy in pairs(enemies) do
                ability:Stun(enemy, self:GetTalentSpecialValueFor("stun_duration"), false)
            end
        end

        -- Play sound effect
        local soundName = "Hero_Phoenix.SuperNova." .. ( isDead and "Death" or "Explode" )
        StartSoundEvent( soundName, hero )

        -- Create particle effect
        local pfxName = "particles/units/heroes/hero_phoenix/phoenix_supernova_" .. ( isDead and "death" or "reborn" ) .. ".vpcf"
        local pfx = ParticleManager:CreateParticle( pfxName, PATTACH_ABSORIGIN, hero )
        ParticleManager:SetParticleControlEnt( pfx, 0, hero, PATTACH_POINT_FOLLOW, "follow_origin", hero:GetAbsOrigin(), true )
        ParticleManager:SetParticleControlEnt( pfx, 1, hero, PATTACH_POINT_FOLLOW, "attach_hitloc", hero:GetAbsOrigin(), true )

        -- Remove the egg
        egg:ForceKill( false )
        egg:AddNoDraw()
    end
end

function modifier_phenx_egg_form:IsAura()
    return true
end

function modifier_phenx_egg_form:GetAuraDuration()
    return 0.5
end

function modifier_phenx_egg_form:GetAuraRadius()
    return self:GetTalentSpecialValueFor("radius")
end

function modifier_phenx_egg_form:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_phenx_egg_form:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_phenx_egg_form:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_phenx_egg_form:GetModifierAura()
    return "modifier_phenx_egg_burn"
end

function modifier_phenx_egg_form:IsAuraActiveOnDeath()
    return false
end

modifier_phenx_egg_burn = class({})
function modifier_phenx_egg_burn:OnCreated(table)
    if IsServer() then
        self:StartIntervalThink(1.0)
    end
end

function modifier_phenx_egg_burn:OnIntervalThink()
    self:GetAbility():DealDamage(self:GetCaster(), self:GetParent(), self:GetTalentSpecialValueFor("damage_per_sec"), {}, 0)
end

function modifier_phenx_egg_burn:GetEffectName()
    return "particles/units/heroes/hero_phoenix/phoenix_supernova_radiance.vpcf"
end