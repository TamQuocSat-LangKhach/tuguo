local langbu = fk.CreateSkill {
  name = "tg__langbu"
}

Fk:loadTranslationTable{
  ['tg__langbu'] = '狼逋',
  ['@tg__langbu-round'] = '狼逋',
  [':tg__langbu'] = '锁定技，当你摸牌时，你视为使用一张【违害就利】；你使用【违害就利】观看牌数-X（X为本轮〖狼逋〗已发动次数且至多为3），若已减至0，此牌的效果改为令你失去1点体力或减1点体力上限。<br/><font color=>【<b>违害就利</b>】锦囊牌 你从牌堆摸牌或进行判定时，对你使用。目标角色观看牌堆顶的三张牌，然后将其中任意张牌置于弃牌堆。',
}

langbu:addEffect(fk.BeforeDrawCard, {
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(langbu) then
      local card = Fk:cloneCard("avoiding_disadvantages")
      return not player:prohibitUse(card) and not player:isProhibited(player, card)
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(langbu.name)
    room:notifySkillInvoked(player, langbu.name, player:getMark("@tg__langbu-round") < 3 and "drawcard" or "negative")
    room:useVirtualCard("avoiding_disadvantages", nil, player, player, langbu.name) --摆
    if not player.dead then room:addPlayerMark(player, "@tg__langbu-round") end
  end,
})

return langbu
