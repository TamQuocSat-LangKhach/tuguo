local tg__danding = fk.CreateSkill {
  name = "tg__danding"
}

Fk:loadTranslationTable{
  ['tg__danding'] = '胆定',
  ['#tg__danding'] = '胆定：你可弃置你与 %dest 区域内共计两张牌，若其中没有你的牌，其摸一张牌',
  ['$Hand_opposite'] = '对方手牌区',
  ['tg__danding_discard'] = '胆定',
  [':tg__danding'] = '当你对其他角色造成伤害后，你可以弃置你与其区域内共计两张牌，若其中没有你的牌，其摸一张牌。',
}

tg__danding:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(tg__danding.name) or not data.to or data.to == player or data.to.dead then return false end
    return #player:getCardIds{Player.Hand, Player.Equip, Player.Judge} + #data.to:getCardIds{Player.Hand, Player.Equip, Player.Judge} > 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = tg__danding.name,
      prompt = "#tg__danding::" .. data.to.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = data.to
    local card_data = {}
    if target:getHandcardNum() > 0 then
      local handcards = {}
      for _ = 1, target:getHandcardNum() do
        table.insert(handcards, -1) -- 手牌不可见
      end
      table.insert(card_data, {"$Hand_opposite", handcards})
    end
    local areas = { {"$Equip", Player.Equip}, {"$Judge", Player.Judge} }
    for _, v in ipairs(areas) do
      local area = v[2]
      if #target.player_cards[area] > 0 then
        table.insert(card_data, {v[1] .. "_opposite", target:getCardIds(area)})
      end
    end
    table.insert(areas, 1, {"$Hand", Player.Hand})
    for _, v in ipairs(areas) do
      local area = v[2]
      if #player.player_cards[area] > 0 then
        table.insert(card_data, {v[1] .. "_own", player:getCardIds(area)})
      end
    end

    local ret = room:askToPoxi(player, {
      poxi_type = "tg__danding_discard",
      data = card_data,
      cancelable = false
    })

    local new_ret = table.filter(ret, function(id) return id ~= -1 end)
    local hand_num = #ret - #new_ret
    if hand_num > 0 then
      table.insertTable(new_ret, table.random(target:getCardIds(Player.Hand), hand_num))
    end

    local moveInfos = {}
    local cards1 = {}
    for i = #new_ret, 1, -1 do
      if room:getCardOwner(new_ret[i]) == player then
        table.insert(cards1, new_ret[i])
        table.remove(new_ret, i)
      end
    end

    local to_draw = not table.find(cards1, function (id)
      return room:getCardArea(id) ~= Player.Judge
    end)

    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = player.id,
        ids = cards1,
        to_area = Card.DiscardPile,
        move_reason = fk.ReasonDiscard,
        proposer = player.id,
        skill_name = tg__danding.name,
      })
    end

    if #new_ret > 0 then
      table.insert(moveInfos, {
        from = target.id,
        ids = new_ret,
        to_area = Card.DiscardPile,
        move_reason = fk.ReasonDiscard,
        proposer = player.id,
        skill_name = tg__danding.name,
      })
    end

    room:moveCards(table.unpack(moveInfos))
    if not target.dead and to_draw then
      target:drawCards(1, tg__danding.name)
    end
  end,
})

return tg__danding
