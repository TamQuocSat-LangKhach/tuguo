local skill = fk.CreateSkill {
  name = "defeating_the_double_active",
}

Fk:loadTranslationTable{
  ["defeating_the_double_active"] = "以半击倍",
}

skill:addEffect("active", {
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select) and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and not to_select:isKongcheng() and to_select:getHandcardNum() == #selected_cards * 2
  end,
})

return skill
