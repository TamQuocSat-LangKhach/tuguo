local tg__jianlian = fk.CreateSkill {
  name = "tg__jianlian"
}

Fk:loadTranslationTable{
  ['tg__jianlian'] = '谏练',
  ['#tg__jianlian-prompt'] = '谏练：将一张黑色牌交给一名其他角色，然后观看牌堆顶牌，或令其使用牌',
  ['tg__jianlian_obtain'] = '观看牌堆顶三张牌，获得其中一张，此牌不计入你的手牌上限',
  ['tg__jianlian_use'] = '令%dest对你指定的一名角色使用一张牌',
  ['#tg__jianlian'] = '谏练：观看牌堆顶三张牌，获得其中一张，此牌不计入你的手牌上限',
  ['tg__pingxiGet'] = '获得',
  ['@@tg__jianlian-inhand'] = '谏练',
  ['#tg__jianlian-target'] = '谏练：选择一名角色，令 %dest 对其使用一张牌',
  ['#tg__jianlian-use'] = '谏练：对 %dest 使用一张牌',
  [':tg__jianlian'] = '出牌阶段限一次，你可以将一张黑色牌交给一名其他角色，然后选择一项：1. 观看牌堆顶三张牌，获得其中一张，此牌不计入你的手牌上限；2. 令其对你指定的一名角色使用一张牌。<br /><font color=>（注：暂时bug，无法使用AOE、装备牌等）</font>',
}

tg__jianlian:addEffect('active', {
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(tg__jianlian.name, Player.HistoryPhase) == 0
  end,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  prompt = "#tg__jianlian-prompt",
  on_use = function (skill, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, tg__jianlian.name)
    local choices = {"tg__jianlian_obtain", "tg__jianlian_use::" .. target.id}
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = tg__jianlian.name
    })
    if choice == "tg__jianlian_obtain" then
      local result = room:askToGuanxing(player, {
        cards = room:getNCards(3),
        top_limit = {1, 1},
        skill_name = "#tg__jianlian",
        skip = true,
        area_names = {"Top", "tg__pingxiGet"}
      })
      local cid = result.bottom[1]
      room:obtainCard(player, cid, false, fk.ReasonPrey, player.id, tg__jianlian.name, "@@tg__jianlian-inhand")
    else
      local to = room:askToChoosePlayers(player, {
        targets = table.map(room.alive_players, function(p) return p end),
        min_num = 1,
        max_num = 1,
        prompt = "#tg__jianlian-target::" .. target.id,
        skill_name = tg__jianlian.name
      })[1]
      local use = room:askToUseCard(target, {
        pattern = "",
        prompt = "#tg__jianlian-use::" .. to.id,
        cancelable = false,
        extra_data = {must_targets = {to}}
      })
      if use then
        room:useCard(use)
      end
    end
  end,
})

tg__jianlian:addEffect('maxcards', {
  name = "#tg__jianlian_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@tg__jianlian-inhand") > 0
  end,
})

return tg__jianlian
