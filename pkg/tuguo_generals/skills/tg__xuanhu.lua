local tg__xuanhu = fk.CreateSkill {
  name = "tg__xuanhu"
}

Fk:loadTranslationTable{
  ['tg__xuanhu'] = '悬壶',
  ['#tg__xuanhu-ask'] = '悬壶：你可令一名角色回复1点体力或摸一张牌，然后若其手牌数等于体力值，你可以对不同角色重复此流程',
  ['tg__xuanhu_draw'] = '令%src摸一张牌',
  ['tg__xuanhu_recover'] = '令%src回复1点体力',
  [':tg__xuanhu'] = '当你因弃置而失去牌后，你可以令一名角色回复1点体力或摸一张牌，然后若其手牌数等于体力值，你可以对不同角色重复此流程。',
}

tg__xuanhu:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(tg__xuanhu.name) then return false end
    for _, move in ipairs(event.data.moves) do
      if move.moveReason == fk.ReasonDiscard and move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local target = room:askToChoosePlayers(player, {
      targets = table.map(room.alive_players, function(p) return p.id end),
      min_num = 1,
      max_num = 1,
      prompt = "#tg__xuanhu-ask",
      skill_name = tg__xuanhu.name,
    })
    if #target > 0 then
      event:setCostData(self, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local p = room:getPlayerById(event:getCostData(self))
    local availableTargets = table.map(room.alive_players, function(p) return p.id end)
    while true do
      table.removeOne(availableTargets, p.id)
      local choices = {"tg__xuanhu_draw:" .. p.id}
      if p:isWounded() then table.insert(choices, 1, "tg__xuanhu_recover:" .. p.id) end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = tg__xuanhu.name,
      })
      if choice:startsWith("tg__xuanhu_draw") then
        p:drawCards(1, tg__xuanhu.name)
      else
        room:recover({
          who = p,
          num = 1,
          recoverBy = player,
          skillName = tg__xuanhu.name,
        })
      end
      if p.hp ~= p:getHandcardNum() or player.dead or #availableTargets == 0 then
        break
      else
        local target = room:askToChoosePlayers(player, {
          targets = availableTargets,
          min_num = 1,
          max_num = 1,
          prompt = "#tg__xuanhu-ask",
          skill_name = tg__xuanhu.name,
        })
        if #target > 0 then
          p = room:getPlayerById(target[1])
        else
          break
        end
      end
    end
  end,
})

return tg__xuanhu
