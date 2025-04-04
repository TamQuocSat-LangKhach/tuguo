local tg__weixi = fk.CreateSkill {
  name = "tg__weixi"
}

Fk:loadTranslationTable{
  ['tg__weixi'] = '遗玺',
  ['#tg__weixi'] = '遗玺：你可与 %dest 各摸一张牌，然后本局游戏你与其摸牌阶段结束时，你与其各摸一张牌',
  ['@tg__weixi'] = '遗玺',
  ['#tg__weixi_draw'] = '遗玺',
  [':tg__weixi'] = '限定技，当其他角色受到伤害后，若其因此不再是体力值唯一最大的角色，你可以与其各摸一张牌，然后本局游戏你与其摸牌阶段结束时，你与其各摸一张牌。',
}

tg__weixi:addEffect(fk.Damaged, {
  frequency = Skill.Limited,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tg__weixi.name) and player:usedSkillTimes(tg__weixi.name, Player.HistoryGame) < 1 and (data.extra_data or {}).weixicheak and target ~= player and table.find(player.room.alive_players, function(p) return p.hp >= target.hp and p ~= target end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = tg__weixi.name, prompt = "#tg__weixi::" .. target.id})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target:drawCards(1, tg__weixi.name)
    if not player.dead then
      player:drawCards(1, tg__weixi.name)
      room:setPlayerMark(player, "_tg__weixi", target.id)
      room:setPlayerMark(player, "@tg__weixi", target.general)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    if data.damageEvent and table.every(target.room.alive_players, function(p) return target.hp > p.hp or target == p end) then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageEvent.extra_data = data.damageEvent.extra_data or {}
    data.damageEvent.extra_data.weixicheak = true
  end,
})

tg__weixi:addEffect(fk.EventPhaseEnd, {
  name = "#tg__weixi_draw",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tg__weixi.name) and target.phase == Player.Draw and player:getMark("_tg__weixi") ~= 0 and (target == player or player:getMark("_tg__weixi") == target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {player.id, player:getMark("_tg__weixi")}
    room:doIndicate(targets[1], {targets[2]})
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not p.dead then p:drawCards(1, tg__weixi.name) end
    end
  end,
})

return tg__weixi
