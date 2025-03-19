local tg__danli = fk.CreateSkill {
  name = "tg__danli"
}

Fk:loadTranslationTable{
  ['tg__danli'] = '胆力',
  ['#tg__danli-ask'] = '胆力：此时为 %arg 开始时，你可摸一张牌并弃置区域内的一张牌',
  [':tg__danli'] = '每回合限X次（X为你已损失的体力值+1），你的每个阶段开始时，你可以摸一张牌并弃置区域内的一张牌。',
}

tg__danli:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and player.phase < Player.NotActive and player.phase > Player.RoundStart and player:usedSkillTimes(tg__danli.name) < player:getLostHp()+1
  end,
  on_cost = function(self, event, target, player)
    local phase_name_table = {
      [2] = "phase_start",
      [3] = "phase_judge",
      [4] = "phase_draw",
      [5] = "phase_play",
      [6] = "phase_discard",
      [7] = "phase_finish",
    }
    return player.room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#tg__danli-ask:::" .. phase_name_table[player.phase]
    })
  end,
  on_use = function(self, event, target, player)
    player:drawCards(1, tg__danli.name)
    local cid = player.room:askToChooseCard(player, {
      target = player,
      flag = "hej",
      skill_name = skill.name
    })
    player.room:throwCard({cid}, skill.name, player, player)
  end,
})

return tg__danli
