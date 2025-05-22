local skill = fk.CreateSkill {
  name = "defeating_the_double_skill",
}

Fk:loadTranslationTable{
  ["#defeating_the_double-discard"] = "以半击倍：弃置任意张手牌，对一名手牌数为弃牌数两倍的角色造成伤害",
}

skill:addEffect("cardskill", {
  prompt = "#defeating_the_double_skill",
  mod_target_filter = Util.TrueFunc,
  can_use = Util.CanUseToSelf,
  on_effect = function(self, room, effect)
    local player = effect.to
    if player.dead then return end
    player:drawCards(1, skill.name)
    if player.dead or player:isKongcheng() or
      not table.find(room.alive_players, function (p)
        return not p:isKongcheng() and p:getHandcardNum() % 2 == 0 and p:getHandcardNum() <= 2 * player:getHandcardNum()
      end) then
      return
    end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "defeating_the_double_active",
      prompt = "#defeating_the_double-discard",
      cancelable = true,
    })
    if success and dat then
      room:throwCard(dat.cards, skill.name, player, player)
      local target = dat.targets[1]
      if target.dead then return false end
      room:doIndicate(player, {target})
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skill.name,
        card = effect.card,
      }
    end
  end,
})

skill:addAI({
  on_use = function(self, logic, effect)
    self.skill:onUse(logic, effect)
  end,
  on_effect = function(self, logic, effect)
    local target = effect.to
    logic:drawCards(target, 1, skill.name)
  end,
}, "__card_skill")

return skill
