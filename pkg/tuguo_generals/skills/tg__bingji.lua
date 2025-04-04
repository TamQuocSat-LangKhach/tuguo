local tg__bingji = fk.CreateSkill {
  name = "tg__bingji"
}

Fk:loadTranslationTable{
  ['tg__bingji'] = '并击',
  ['@@tg__bingji-inhand'] = '并击',
  [':tg__bingji'] = '每项对每名角色限一次：1. 当你失去判定区内的最后一张牌后，你可以对一名角色造成1点伤害；2. 当你失去装备区内的最后一张牌后，你可以令一名角色从牌堆获得一张不计入手牌上限的【杀】、【决斗】或【酒】；3. 当你于弃牌阶段失去基本牌后，你可以视为对一名角色使用一张【杀】。',
}

tg__bingji:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(tg__bingji) then return false end
    for _, move in ipairs(data) do
      if move.from and move.from == player.id then
        if not player.dead then
          if #player:getCardIds(Player.Judge) == 0 and table.find(move.moveInfo, function (info)
            return info.fromArea == Card.PlayerJudge end) then
            return true
          end
          if #player:getCardIds(Player.Equip) == 0 and table.find(move.moveInfo, function (info)
            return info.fromArea == Card.PlayerEquip end) then
            return true
          end
          if player.phase == Player.Discard and table.find(move.moveInfo, function (info)
            return Fk:getCardById(info.cardId).type == Card.TypeBasic end) then
            return true
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local events = {}
    for _, move in ipairs(data) do
      if move.from and move.from == player.id then
        if #player:getCardIds(Player.Judge) == 0 and table.find(move.moveInfo, function (info)
          return info.fromArea == Card.PlayerJudge end) then
          table.insert(events, 1)
        end
        if #player:getCardIds(Player.Equip) == 0 and table.find(move.moveInfo, function (info)
          return info.fromArea == Card.PlayerEquip end) then
          table.insert(events, 2)
        end
        if player.phase == Player.Discard and table.find(move.moveInfo, function (info)
          return Fk:getCardById(info.cardId).type == Card.TypeBasic end) then
          table.insert(events, 3)
        end
      end
    end
    local mark = type(player:getMark("_tg__bingji")) == "table" and player:getMark("_tg__bingji") or { {}, {}, {} }
    for _, e in ipairs(events) do
      if not player:hasSkill(tg__bingji) or player.dead then break end
      if table.find(room.alive_players, function(p) return not table.contains(mark[e], p.id) end) then
        if e == 3 then
          local card = Fk:cloneCard("slash")
          if player:prohibitUse(card) then return false end
          if not table.find(room.alive_players, function(p) return p ~= player and not player:isProhibited(p, card) end) then
            return false
          end
        end
        self:doCost(event, target, player, e)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = type(player:getMark("_tg__bingji")) == "table" and player:getMark("_tg__bingji") or { {}, {}, {} }
    local availableTargets = table.map(table.filter(room.alive_players, function(p) return not table.contains(mark[data], p.id) end), function(p) return p.id end)
    if #availableTargets == 0 then return false end
    if data == 3 then
      local card = Fk:cloneCard("slash")
      if player:prohibitUse(card) then return false end
      availableTargets = table.filter(availableTargets, function(pid) return pid ~= player.id and not player:isProhibited(room:getPlayerById(pid), card) end)
      if #availableTargets == 0 then return false end
    end
    local targets = room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 1,
      prompt = "#tg__bingji_" .. tostring(data),
      skill_name = tg__bingji.name,
      cancelable = true,
    })
    if #targets > 0 then
      event:setCostData(self, targets[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = type(player:getMark("_tg__bingji")) == "table" and player:getMark("_tg__bingji") or { {}, {}, {} }
    local targetId = event:getCostData(self)
    table.insert(mark[data], targetId)
    room:setPlayerMark(player, "_tg__bingji", mark)
    if data == 3 then
      local slash = Fk:cloneCard("slash")
      slash.skillName = tg__bingji.name
      local use = {
        from = player.id,
        tos = { {targetId} },
        card = slash,
      }
      room:useCard(use)
    elseif data == 1 then
      room:damage{
        from = player,
        to = room:getPlayerById(targetId),
        damage = 1,
        skillName = tg__bingji.name,
      }
    else
      local cids = room:getCardsFromPileByRule("slash,duel,analeptic")
      if #cids > 0 then
        room:setCardMark(Fk:getCardById(cids[1]), "@@tg__bingji-inhand", 1)
        room:obtainCard(targetId, cids[1], false, fk.ReasonPrey)
      end
    end
  end,
})

local tg__bingji_maxcards = fk.CreateMaxCardsSkill{
  name = "#tg__bingji_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@tg__bingji-inhand") > 0
  end,
}

return tg__bingji
