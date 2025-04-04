local tg__qihcai = fk.CreateSkill {
  name = "tg__qihcai"
}

Fk:loadTranslationTable{
  ['tg__qihcai'] = '弃才',
  ['#tg__qihcai-ask'] = '弃才：你可摸 %arg 张牌，直到你下回合开始，你的拼点牌的点数-X',
  ['@tg__qihcai'] = '弃才拼点',
  [':tg__qihcai'] = '每轮限一次，你的回合外，当你失去最后的手牌后或拼点没赢时，你可以摸X张牌，然后直到你下回合开始，你的拼点牌的点数-X（X为你本轮拼点没赢的次数）。',
}

tg__qihcai:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(tg__qihcai.name) or player:usedSkillTimes(tg__qihcai.name, Player.HistoryRound) > 0 then return false end
    for _, move in ipairs(target.data) do
      if move.from and move.from == player.id then
        if player:isKongcheng() and not player.dead and table.find(move.moveInfo, function (info)
          return info.fromArea == Card.PlayerHand end) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player)
    local events = player.room.logic:getEventsOfScope(GameEvent.Pindian, 998, function(e) 
      local pd = e.data[1]
      return pd.from == player or table.contains(pd.tos, player)
    end, Player.HistoryRound)
    local num = 0
    for _, e in ipairs(events) do
      local pd = e.data[1]
      for _, result in pairs(pd.results) do
        if result.winner ~= player then
          num = num + 1
        end
      end
    end
    if event == fk.AfterCardsMove then num = num - 1 end
    if player.room:askToSkillInvoke(player, { skill_name = tg__qihcai.name, prompt = "#tg__qihcai-ask:::" .. num }) then
      event:setCostData(skill, num)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local num = event:getCostData(skill)
    local room = player.room
    player:drawCards(num, tg__qihcai.name)
    room:setPlayerMark(player, "@tg__qihcai", "-" .. tostring(num))
  end,
})

tg__qihcai:addEffect(fk.PindianResultConfirmed, {
  can_trigger = function(self, event, target, player)
    return (target.data.from == player or table.contains(target.data.tos, player)) and target.data.winner ~= player
  end,
  on_cost = function(self, event, target, player) 
    local events = player.room.logic:getEventsOfScope(GameEvent.Pindian, 998, function(e) 
      local pd = e.data[1]
      return pd.from == player or table.contains(pd.tos, player)
    end, Player.HistoryRound)
    local num = 0
    for _, e in ipairs(events) do
      local pd = e.data[1]
      for _, result in pairs(pd.results) do
        if result.winner ~= player then
          num = num + 1
        end
      end
    end
    if event == fk.AfterCardsMove then num = num - 1 end
    if player.room:askToSkillInvoke(player, { skill_name = tg__qihcai.name, prompt = "#tg__qihcai-ask:::" .. num }) then
      event:setCostData(skill, num)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local num = event:getCostData(skill)
    local room = player.room
    player:drawCards(num, tg__qihcai.name)
    room:setPlayerMark(player, "@tg__qihcai", "-" .. tostring(num))
  end,
})

tg__qihcai:addEffect(fk.EventPhaseChanging, {
  can_refresh = function(self, event, target, player)
    return target == player and player:getMark("@tg__qihcai") ~= 0 and (event == fk.Death or data.from == Player.NotActive)
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, "@tg__qihcai", 0)
  end
})

tg__qihcai:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player)
    return target == player and player:getMark("@tg__qihcai") ~= 0 and (event == fk.Death or data.from == Player.NotActive)
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, "@tg__qihcai", 0)
  end
})

local tg__qihcai_minus = fk.CreateSkill {
  name = "#tg__qihcai_minus"
}

tg__qihcai_minus:addEffect(fk.PindianCardsDisplayed, {
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return player:getMark("@@tg__qihcai") > 0 and (target.data.from == player or table.contains(target.data.tos, player))
  end,
  on_use = function(self, event, target, player)
    local num = tonumber(player:getMark("@tg__qihcai"))
    if target.data.from == player then
      target.data.fromCard.number = math.max(target.data.fromCard.number + num, 1)
    else
      target.data.results[player.id].toCard.number = math.max(target.data.results[player.id].toCard.number + num, 1)
    end
  end,
})

return tg__qihcai
