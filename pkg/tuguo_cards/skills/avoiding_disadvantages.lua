local skill = fk.CreateSkill {
  name = "avoiding_disadvantages_skill",
}

Fk:loadTranslationTable{
  ["#avoiding_disadvantages-judge"] = "你即将判定“%arg”，可使用【违害就利】，观看牌堆顶的牌并将其中任意张牌置于弃牌堆",
  ["#avoiding_disadvantages-draw"] = "你即将摸%arg张牌，可使用【违害就利】，观看牌堆顶的牌并将其中任意张牌置于弃牌堆",
  ["#avoiding_disadvantages-discard"] = "违害就利：你可以将其中任意张牌置于弃牌堆",
}

skill:addEffect("cardskill", {
  mod_target_filter = Util.TrueFunc,
  on_use = function (self, room, cardUseEvent)
    if not cardUseEvent.tos or #cardUseEvent.tos == 0 then
      cardUseEvent.tos = {}
      cardUseEvent:addTarget(cardUseEvent.from)
    end
  end,
  can_use = Util.FalseFunc,
  on_effect = function(self, room, effect)
    local player = effect.to
    local cards = room:getNCards(3)
    local to_discard = room:askToChooseCards(player, {
      target = player,
      min = 0,
      max = #cards,
      flag = { card_data = {{ "Top", cards }} },
      skill_name = skill.name,
      prompt = "#avoiding_disadvantages-discard",
    })
    if #to_discard > 0 then
      room:moveCardTo(to_discard, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skill.name, nil, true, player)
    end
  end,
})

skill:addEffect(fk.StartJudge, {
  priority = 0.001,
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      table.find(player:getHandlyIds(), function (id)
        local card = Fk:getCardById(id)
        return card.name == "avoiding_disadvantages" and not player:prohibitUse(card) and not player:isProhibited(player, card)
      end)
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseCard(player, {
      skill_name = "",
      pattern = "avoiding_disadvantages",
      prompt = "#avoiding_disadvantages-judge:::"..data.reason,
      cancelable = true,
    })
    if use then
      room:useCard(use)
    end
  end,
})

skill:addEffect(fk.BeforeDrawCard, {
  priority = 0.001,
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.num > 0 and
      table.find(player:getHandlyIds(), function (id)
        local card = Fk:getCardById(id)
        return card.name == "avoiding_disadvantages" and not player:prohibitUse(card) and not player:isProhibited(player, card)
      end)
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseCard(player, {
      skill_name = "",
      pattern = "avoiding_disadvantages",
      prompt = "#avoiding_disadvantages-draw:::"..data.num,
      cancelable = true,
    })
    if use then
      room:useCard(use)
    end
  end,
})

return skill
