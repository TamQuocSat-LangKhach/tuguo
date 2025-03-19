local biyue = fk.CreateSkill {
  name = "tg__siye"
}

Fk:loadTranslationTable{
  ['tg__siye'] = '肆野',
  ['@@tg__siye-round'] = '肆野 必须发动',
  ['#tg__siye'] = '你可发动“肆野”，摸 %arg 张牌，然后本轮你必须发动此技能',
  ['@tg__langbu-round'] = '狼逋',
  [':tg__siye'] = '当主公受到【杀】的伤害后，你可以摸X+1张牌（X为本轮〖狼逋〗发动过的次数且至多为3），然后本轮你必须发动此技能。',
}

biyue:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(biyue.name) then return false end
    return target.role == "lord" and data.card and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player)
    return player:getMark("@@tg__siye-round") > 0 or player.room:askToSkillInvoke(player, {
      skill_name = biyue.name,
      prompt = "#tg__siye:::" .. math.min(player:getMark("@tg__langbu-round"), 3) + 1
    })
  end,
  on_use = function(self, event, target, player)
    player:drawCards(math.min(player:getMark("@tg__langbu-round"), 3) + 1, biyue.name)
    if not player.dead then player.room:setPlayerMark(player, "@@tg__siye-round", 1) end
  end,
})

return biyue
