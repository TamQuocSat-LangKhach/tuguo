local tg__yanfa = fk.CreateSkill {
  name = "tg__yanfa"
}

Fk:loadTranslationTable{
  ['tg__yanfa'] = '掩伐',
  ['#tg__yanfa'] = '掩伐：你可视为对 %dest 使用一张【杀】',
  ['#tg__yanfa_discard'] = '掩伐[弃牌]',
  ['tg__yanfa_hand'] = '弃置所有手牌，令此【杀】无效，%src获得其中点数最大的牌并翻面',
  ['tg__yanfa_equip'] = '弃置所有装备区里的牌，令此【杀】无效，%src获得其中点数最大的牌并翻面',
  [':tg__yanfa'] = '每回合对每名角色限一次，当你对其他角色造成伤害后，你可以视为对其使用一张【杀】，当其成为此【杀】的目标后，其可以弃置所有手牌或所有装备区里的牌，令此【杀】无效，你获得其中点数最大的牌并翻面。',
}

tg__yanfa:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tg__yanfa) and data.to:getMark("_tg__yanfa_" .. player.id .. "-turn") == 0 and data.to ~= player
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = tg__yanfa.name, prompt = "#tg__yanfa::" .. data.to.id })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local slash = Fk:cloneCard("slash")
    slash.skillName = tg__yanfa.name
    local use = {
      from = player.id,
      tos = { {data.to.id} },
      card = slash,
    }
    slash.extra_data = slash.extra_data or {}
    slash.extra_data.tg__yanfaTarget = data.to.id
    slash.extra_data.tg__yanfaUser = player.id
    room:addPlayerMark(data.to, "_tg__yanfa_" .. player.id .. "-turn")
    room:useCard(use)
  end,
})

tg__yanfa:addEffect(fk.TargetConfirmed, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, tg__yanfa.name) and not player:isNude() and (data.card.extra_data or {}).tg__yanfaTarget == player.id
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    local from = (data.card.extra_data or {}).tg__yanfaUser
    if not player:isKongcheng() then table.insert(choices, "tg__yanfa_hand:" .. from) end --摆了
    if #player:getCardIds("e") > 0 then table.insert(choices, "tg__yanfa_equip:" .. from) end
    if #choices == 0 then return false end
    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(player, { choices = choices, skill_name = tg__yanfa.name })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self)
    local cids
    if choice:startsWith("tg__yanfa_hand") then
      cids = player:getCardIds("h")
      player:throwAllCards("h")
    else
      cids = player:getCardIds("e")
      player:throwAllCards("e")
    end
    table.forEach(room.alive_players, function(p)
      table.insertIfNeed(data.nullifiedTargets, p.id)
    end)
    local from = room:getPlayerById((data.card.extra_data or {}).tg__yanfaUser)
    local num = -1
    for _, id in ipairs(cids) do
      local card = Fk:getCardById(id)
      if card.number > num then num = card.number end
    end
    local dummy = Fk:cloneCard("dilu")
    for _, id in ipairs(cids) do
      local card = Fk:getCardById(id)
      if card.number == num and room:getCardArea(id) == Card.DiscardPile then dummy:addSubcard(id) end
    end
    room:delay(1200)
    if #dummy.subcards > 0 then room:obtainCard(from, dummy, true) end
    from:turnOver()
  end,
})

return tg__yanfa
