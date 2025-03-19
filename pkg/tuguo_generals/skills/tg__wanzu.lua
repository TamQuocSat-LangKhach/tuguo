local tg__wanzu = fk.CreateSkill {
  name = "tg__wanzu"
}

Fk:loadTranslationTable{
  ['tg__wanzu'] = '完族',
  ['#tg__wanzu-target'] = '你可以对一名本回合获得过你的牌的角色发动“完族”',
  ['tg__wanzu_distance'] = '令除 %src 外的角色至其距离+1，直至其体力值变化',
  ['tg__wanzu_move'] = '将 %src 区域内的一张牌移动至你的相同区域',
  ['@tg__wanzu_distance'] = '完族 至其距离+',
  ['#tg__wanzu_dis_remove'] = '完族[距离清零]',
  [':tg__wanzu'] = '一名角色的回合结束时，你可以选择一名本回合获得过你的牌的角色并选择一项：1. 将其区域内的一张牌移动至你的相同区域（替换原有牌）；2.令除其外的角色至其距离+1，直至其体力值变化。',
}

tg__wanzu:addEffect(fk.TurnEnd, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(tg__wanzu.name) then return false end
    return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move and move.toArea == Card.PlayerHand and move.from == player.id and move.to and
          move.to ~= player.id and not player.room:getPlayerById(move.to).dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 999, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.PlayerHand and move.from == player.id and move.to
          and move.to ~= player.id and not player.room:getPlayerById(move.to).dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.insertIfNeed(targets, move.to)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#tg__wanzu-target",
      skill_name = tg__wanzu.name,
      cancelable = true
    })
    if #tos > 0 then
      local to = room:getPlayerById(tos[1])
      local choices = {"tg__wanzu_distance:" .. to.id, "Cancel"}
      if not to:isAllNude() then
        table.insert(choices, 1, "tg__wanzu_move:" .. to.id)
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = tg__wanzu.name
      })
      if choice ~= "Cancel" then
        event:setCostData(skill, {choice, to.id})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(skill)
    local choice, to = cost_data[1], room:getPlayerById(cost_data[2])
    if choice:startsWith("tg__wanzu_distance") then
      room:addPlayerMark(to, "@tg__wanzu_distance")
    else
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "hej",
        skill_name = tg__wanzu.name
      })
      local fromArea = room:getCardArea(id)
      local card = Fk:getCardById(id)
      if fromArea == Card.PlayerEquip then
        room:moveCardIntoEquip(player, id, tg__wanzu.name, true, player)
      else
        local move3 = {
          ids = {id},
          fromArea = fromArea,
          from = to.id,
          to = player.id,
          toArea = fromArea,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = tg__wanzu.name,
        }
        local judge = fromArea == Card.PlayerJudge and player:hasDelayedTrick(card.name)
        if judge then
          local ids = {}
          for _, i in ipairs(player:getCardIds(Player.Judge)) do
            local c = player:getVirualEquip(i)
            if not c then c = Fk:getCardById(i) end
            if c.name == card.name then
              ids = {i}
              break
            end
          end
          local move2 = {
            ids = ids,
            from = player.id,
            fromArea = fromArea,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonJustMove,
          }
          room:moveCards(move2, move3)
        else
          room:moveCards(move3)
        end
      end
    end
  end,
})

tg__wanzu:addEffect('distance', {
  name = "#tg__wanzu_dis",
  correct_func = function(self, from, to)
    if to:getMark("@tg__wanzu_distance") > 0 then
      return to:getMark("@tg__wanzu_distance")
    end
  end,
})

tg__wanzu:addEffect(fk.HpChanged, {
  name = "#tg__wanzu_dis_remove",
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@tg__wanzu_distance") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@tg__wanzu_distance", 0)
  end,
})

return tg__wanzu
