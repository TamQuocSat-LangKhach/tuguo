local tg__kaiji = fk.CreateSkill {
  name = "tg__kaiji"
}

Fk:loadTranslationTable{
  ['tg__kaiji'] = '开济',
  ['#tg__kaiji-discard'] = '开济：弃置 %arg 张手牌',
  [':tg__kaiji'] = '转换技，出牌阶段限一次，阳：你可以将手牌摸至X张；阴：你可以弃置X张手牌。（X为你的手牌上限）',
}

tg__kaiji:addEffect('active', {
  anim_type = "drawcard",
  mute = true,
  switch_skill_name = "tg__kaiji",
  can_use = function(self, player)
    return player:usedSkillTimes(tg__kaiji.name, Player.HistoryPhase) == 0 and (player:getSwitchSkillState(tg__kaiji.name) == fk.SwitchYang or player:getHandcardNum() >= player:getMaxCards())
  end,
  card_filter = function(player) return false end,
  card_num = 0,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke("ty__kaiji")
    if player:getSwitchSkillState(tg__kaiji.name, true) == fk.SwitchYang then
      room:notifySkillInvoked(player, tg__kaiji.name, "drawcard")
      local num = player:getMaxCards() - player:getHandcardNum()
      if num > 0 then player:drawCards(num, tg__kaiji.name) end
    else
      room:notifySkillInvoked(player, tg__kaiji.name, "negative")
      local num = player:getMaxCards()
      room:askToDiscard(player, {
        min_num = num,
        max_num = num,
        include_equip = false,
        skill_name = tg__kaiji.name,
        cancelable = false,
        prompt = "#tg__kaiji-discard:::" .. num
      })
    end
  end,
})

return tg__kaiji
