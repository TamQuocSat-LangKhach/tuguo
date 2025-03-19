local tg__jiancheng = fk.CreateSkill {
  name = "tg__jiancheng"
}

Fk:loadTranslationTable{
  ['tg__jiancheng'] = '坚城',
  ['@tg__jiancheng-round'] = '坚城',
  ['@@tg__jiancheng_invalid-round'] = '坚城 距离+1',
  [':tg__jiancheng'] = '每轮限两次，当你需要使用/打出一种基本牌时，你可以展示牌堆顶和牌堆底各一张牌，视为使用/打出之，若这两张牌颜色不同，你获得这两张牌，然后本轮内此技能失效且其他角色至你距离+1。',
}

tg__jiancheng:addEffect('viewas', {
  card_filter = function(self, player)
    return false
  end,
  card_num = 0,
  pattern = "^nullification|.|.|.|.|basic",
  interaction = function(self, player)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and card.type == Card.TypeBasic and not card.is_derived and ((Fk.currentResponsePattern == nil and player:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) and not player:prohibitUse(card) then
        table.insert(allCardNames, card.name)
      end
    end
    return UI.ComboBox { choices = allCardNames }
  end,
  view_as = function(self, player, cards)
    local choice = skill.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = skill.name
    return c
  end,
  before_use = function(self, player, use, event)
    local room = player.room
    room:addPlayerMark(player, "@tg__jiancheng-round")
    if #room.draw_pile < 2 then
      room:shuffleDrawPile()
      if #room.draw_pile < 2 then
        room:gameOver("")
      end
    end
    local cids = {room:getNCards(1)[1], room:getNCards(1, "bottom")[1]}
    room:moveCardTo(cids, Card.Processing, nil, fk.ReasonJustMove, skill.name)
    room:sendFootnote(cids, {
      type = "##ShowCard",
      from = player.id,
    }) --FIXME，展示牌堆顶牌
    room:delay(1200)
    if Fk:getCardById(cids[1]).color ~= Fk:getCardById(cids[2]).color then
      local dummy = Fk:cloneCard("jink")
      dummy:addSubcards(cids)
      room:obtainCard(player, dummy, true, fk.ReasonPrey)
      room:setPlayerMark(player, "@tg__jiancheng-round", 0)
      room:setPlayerMark(player, "@@tg__jiancheng_invalid-round", 1)
    else
      room:moveCardTo(cids[1], Card.DrawPile, nil, fk.ReasonPut, skill.name, nil, false)
      local move1 = {
        ids = {cids[2]},
        fromArea = Card.Processing,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = skill.name,
        drawPilePosition = -1,
      }
      local move2 = {
        ids = {cids[1]},
        fromArea = Card.Processing,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = skill.name,
      }
      room:moveCards(move1, move2)
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(tg__jiancheng.name, Player.HistoryRound) < 2 and player:getMark("@@tg__jiancheng_invalid-round") == 0
  end,
  enabled_at_response = function(self, player)
    return player:usedSkillTimes(tg__jiancheng.name, Player.HistoryRound) < 2 and player:getMark("@@tg__jiancheng_invalid-round") == 0
  end,
})

tg__jiancheng:addEffect('distance', {
  correct_func = function(self, from, to)
    if to:getMark("@@tg__jiancheng_invalid-round") ~= 0 and from ~= to then
      return to:getMark("@@tg__jiancheng_invalid-round")
    end
  end,
})

return tg__jiancheng
