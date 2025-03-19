local biyue = fk.CreateSkill {
  name = "tg__shuanggu"
}

Fk:loadTranslationTable{
  ['tg__shuanggu'] = '霜骨',
  ['#tg__shuanggu-ask'] = '霜骨：你可减1点体力上限，防止本回合你与 %dest 受到的伤害',
  ['@@tg__shuanggu-turn'] = '霜骨 防伤',
  ['#tg__shuanggu_trig'] = '霜骨',
  [':tg__shuanggu'] = '当你攻击范围内的角色受到致命伤害时，你可减1点体力上限，此回合防止你与其受到的伤害。',
}

biyue:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(biyue.name) and player:inMyAttackRange(target) and data.damage >= target.hp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = biyue.name,
      prompt = "#tg__shuanggu-ask::" .. target.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not (player.dead or target.dead) then
      room:setPlayerMark(player, "@@tg__shuanggu-turn", 1)
      room:setPlayerMark(target, "@@tg__shuanggu-turn", 1)
    end
  end,
})

biyue:addEffect(fk.DamageInflicted, {
  name = "#tg__shuanggu_trig",
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@tg__shuanggu-turn") > 0
  end,
  on_use = Util.TrueFunc,
})

return biyue
