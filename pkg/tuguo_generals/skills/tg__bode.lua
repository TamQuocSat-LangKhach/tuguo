local tg__bode = fk.CreateSkill {
  name = "tg__bode"
}

Fk:loadTranslationTable{
  ['tg__bode'] = '播德',
  ['#tg__bode-ask'] = '播德：将其中的锦囊牌交给一名攻击范围外的其他角色，你获得其余牌',
  [':tg__bode'] = '出牌阶段限一次，你可以展示牌堆顶的X张牌（X为攻击范围内没有你的角色数），你将其中的锦囊牌交给一名攻击范围外的其他角色，获得未交出的牌。',
}

tg__bode:addEffect('active', {
  anim_type = "drawcard",
  can_use = function (self, player)
    return player:usedSkillTimes(tg__bode.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = function() return false end,
  on_use = function (self, room, effect)
    local player = room:getPlayerById(effect.from)
    local num = #table.filter(room.alive_players, function(p) return not p:inMyAttackRange(player) end)
    if num == 0 then return false end
    local cids = room:getNCards(num)
    room:moveCardTo(cids, Card.Processing, nil, fk.ReasonJustMove, tg__bode.name)
    room:delay(2000)
    local targets = table.map(table.filter(room.alive_players, function(p) return not player:inMyAttackRange(p) and p ~= player end), function(p) return p.id end)
    if #targets > 0 then
      local cards = table.filter(cids, function(id) return Fk:getCardById(id).type == Card.TypeTrick end)
      if #cards > 0 then
        local target = room:askToChoosePlayers(player, {
          targets = room:getAlivePlayers(),
          min_num = 1,
          max_num = 1,
          prompt = "#tg__bode-ask",
          skill_name = tg__bode.name,
          cancelable = false
        })[1]
        room:moveCardTo(cards, Player.Hand, room:getPlayerById(target), fk.ReasonGive, tg__bode.name, nil, false)
        table.forEach(cards, function(id) table.removeOne(cids, id) end)
      end
    end
    local dummy = Fk:cloneCard("jink")
    dummy:addSubcards(cids)
    room:obtainCard(player, dummy, true, fk.ReasonPrey)
  end
})

return tg__bode
