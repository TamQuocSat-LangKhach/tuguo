local fenwei = fk.CreateSkill {
  name = "tg__fenwei"
}

Fk:loadTranslationTable{
  ['tg__fenwei'] = '奋围',
  ['#tg__fenwei'] = '奋围：你可翻面，视为对 %dest 使用一张【决斗】或【杀】',
  [':tg__fenwei'] = '每回合限一次，其他角色使用【闪】或本回合第二张同名牌结算结束后，若没有角色处于濒死状态，你可以翻面，视为对其使用一张【决斗】或【杀】（有距离限制）。',
}

fenwei:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player or not player:hasSkill(skill.name) or player:usedSkillTimes(skill.name) > 0 or table.find(player.room.alive_players, function(p)
      return p.dying
    end) then return false end
    if data.card.name == "jink" then return true end
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
      local use = e.data[1]
      return use.card.name == data.card.name
    end, Player.HistoryTurn)
    return #events > 1 and events[2].id == player.room.logic:getCurrentEvent().id
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    for _, n in ipairs({"duel", "slash"}) do
      local card = Fk:cloneCard(n)
      if not player:prohibitUse(card) and not player:isProhibited(target, card) and (n == "duel" or player:inMyAttackRange(target)) then
        table.insert(choices, "tg__fenwei_" .. n .. "_::" .. target.id) --摆
      end
    end
    if #choices == 0 then return false end
    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = fenwei.name,
      prompt = "#tg__fenwei::" .. target.id
    })
    if choice ~= "Cancel" then
      event:setCostData(skill, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    local choice = event:getCostData(skill):split("_")[4]
    player.room:useVirtualCard(choice, nil, player, target, fenwei.name, true)
  end,
})

return fenwei
