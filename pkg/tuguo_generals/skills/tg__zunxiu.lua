local tg__zunxiu = fk.CreateSkill {
  name = "tg__zunxiu"
}

Fk:loadTranslationTable{
  ['tg__zunxiu'] = '遵修',
  ['@tg__zunxiu-turn'] = '遵修',
  ['#tg__zunxiu_filter'] = '遵修',
  [':tg__zunxiu'] = '锁定技，当你使用或打出基本牌时，你令当前回合角色的基本牌直到回合结束均视为此牌；回合结束时，若你本回合只使用过基本牌，你摸X张牌（X为你本回合使用的牌数）。',
}

tg__zunxiu:addEffect(fk.EventPhaseChanging, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(tg__zunxiu.name) then return false end
    if data.to == Player.NotActive then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryTurn)
      return #events > 0 and table.every(events, function(e)
        return e.data[1].card.type == Card.TypeBasic
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
      local use = e.data[1]
      return use.from == player.id
    end, Player.HistoryTurn)
    player:drawCards(#events, tg__zunxiu.name)
  end,
})

tg__zunxiu:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(tg__zunxiu.name) then return false end
    return data.card.type == Card.TypeBasic
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not room.current.dead then
      player.room:setPlayerMark(room.current, "@tg__zunxiu-turn", data.card.name)
    end
  end,
})

tg__zunxiu:addEffect(fk.CardResponding, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(tg__zunxiu.name) then return false end
    return data.card.type == Card.TypeBasic
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not room.current.dead then
      player.room:setPlayerMark(room.current, "@tg__zunxiu-turn", data.card.name)
    end
  end,
})

tg__zunxiu:addEffect('filter', {
  card_filter = function(self, player, to_select, selected)
    if player:getMark("@tg__zunxiu-turn") == 0 or table.contains(player.player_cards[Player.Equip], to_select.id) or table.contains(player.player_cards[Player.Judge], to_select.id) then return false end
    return to_select.type == Card.TypeBasic
  end,
  view_as = function(self, player, to_select)
    local card = Fk:cloneCard(player:getMark("@tg__zunxiu-turn"), to_select.suit, to_select.number)
    card.skillName = tg__zunxiu.name
    return card
  end,
})

return tg__zunxiu
