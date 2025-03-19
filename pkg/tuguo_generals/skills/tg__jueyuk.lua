local tg__jueyuk = fk.CreateSkill {
  name = "tg__jueyuk"
}

Fk:loadTranslationTable{
  ['tg__jueyuk'] = '绝域',
  [':tg__jueyuk'] = '锁定技，手牌多于你的角色至你距离+1。',
}

tg__jueyuk:addEffect('distance', {
  correct_func = function(self, player, from, to)
    if to:hasSkill(tg__jueyuk.name) and from:getHandcardNum() > to:getHandcardNum() then
      return 1
    end
  end,
})

return tg__jueyuk
