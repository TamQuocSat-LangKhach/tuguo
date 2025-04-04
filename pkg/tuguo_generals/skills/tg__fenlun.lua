local tg__fenlun = fk.CreateSkill {
  name = "tg__fenlun"
}

Fk:loadTranslationTable{
  ['tg__fenlun'] = '忿论',
  ['#tg__fenlun-invoke'] = '忿论：你可与 %src 点',
  ['tg__fenlun_vs'] = '忿论',
  ['#tg__fenlun-vs'] = '忿论：你可视为使用一张 %src 此回合使用过的基本或普通锦囊牌',
  ['#tg__fenlun-again'] = '忿论：你可与一名角色拼点',
  [':tg__fenlun'] = '其他角色的回合结束时，你可以与其拼点：若你赢，你可以视为使用一张当前回合角色此回合使用过的基本或普通锦囊牌；若你没赢，你可以与此次发动技能未选择过的一名角色重复此流程。',
}

tg__fenlun:addEffect(fk.EventPhaseChanging, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tg__fenlun.name) and data.to == Player.NotActive and target ~= player and not player:isKongcheng() and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = tg__fenlun.name,
      prompt = "#tg__fenlun-invoke:" .. target.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = target
    while true do
      room:addPlayerMark(to, "_tg__fenlun", 1)
      local pd = player:pindian({to}, tg__fenlun.name)
      if pd.results[to.id].winner == player then
        local events = room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
          local use = e.data[1]
          return use.from == room.current.id and (use.card.type == Card.TypeBasic or use.card:isCommonTrick())
        end, Player.HistoryTurn)
        if #events == 0 then break end
        local cards = {}
        table.forEach(events, function(e)
          table.insertIfNeed(cards, e.data[1].card.name)
        end)
        room:setPlayerMark(player, "_tg__fenlun_cards", cards)
        local success, dat = room:askForUseViewAsSkill(player, "tg__fenlun_vs", "#tg__fenlun-vs:" .. target.id, true)
        if success then
          local card = Fk.skills["tg__fenlun_vs"]:viewAs(dat.cards)
          local use = {
            from = player.id,
            tos = table.map(dat.targets, function(e) return {e} end),
            card = card,
          }
          room:useCard(use)
        end
        room:setPlayerMark(player, "_tg__fenlun_cards", 0)
        break
      else
        if player:isKongcheng() then break end
        local availableTargets = table.map(table.filter(room.alive_players, function(p) return p ~= player and not p:isKongcheng() and p:getMark("_tg__fenlun") == 0 end), function(p) return p.id end)
        if #availableTargets == 0 then break end
        local targets = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          prompt = "#tg__fenlun-again",
          skill_name = tg__fenlun.name,
          cancelable = true
        })
        if #targets == 0 then break end
        to = room:getPlayerById(targets[1])
        room:doIndicate(player.id, {to.id})
        room:notifySkillInvoked(player, tg__fenlun.name)
      end
    end
    table.forEach(room.alive_players, function(p) room:setPlayerMark(p, "_tg__fenlun", 0) end)
  end,
})

return tg__fenlun
