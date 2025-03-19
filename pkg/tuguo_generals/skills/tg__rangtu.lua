local rangtu = fk.CreateSkill {
  name = "tg__rangtu"
}

Fk:loadTranslationTable{
  ['tg__rangtu'] = '攘途',
  ['#tg__rangtu'] = '攘途：你可与 %dest 点：若你赢，你令其跳过本回合的一个阶段；若你没赢，你展示所有手牌，你下次拼点点数-2',
  ['#tg__rangtu-skip'] = '攘途：令 %src 跳过本回合的一个阶段',
  ['@@tg__rangtu'] = '攘途 拼点-2',
  ['#tg__rangtu_negative'] = '攘途',
  [':tg__rangtu'] = '其他角色的准备阶段，若其体力值不小于你，你可以与其拼点：若你赢，你令其跳过本回合的一个阶段；若你没赢，你展示所有手牌，你下次拼点点数-2。',
}

rangtu:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(rangtu.name) and target.phase == Player.Start and player ~= target and target.hp >= player.hp and not player:isKongcheng() and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = rangtu.name,
      prompt = "#tg__rangtu::" .. target.id
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local pd = player:pindian({target}, rangtu.name)
    if pd.results[target.id].winner == player then
      local phase = {"phase_judge", "phase_draw", "phase_play", "phase_discard", "phase_finish"}
      target:skip(room:askToChoice(player, {
        choices = phase,
        skill_name = rangtu.name,
        prompt = "#tg__rangtu-skip:" .. player.id
      }) + 2)
    else
      player:showCards(player:getCardIds(Player.Hand))
      room:addPlayerMark(player, "@@tg__rangtu")
    end
  end,
})

rangtu:addEffect(fk.PindianCardsDisplayed, {
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return player:getMark("@@tg__rangtu") > 0 and (target == player or table.contains(player.room:findPlayerBySkillName("#tg__rangtu_negative"), player))
  end,
  on_use = function(self, event, target, player)
    player.room:setPlayerMark(player, "@@tg__rangtu", 0)
    if target == player then
      target.fromCard.number = math.max(target.fromCard.number - 2, 1)
    else
      local results = player.room:getTag("PindianResult"):toTable()
      results[player.id].toCard.number = math.max(results[player.id].toCard.number - 2, 1)
    end
  end,
})

return rangtu
