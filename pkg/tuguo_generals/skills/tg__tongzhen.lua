local tg__tongzhen = fk.CreateSkill {
  name = "tg__tongzhen"
}

Fk:loadTranslationTable{
  ['tg__tongzhen'] = '恸阵',
  ['@tg__tongzhen'] = '恸阵',
  ['tg__losehandcard'] = '失',
  ['tg__afterdying'] = '脱',
  ['tg__lonearmy'] = '孤',
  ['tg__die'] = '死',
  ['#tg__tongzhen-choose'] = '恸阵：你可视为使用一张无距离、次数和目标数限制的【杀】，此【杀】的伤害值基数为 %arg',
  [':tg__tongzhen'] = '当你{失去最后的手牌/脱离濒死/所属阵营变为仅剩一人/死亡}后，你可以视为使用一张无距离、次数和目标数限制的【杀】，此【杀】的伤害值基数为你触发过的〖恸阵〗条件数。<font color=>其实叫“<b>韩瑛&韩瑶&韩琼&韩琪</b>”，名字太长……“伵”xù（@韩旭）',
}

tg__tongzhen:addEffect({fk.AfterCardsMove, fk.AfterDying, fk.Death, fk.Deathed, fk.GameStart}, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(tg__tongzhen.name, false, true) or player:prohibitUse(Fk:cloneCard("slash")) then return false end
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(target.data) do
        if move.from and move.from == player.id then
          if player:isKongcheng() and not player.dead and table.find(move.moveInfo, function (info)
            return info.fromArea == Card.PlayerHand end) then
            return true
          end
        end
      end
    elseif event == fk.AfterDying then
      return target == player and not player.dead --似了也会有脱离濒死的时机触发
    elseif event == fk.Death then
      return target == player
    else
      if player:getMark("_tg__tongzhen_lonearmy") == 1 then return false end
      local n = 0
      if player.role == "lord" or player.role == "loyalist" then --不行的
        n = #table.filter(room.alive_players, function(p) return p.role == "lord" or p.role == "loyalist" end)
      elseif player.role == "rebel" then
        n = #table.filter(room.alive_players, function(p) return p.role == "rebel" end)
      elseif player.role == "renegade" then
        n = #table.filter(room.alive_players, function(p) return p.role == "renegade" end)
      end
      return n == 1
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local card = Fk:cloneCard("slash")
    local availableTargets = table.map(table.filter(room.alive_players, function(p) return p ~= player and not player:isProhibited(p, card) end), function(p) return p.id end)
    if #availableTargets == 0 then return false end
    local mark = type(player:getMark("@tg__tongzhen")) == "table" and player:getMark("@tg__tongzhen") or {}
    local mark_name = {[fk.AfterCardsMove] = "tg__losehandcard", [fk.AfterDying] = "tg__afterdying", [fk.Deathed] = "tg__lonearmy", [fk.Death] = "tg__die", [fk.GameStart] = "tg__lonearmy"}
    table.insertIfNeed(mark, mark_name[event])
    local targets = room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 99,
      prompt = "#tg__tongzhen-choose:::" .. #mark,
      skill_name = tg__tongzhen.name,
      cancelable = true
    })
    if #targets > 0 then
      event:setCostData(self, targets)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if event == fk.Deathed or event == fk.GameStart then
      room:setPlayerMark(player, "_tg__tongzhen_lonearmy", 1)
    end
    local mark = type(player:getMark("@tg__tongzhen")) == "table" and player:getMark("@tg__tongzhen") or {}
    local mark_name = {[fk.AfterCardsMove] = "tg__losehandcard", [fk.AfterDying] = "tg__afterdying", [fk.Deathed] = "tg__lonearmy", [fk.Death] = "tg__die", [fk.GameStart] = "tg__lonearmy"}
    table.insertIfNeed(mark, mark_name[event])
    room:setPlayerMark(player, "@tg__tongzhen", mark)
    local slash = Fk:cloneCard("slash")
    slash.skillName = tg__tongzhen.name
    local use = {
      from = player.id,
      tos = table.map(event:getCostData(self), function(pid) return {pid} end),
      card = slash,
      additionalDamage = #mark - 1,
      extraUse = true,
    }
    room:useCard(use)
  end,
})

return tg__tongzhen
