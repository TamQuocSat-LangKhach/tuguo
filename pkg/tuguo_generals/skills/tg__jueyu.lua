local tg__jueyu = fk.CreateSkill {
  name = "tg__jueyu"
}

Fk:loadTranslationTable{
  ['tg__jueyu'] = '攫誉',
  ['#tg__jueyu-ask'] = '攫誉：你可以获得攻击范围外距离最近的其他角色各一张牌，然后此阶段结束时，你交给其中此阶段未成为过你牌目标的角色各一张牌',
  ['@@tg__jueyu-phase'] = '攫誉',
  ['#tg__jueyu_pay'] = '攫誉',
  ['#tg__jueyu_pay-card'] = '攫誉：交给 %dest 一张牌',
  [':tg__jueyu'] = '出牌阶段开始时，你可以获得攻击范围外距离最近的其他角色各一张牌，然后此阶段结束时，你交给其中此阶段未成为过你牌目标的角色各一张牌。',
}

tg__jueyu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(tg__jueyu.name) and player.phase == Player.Play and table.find(player.room.alive_players, function(p) return not player:inMyAttackRange(p) and p ~= player and not p:isNude() end)
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, { skill_name = tg__jueyu.name, prompt = "#tg__jueyu-ask" })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local num = 999
    for _, p in ipairs(room.alive_players) do
      if not player:inMyAttackRange(p) and p ~= player then
        num = num > player:distanceTo(p) and player:distanceTo(p) or num
      end
    end
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not player:inMyAttackRange(p) and p ~= player and player:distanceTo(p) == num and not p:isNude()
    end), function(p)
        return p.id
      end)
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not player.dead and not p.dead then
        local id = room:askToChooseCard(player, { target = p, flag = "he", skill_name = tg__jueyu.name })
        room:obtainCard(player, id)
        room:setPlayerMark(p, "@@tg__jueyu-phase", 1)
      end
    end
  end,
})

tg__jueyu:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if player == target and player:usedSkillTimes(tg__jueyu.name, Player.HistoryPhase) > 0 and not player:isNude() then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e)
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryTurn)
      local targets = {}
      if #events > 0 then
        table.forEach(events, function(e)
          table.forEach(e.data[1].tos, function(pids)
            table.insertIfNeed(targets, pids[1])
          end)
        end)
      end
      return table.find(player.room.alive_players, function(p)
        return p:getMark("@@tg__jueyu-phase") > 0 and not table.contains(targets, p.id)
      end)
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local events = room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e)
      local use = e.data[1]
      return use.from == player.id
    end, Player.HistoryTurn)
    local targets = {}
    if #events > 0 then
      table.forEach(events, function(e)
        table.forEach(e.data[1].tos, function(pids)
          table.insertIfNeed(targets, pids[1])
        end)
      end)
    end
    targets = table.map(table.filter(room.alive_players, function(p)
      return p:getMark("@@tg__jueyu-phase") > 0 and not table.contains(targets, p.id)
    end), function(p)
        return p.id
      end)
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local target = room:getPlayerById(pid)
      if not player.dead and not target.dead then
        local c = room:askToCards(player, { min_num = 1, max_num = 1, include_equip = true, skill_name = tg__jueyu.name, prompt = "#tg__jueyu_pay-card::" .. target.id })[1]
        room:moveCardTo(c, Player.Hand, target, fk.ReasonGive, tg__jueyu.name, nil, false)
      end
    end
  end,
})

return tg__jueyu
