local tg__pingxi = fk.CreateSkill {
  name = "tg__pingxi"
}

Fk:loadTranslationTable{
  ['tg__pingxi'] = '平袭',
  ['#tg__pingxi-ask'] = '平袭：你可以弃置 %src 两张牌，若这两张牌：花色相同，你获得其中一张；点数相同，你对其造成1点伤害',
  ['tg__pingxiGain'] = '平袭',
  ['tg__pingxiNoGet'] = '不获得',
  ['tg__pingxiGet'] = '获得',
  [':tg__pingxi'] = '当你受到伤害后，若你的手牌数小于伤害来源，你可以弃置其两张牌，若这两张牌：花色相同，你获得其中一张；点数相同，你对其造成1点伤害。',
}

tg__pingxi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.from and data.from:getHandcardNum() > player:getHandcardNum() and #data.from:getCardIds{Player.Hand, Player.Equip} > 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = skill.name, prompt = "#tg__pingxi-ask:" .. data.from.id })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    local cids = room:askToChooseCards(player, {
      min = 2,
      max = 2,
      target = from,
      flag = "he",
      skill_name = skill.name
    })
    room:throwCard(cids, skill.name, from, player)
    local cards1, cards2 = Fk:getCardById(cids[1]), Fk:getCardById(cids[2])
    if cards1.suit == cards2.suit then
      local guanxing_result = room:askToGuanxing(player, {
        cards = cids,
        bottom_limit = { 1, 1 },
        skill_name = "tg__pingxiGain",
        skip = true,
        area_names = { "tg__pingxiNoGet", "tg__pingxiGet" }
      })
      local cards = guanxing_result.bottom
      if #cards > 0 then
        room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
      end
    end
    if cards1.number == cards2.number and not (player.dead or from.dead) then
      room:damage{
        from = player,
        to = from,
        damage = 1,
        skillName = skill.name,
      }
    end
  end,
})

return tg__pingxi
