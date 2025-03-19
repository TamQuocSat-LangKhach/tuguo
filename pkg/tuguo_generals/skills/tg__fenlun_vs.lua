local tg__fenlun = fk.CreateSkill {
  name = "tg__fenlun"
}

Fk:loadTranslationTable{
  ['tg__fenlun_vs'] = '忿论',
}

tg__fenlun:addEffect('viewas', {
  card_filter = function(self, player, card) return false end,
  card_num = 0,
  interaction = function(self)
    local allCardNames = {}
    for _, name in ipairs(player:getMark("_tg__fenlun_cards")) do
      local card = Fk:cloneCard(name)
      card.skillName = tg__fenlun.name
      if not player:prohibitUse(card) and player:canUse(card) then
        table.insertIfNeed(allCardNames, name)
      end
    end
    return UI.ComboBox { choices = allCardNames, all_choices = player:getMark("_tg__fenlun_cards") }
  end,
  view_as = function(self, player, cards)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = tg__fenlun.name
    return c
  end,
  enabled_at_play = function(self, player)
    return false
  end,
  enabled_at_response = function(self, player)
    return false
  end,
})

return tg__fenlun
