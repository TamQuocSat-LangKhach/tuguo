local shuangkai = fk.CreateSkill {
  name = "tg__shuangkai"
}

Fk:loadTranslationTable{
  ['tg__shuaikai'] = '爽慨',
  ['#tg__shuaikai_select'] = '爽慨',
  ['#tg__shuangkai-select'] = '爽慨：你可弃置一张装备牌并选择牌面上一个数字，令攻击范围内至多等量角色各摸一张牌；若没有数字，则改为交给一名其他角色',
  ['#tg__shuangkai-choose'] = '爽慨：选择攻击范围内至多 %arg 名角色，各摸一张牌',
  ['#tg__shuangkai-give'] = '爽慨：选择一名其他角色，将 %arg 交给其',
  [':tg__shuangkai'] = '回合结束时，你可以弃置一张装备牌并选择牌面上一个数字，令攻击范围内至多等量的角色各摸一张牌；若没有数字，则改为将此牌交给一名其他角色。<br/><font color=>#"<b>牌面上一个数字</b>"包括（武器的）攻击范围、（坐骑的）距离，不包括点数。</font>',
}

shuangkai:addEffect(fk.EventPhaseChanging, {
  can_trigger = function(event, target, player)
    return player:hasSkill(shuangkai.name) and target == player and data.to == Player.NotActive
  end,
  on_cost = function(event, target, player)
    local card
    local _, ret = player.room:askToUseActiveSkill(player, {
      skill_name = "#tg__shuaikai_select",
      prompt = "#tg__shuangkai-select",
      cancelable = true
    })
    if ret then
      card = Fk:getCardById(ret.cards[1])
    end
    if card then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(event, target, player)
    local room = player.room
    local card = event:getCostData(self)
    local num
    if card.sub_type == Card.SubtypeWeapon then
      num = card.attack_range
    elseif card.sub_type == Card.SubtypeDefensiveRide or card.sub_type == Card.SubtypeOffensiveRide then
      num = 1
    end
    if num then
      room:throwCard(card.id, shuangkai.name, player, player)
      local targets = table.map(table.filter(room.alive_players, function(p) return player:inMyAttackRange(p) end), function (p) return p.id end)
      if #targets == 0 then return false end
      local tos = room:askToChoosePlayers(player, {
        skill_name = shuangkai.name,
        targets = table.map(room:getAlivePlayers(), function(p) return p.id end),
        min_num = 1,
        max_num = num,
        prompt = "#tg__shuangkai-choose:::"..num
      })
      room:sortPlayersByAction(tos)
      for _, pid in ipairs(tos) do
        local p = room:getPlayerById(pid)
        if not p.dead then p:drawCards(1, shuangkai.name) end
      end
    else
      local tos = room:askToChoosePlayers(player, {
        skill_name = shuangkai.name,
        targets = table.map(room:getOtherPlayers(player), function(p) return p.id end),
        min_num = 1,
        max_num = 1,
        prompt = "#tg__shuangkai-give:::" .. card:toLogString()
      })
      local to = tos[1]
      room:moveCardTo(card.id, Player.Hand, room:getPlayerById(to), fk.ReasonGive, shuangkai.name, nil, true)
    end
  end,
})

local shuaikai_select = fk.CreateSkill {
  name = "#tg__shuaikai_select"
}

shuaikai_select:addEffect('active', {
  can_use = function(self, player) return false end,
  target_num = 0,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      local card = Fk:getCardById(to_select)
      if card.type == Card.TypeEquip then
        return not table.contains({Card.SubtypeWeapon, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide}, card.sub_type) or not player:prohibitDiscard(card)
      end
    end
  end,
})

return shuangkai
