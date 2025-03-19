local biyue = fk.CreateSkill {
  name = "tg__zhenfan"
}

Fk:loadTranslationTable{
  ['tg__zhenfan'] = '振藩',
  ['#tg__zhenfan-ask'] = '振藩：你可令一名其他角色选择是否使用一张【杀】，令你本回合使用【杀】的次数上限+1',
  ['#tg__zhenfan-slash'] = '振藩：你可使用一张【杀】，令 %src 本回合使用【杀】的次数上限+1',
  ['@tg__zhenfan-turn'] = '振藩',
  [':tg__zhenfan'] = '当你于出牌阶段使用【杀】结算后，你可以令一名其他角色选择是否使用一张【杀】，令你本回合使用【杀】的次数上限+1。',
}

biyue:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player == target and player:hasSkill(biyue.name) and target.phase == Player.Play and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player),function(p)
      return not p:prohibitUse(Fk:cloneCard("slash"))
    end), function(p)
        return p.id
      end)
    local target = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#tg__zhenfan-ask",
      skill_name = biyue.name,
      cancelable = true,
    })
    if #target > 0 then
      event:setCostData(self, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke("jijiang")
    local targetPlayer = room:getPlayerById(event:getCostData(self))
    local use = room:askToUseCard(targetPlayer, {
      pattern = "slash",
      prompt = "#tg__zhenfan-slash:" .. player.id,
      cancelable = true,
      extra_data = { bypass_times = true },
    })
    if use then
      room:useCard(use)
      room:addPlayerMark(player, "@tg__zhenfan-turn")
    end
  end,
})

biyue:addEffect("targetmod", {
  name = "#tg__zhenfan_buff",
  residue_func = function(self, player, skill, scope)
    if player:getMark("@tg__zhenfan-turn") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@tg__zhenfan-turn")
    end
  end,
})

return biyue
