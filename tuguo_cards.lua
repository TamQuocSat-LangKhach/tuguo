local extension = Package("tuguo_cards", Package.CardPack)
extension.extensionName = "tuguo"

Fk:loadTranslationTable{
  ["tuguo_cards"] = "图国篇卡牌",
}

local avoidingDisadvantagesTrigger = fk.CreateTriggerSkill{
  name = "avoiding_disadvantages_trigger",
  events = {fk.BeforeDrawCard, fk.StartJudge},
  mute = true,
  global = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end 
    if event == fk.BeforeDrawCard and data.num < 1 then return false end
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      if card and card.name == "avoiding_disadvantages" and not player:prohibitUse(card) and not player:isProhibited(player, card) then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local num = 3
    if player:hasSkill("tg__langbu") then -- 开耦！
      num = num - player:getMark("@tg__langbu-round")
    end
    local prompt
    if num < 1 then
      prompt = "#AD-negative"
    else
      prompt = event == fk.StartJudge and "#AD-judge:::" .. data.reason .. ":" .. num or "#AD-draw:::" .. data.num .. ":" .. num
    end
    local use = player.room:askForUseCard(player, "avoiding_disadvantages", nil, prompt, true)
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:useCard(self.cost_data)
    if player.dead and event == fk.BeforeDrawCard then
      data.num = 0
    end
  end,
}
Fk:addSkill(avoidingDisadvantagesTrigger)
local avoidingDisadvantagesSkill = fk.CreateActiveSkill{
  name = "avoiding_disadvantages_skill",
  can_use = Util.FalseFunc,
  on_use = function(self, room, cardUseEvent)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = { { cardUseEvent.from } }
    end
  end,
  on_effect = function(self, room, cardEffectEvent)
    local player = room:getPlayerById(cardEffectEvent.to)
    local num = 3
    if player:hasSkill("tg__langbu") then -- 开耦！
      num = num - player:getMark("@tg__langbu-round")
      if num < 1 then
        local chs = {"loseMaxHp"}
        if player.hp > 0 then table.insert(chs, 1, "loseHp") end
        local chc = room:askForChoice(player, chs, self.name)
        if chc == "loseMaxHp" then
          room:changeMaxHp(player, -1)
        else
          room:loseHp(player, 1, self.name)
        end
        return false
      end
    end
    if #room.draw_pile < num then
      room:shuffleDrawPile()
      if #room.draw_pile < num then
        room:gameOver("")
      end
    end
    local cids = table.slice(room.draw_pile, 1, num + 1)
    local to_discard = room:askForCardsChosen(player, player, 0, num, {
      card_data = {
        { "Top", cids }
      }
    }, self.name, "#AD-discard:::" .. num)
    room:moveCardTo(to_discard, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name)
  end
}
local avoidingDisadvantages = fk.CreateTrickCard{
  name = "avoiding_disadvantages",
  suit = Card.Spade,
  number = 12,
  skill = avoidingDisadvantagesSkill,
  is_passive = true,
}
extension:addCards{
  avoidingDisadvantages,
  avoidingDisadvantages:clone(Card.Diamond, 1),
}
Fk:loadTranslationTable{
  ["avoiding_disadvantages"] = "违害就利", -- seeking_advantages_and_avoiding_disadvantages
  [":avoiding_disadvantages"] = "锦囊牌<br /><b>时机</b>：当你摸牌或进行判定时<br /><b>目标</b>：你<br /><b>效果</b>：目标角色观看牌堆顶三张牌，然后将其中任意张牌置于弃牌堆。",

  ["avoiding_disadvantages_trigger"] = "违害就利",
  ["#AD-judge"] = "你即将判定%arg，可使用【违害就利】，观看牌堆顶%arg2张牌，将其中任意张牌置于弃牌堆",
  ["#AD-draw"] = "你即将摸%arg张牌，可使用【违害就利】，观看牌堆顶%arg2张牌，将其中任意张牌置于弃牌堆",
  ["#AD-negative"] = "你可使用【违害就利】，选择失去1点体力或减1点体力上限",
  ["avoiding_disadvantages_skill"] = "违害就利",
  ["#AD-discard"] = "违害就利：观看牌堆顶至多%arg张牌，可将其中任意张牌置于弃牌堆",
}

local defeating_the_double_active = fk.CreateActiveSkill{
  name = "defeating_the_double_active",
  mute = true,
  can_use = Util.FalseFunc,
  target_num = 1,
  min_card_num = 1,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select)) and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getHandcardNum() == #selected_cards * 2
  end,
}
Fk:addSkill(defeating_the_double_active)
local defeatingTheDoubleSkill = fk.CreateActiveSkill{
  name = "defeating_the_double_skill",
  mod_target_filter = Util.TrueFunc,
  can_use = Util.SelfCanUse,
  on_use = function(self, room, cardUseEvent)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = { { cardUseEvent.from } }
    end
  end,
  on_effect = function(self, room, cardEffectEvent)
    local player = room:getPlayerById(cardEffectEvent.to)
    player:drawCards(1, "defeating_the_double")
    if player.dead then return false end
    local _, ret = room:askForUseActiveSkill(player, "defeating_the_double_active", "#DB-ask", true)
    if ret then
      room:throwCard(ret.cards, self.name, player)
      local target = room:getPlayerById(ret.targets[1])
      if player.dead or target.dead then return false end
      room:doIndicate(player.id, {target.id})
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
        card = cardEffectEvent.card,
        damageType = fk.NormalDamage,
      }
    end
  end
}
local defeatingTheDouble = fk.CreateTrickCard{
  name = "defeating_the_double",
  suit = Card.Club,
  number = 3,
  skill = defeatingTheDoubleSkill,
  is_damage_card = true,
}
extension:addCards{
  defeatingTheDouble,
  defeatingTheDouble:clone(Card.Diamond, 9),
}

Fk:loadTranslationTable{
  ["defeating_the_double"] = "以半击倍",
  [":defeating_the_double"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：你<br /><b>效果</b>：目标角色摸一张牌，然后弃置任意张手牌并选择一名手牌数为弃置牌数两倍的角色，对其造成1点伤害。<br /><font color='grey' size = 2>八百虎贲踏江去，十万吴兵丧胆还！",

  ["defeating_the_double_active"] = "以半击倍",
  ["#DB-ask"] = "以半击倍：弃置任意张手牌并选择一名手牌数为弃置牌数两倍的角色，对其造成1点伤害",
}

return extension
