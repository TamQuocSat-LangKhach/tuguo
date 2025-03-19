local xiannan = fk.CreateSkill {
  name = "tg__xiannan"
}

Fk:loadTranslationTable{
  ['tg__xiannan'] = '陷难',
  ['@tg__xiannian-turn'] = '陷难 加伤',
  ['#tg__xiannan_trig'] = '陷难',
  [':tg__xiannan'] = '当你于一轮内失去第一张牌或第X张牌后（X为你的体力上限），你可摸一张牌，令你于此回合下一次造成或受到的伤害+1。',
}

xiannan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(xiannan.name) then return false end
    local num = 0
    local ret = true
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      if num >= 1 then ret = false end
      if num >= player.maxHp then
        ret = false
        return true
      end
      for _, move in ipairs(e.data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              num = num + 1
              if num >= player.maxHp then ret = true end
            end
          end
        end
      end
    end, Player.HistoryRound)
    return (num >= 1 or num >= player.maxHp) and ret
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, xiannan.name)
    player.room:addPlayerMark(player, "@tg__xiannian-turn", 1)
  end,
})

xiannan:addEffect(fk.DamageInflicted, {
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@tg__xiannian-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "tg__xiannan", "negative")
    data.damage = data.damage + player:getMark("@tg__xiannian-turn")
    room:setPlayerMark(player, "@tg__xiannian-turn", 0)
  end,
})

xiannan:addEffect(fk.DamageCaused, {
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@tg__xiannian-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "tg__xiannan", "offensive")
    data.damage = data.damage + player:getMark("@tg__xiannian-turn")
    room:setPlayerMark(player, "@tg__xiannian-turn", 0)
  end,
})

return xiannan
  ```

