snapfire_lil_shredder_lua = class({})
LinkLuaModifier("modifier_snapfire_lil_shredder_lua_buff", "heroes/hero_snapfire/snapfire_lil_shredder_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_snapfire_lil_shredder_lua_debuff", "heroes/hero_snapfire/snapfire_lil_shredder_lua", LUA_MODIFIER_MOTION_NONE)

function snapfire_lil_shredder_lua:IsStealable()
    return true
end

function snapfire_lil_shredder_lua:IsHiddenWhenStolen()
    return false
end

function snapfire_lil_shredder_lua:GetBehavior()
    if self:GetCaster():HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_TOGGLE
    end
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
end

function snapfire_lil_shredder_lua:OnSpellStart()
    local caster = self:GetCaster()

    local duration = self:GetTalentSpecialValueFor("buff_duration_tooltip")
    local buffed_attacks = self:GetTalentSpecialValueFor("buffed_attacks")
    
    EmitSoundOn("Hero_Snapfire.ExplosiveShells.Cast", caster)

    caster:AddNewModifier(caster, self, "modifier_snapfire_lil_shredder_lua_buff", {Duration = duration}):SetStackCount(buffed_attacks)
end

function snapfire_lil_shredder_lua:OnToggle()
    local caster = self:GetCaster()

    if caster:HasModifier("modifier_snapfire_lil_shredder_lua_buff") then
        caster:RemoveModifierByName("modifier_snapfire_lil_shredder_lua_buff")
    else
        caster:AddNewModifier(caster, self, "modifier_snapfire_lil_shredder_lua_buff", {})
    end
end

modifier_snapfire_lil_shredder_lua_buff = class({})

function modifier_snapfire_lil_shredder_lua_buff:OnCreated(table)
    self.bonus_as = self:GetTalentSpecialValueFor("attack_speed_bonus")
    self.bonus_ar = self:GetTalentSpecialValueFor("attack_range_bonus")
    self.bonus_bat = self:GetTalentSpecialValueFor("base_attack_time")

    if IsServer() then 
        local parent = self:GetParent()

        self.debuffStackCount = self:GetTalentSpecialValueFor("buffed_attacks")
        self.debuffDuration = self:GetTalentSpecialValueFor("slow_duration")

        self.damage = self:GetTalentSpecialValueFor("damage")

        self.mana_cost_scepter = self:GetTalentSpecialValueFor("mana_cost_scepter")

        self.attack_damage = -100
        if parent:HasTalent("special_bonus_unique_snapfire_lil_shredder_lua_2") then
            self.attack_damage = -(100 - parent:FindTalentValue("special_bonus_unique_snapfire_lil_shredder_lua_2"))
        end

        self:StartIntervalThink(0.25)
    end
end

function modifier_snapfire_lil_shredder_lua_buff:OnRefresh(table)
    self.bonus_as = self:GetTalentSpecialValueFor("attack_speed_bonus")
    self.bonus_ar = self:GetTalentSpecialValueFor("attack_range_bonus")
    self.bonus_bat = self:GetTalentSpecialValueFor("base_attack_time")

    if IsServer() then 
        local parent = self:GetParent()

        self.debuffStackCount = self:GetTalentSpecialValueFor("buffed_attacks")
        self.debuffDuration = self:GetTalentSpecialValueFor("slow_duration")

        self.attack_damage = -100
        if parent:HasTalent("special_bonus_unique_snapfire_lil_shredder_lua_2") then
            self.attack_damage = -(100 - parent:FindTalentValue("special_bonus_unique_snapfire_lil_shredder_lua_2")) 
        end

        self.damage = self:GetTalentSpecialValueFor("damage")

        self.mana_cost_scepter = self:GetTalentSpecialValueFor("mana_cost_scepter")
    end
end

function modifier_snapfire_lil_shredder_lua_buff:OnIntervalThink()
    local caster = self:GetCaster()
    if not caster:HasScepter() or not self:GetAbility():GetToggleState() then

    end
end

function modifier_snapfire_lil_shredder_lua_buff:OnRemoved()
    if IsServer() then        
        if self:GetStackCount() < 2 then
            self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_3_END)
        end
    end
end

function modifier_snapfire_lil_shredder_lua_buff:DeclareFunctions()
    local funcs = { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
                    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
                    MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
                    MODIFIER_EVENT_ON_ATTACK_LANDED,
                    MODIFIER_PROPERTY_PROJECTILE_NAME,
                    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
                    MODIFIER_EVENT_ON_ATTACK_START,
                    MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE}
    return funcs
end

function modifier_snapfire_lil_shredder_lua_buff:GetModifierDamageOutgoing_Percentage()
    return self.attack_damage
end

function modifier_snapfire_lil_shredder_lua_buff:GetModifierProjectileName()
    return "particles/units/heroes/hero_snapfire/hero_snapfire_shells_projectile.vpcf"
end

function modifier_snapfire_lil_shredder_lua_buff:MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS ()
    return "turret"
end

function modifier_snapfire_lil_shredder_lua_buff:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_as
end

function modifier_snapfire_lil_shredder_lua_buff:GetModifierAttackRangeBonus()
    return self.bonus_ar
end

function modifier_snapfire_lil_shredder_lua_buff:GetModifierBaseAttackTimeConstant()
    return self.bonus_bat
end

function modifier_snapfire_lil_shredder_lua_buff:OnAttackStart(params)
    if IsServer() then
        local attacker = params.attacker
        local target = params.target

        if target and target ~= attacker and target:GetTeam() ~= attacker:GetTeam() and attacker == self:GetParent() then
            EmitSoundOn("Hero_Snapfire.ExplosiveShellsBuff.Attack", attacker)
        end
    end
end

function modifier_snapfire_lil_shredder_lua_buff:OnAttackLanded(params)
    if IsServer() then
        local attacker = params.attacker
        local target = params.target

        if target and target ~= attacker and target:GetTeam() ~= attacker:GetTeam() and attacker == self:GetParent() then
            if target:HasModifier("modifier_snapfire_lil_shredder_lua_debuff") then
                if target:FindModifierByName("modifier_snapfire_lil_shredder_lua_debuff"):GetStackCount() < self.debuffStackCount then
                    target:AddNewModifier(attacker, self:GetAbility(), "modifier_snapfire_lil_shredder_lua_debuff", {Duration = self.debuffDuration}):IncrementStackCount()
                else
                    target:AddNewModifier(attacker, self:GetAbility(), "modifier_snapfire_lil_shredder_lua_debuff", {Duration = self.debuffDuration})
                end
            else
                target:AddNewModifier(attacker, self:GetAbility(), "modifier_snapfire_lil_shredder_lua_debuff", {Duration = self.debuffDuration}):IncrementStackCount()
            end

            EmitSoundOn("Hero_Snapfire.ExplosiveShellsBuff.Target", target)
            self:GetAbility():DealDamage(attacker, target, self.damage, {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION}, OVERHEAD_ALERT_DAMAGE)

        end

        if attacker:HasScepter() then
            attacker:ReduceMana(self.mana_cost_scepter)
        else
            if self:GetStackCount() <= 1 then
                self:Destroy()
            else
                self:DecrementStackCount()
            end
        end
    end
end

function modifier_snapfire_lil_shredder_lua_buff:GetEffectName()
    return "particles/units/heroes/hero_snapfire/hero_snapfire_shells_buff.vpcf"
end

function modifier_snapfire_lil_shredder_lua_buff:IsPurgable()
    return true
end

function modifier_snapfire_lil_shredder_lua_buff:IsDebuff()
    return false
end

modifier_snapfire_lil_shredder_lua_debuff = class({})

function modifier_snapfire_lil_shredder_lua_debuff:OnCreated(table)
    self.bonus_as = -self:GetTalentSpecialValueFor("attack_speed_slow_per_stack") * self:GetStackCount()
    self.slow_ms = 0
    if self:GetCaster():HasTalent("special_bonus_unique_snapfire_lil_shredder_lua_1") then
        self.slow_ms = -self:GetCaster():FindTalentValue("special_bonus_unique_snapfire_lil_shredder_lua_1")
    end
end

function modifier_snapfire_lil_shredder_lua_debuff:OnRefresh(table)
    self.bonus_as = -self:GetTalentSpecialValueFor("attack_speed_slow_per_stack") * self:GetStackCount()
    self.slow_ms = 0
    if self:GetCaster():HasTalent("special_bonus_unique_snapfire_lil_shredder_lua_1") then
        self.slow_ms = -self:GetCaster():FindTalentValue("special_bonus_unique_snapfire_lil_shredder_lua_1")
    end
end

function modifier_snapfire_lil_shredder_lua_debuff:DeclareFunctions()
    local funcs = { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
                    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
    return funcs
end

function modifier_snapfire_lil_shredder_lua_debuff:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_as
end

function modifier_snapfire_lil_shredder_lua_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow_ms
end

function modifier_snapfire_lil_shredder_lua_debuff:IsPurgable()
    return true
end

function modifier_snapfire_lil_shredder_lua_debuff:IsDebuff()
    return true
end