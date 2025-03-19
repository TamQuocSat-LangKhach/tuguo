local biyue = fk.CreateSkill {
  name = "tg__zhemou"
}

Fk:loadTranslationTable{
  ['tg__zhemou'] = '折谋',
  ['#tg__zhemou'] = '你可发动“折谋”，跳过出牌阶段和弃牌阶段，视为依次使用无距离和目标数限制的【顺手牵羊】和【杀】',
  [':tg__zhemou'] = '限定技，你可以跳过出牌阶段和弃牌阶段，视为依次使用无距离和目标数限制的【顺手牵羊】和【杀】。',
}

biyue:addEffect(fk.EventPhaseChanging, {
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player:usedSkillTimes(biyue.name, Player.HistoryGame) < 1 and not (player:prohibitUse(Fk:cloneCard("slash")) and player:prohibitUse(Fk:cloneCard("snatch"))) and data.to == Player.Play and not player.skipped_phases[Player.Discard]
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = biyue.name, prompt = "#tg__zhemou" })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:skip(Player.Play)
    player:skip(Player.Discard)
    for _, c in ipairs({"snatch", "slash"}) do
      local card = Fk:cloneCard(c)
      if not player:prohibitUse(card) then
        local availableTargets = table.map(table.filter(room.alive_players, function(p) return p ~= player and not player:isProhibited(p, card) and (c == "slash" or not p:isAllNude()) end), function(p) return p.id end)
        if #availableTargets == 0 then return false end
        local targets = table.map(room:askToChoosePlayers(player, { 
          min_num = 1,
          max_num = 99,
          prompt = "#tg__zhemou-" .. c,
          skill_name = biyue.name,
          cancelable = false,
          targets = availableTargets
        }), function(pid) return room:getPlayerById(pid) end)
        room:useVirtualCard(c, nil, player, targets, biyue.name, true)
      end
    end
    return true
  end,
})

return biyue
