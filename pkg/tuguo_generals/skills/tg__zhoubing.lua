local tg__zhoubing = fk.CreateSkill {
  name = "tg__zhoubing"
}

Fk:loadTranslationTable{
  ['tg__zhoubing'] = '骤兵',
  ['#tg__zhoubing-choose'] = '骤兵：你可以视为使用一张无距离限制且目标数为%arg的【杀】',
  [':tg__zhoubing'] = '其他角色的回合结束时，你可以视为使用一张无距离限制且目标数为X的【杀】（X为其本回合跳过的阶段数）。',
}

tg__zhoubing:addEffect(fk.EventPhaseChanging, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tg__zhoubing.name) and data.to == Player.NotActive and target ~= player and target.skipped_phases and not player:prohibitUse(Fk:cloneCard("slash"))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, phase in ipairs({Player.Start, Player.Judge, Player.Draw, Player.Play, Player.Discard, Player.Finish}) do
      if target.skipped_phases[phase] then
        n = n + 1
      end
    end
    local card = Fk:cloneCard("slash")
    local availableTargets = table.map(table.filter(room.alive_players, function(p) return p ~= player and not player:isProhibited(p, card) end), function(p) return p.id end)
    if #availableTargets == 0 then return false end
    local targets = room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = n,
      max_num = n,
      prompt = "#tg__zhoubing-choose:::" .. n,
      skill_name = tg__zhoubing.name,
      cancelable = true,
    })
    if #targets > 0 then
      event:setCostData(self, targets)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(event:getCostData(self), function(pid) return room:getPlayerById(pid) end)
    room:useVirtualCard("slash", nil, player, targets, tg__zhoubing.name, true)
  end,
})

return tg__zhoubing
