local extension = Package("tuguo_generals")
extension.extensionName = "tuguo"

Fk:loadTranslationTable{
  ["tuguo"] = "图国篇", --strengthening the country，但是好长
  ["tuguo_generals"] = "图国篇",
  ["tg"] = "图国",
}

local tg__wangchang = General(extension, "tg__wangchang", "wei", 3)

local tg__kaiji = fk.CreateActiveSkill{
  name = "tg__kaiji",
  anim_type = "drawcard",
  mute = true,
  switch_skill_name = "tg__kaiji",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and (player:getSwitchSkillState(self.name) == fk.SwitchYang or player:getHandcardNum() >= player:getMaxCards())
  end,
  card_filter = function() return false end,
  card_num = 0,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke("ty__kaiji")
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:notifySkillInvoked(player, self.name, "drawcard")
      local num = player:getMaxCards() - player:getHandcardNum()
      if num > 0 then player:drawCards(num, self.name) end
    else
      room:notifySkillInvoked(player, self.name, "negative")
      local num = player:getMaxCards()
      room:askForDiscard(player, num, num, false, self.name, false, nil, "#tg__kaiji-discard:::" .. num)
    end
  end,
}

local tg__pingxi = fk.CreateTriggerSkill{
  name = "tg__pingxi",
  events = {fk.Damaged},
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from:getHandcardNum() > player:getHandcardNum() and #data.from:getCardIds{Player.Hand, Player.Equip} > 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#tg__pingxi-ask:" .. data.from.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    local cids = room:askForCardsChosen(player, from, 2, 2, "he",self.name)
    room:throwCard(cids, self.name, from, player)
    local cards1, cards2 = Fk:getCardById(cids[1]), Fk:getCardById(cids[2])
    if cards1.suit == cards2.suit then
      local cards = room:askForGuanxing(player, cids, nil, {1, 1}, "tg__pingxiGain", true, {"tg__pingxiNoGet", "tg__pingxiGet"}).bottom
      if #cards > 0 then
        room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
      end
    end
    if cards1.number == cards2.number and not (player.dead or from.dead) then
      room:damage{
        from = player,
        to = from,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}

tg__wangchang:addSkill(tg__kaiji)
tg__wangchang:addSkill(tg__pingxi)

Fk:loadTranslationTable{
  ["tg__wangchang"] = "王昶", --TG001 攥策及江 插画绘制：B_LEE 技能设计：韩旭 称号设计：圣帝
  ["tg__kaiji"] = "开济",
  [":tg__kaiji"] = "转换技，出牌阶段限一次，阳：你可以将手牌摸至X张；阴：你可以弃置X张手牌。（X为你的手牌上限）",
  ["tg__pingxi"] = "平袭",
  [":tg__pingxi"] = "当你受到伤害后，若你的手牌数小于伤害来源，你可以弃置其两张牌，若这两张牌：花色相同，你获得其中一张；点数相同，你对其造成1点伤害。",

  ["#tg__kaiji-discard"] = "开济：弃置 %arg 张手牌",
  ["#tg__pingxi-ask"] = "平袭：你可以弃置 %src 两张牌，若这两张牌：花色相同，你获得其中一张；点数相同，你对其造成1点伤害",
  ["tg__pingxiGain"] = "平袭",
  ["tg__pingxiNoGet"] = "不获得",
  ["tg__pingxiGet"] = "获得",
}

local tg__xuzhi = General(extension, "tg__xuzhi", "wei", 4)

local tg__fenwei = fk.CreateTriggerSkill{
  name = "tg__fenwei",
  events = {fk.CardUseFinished},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player or not player:hasSkill(self) or player:usedSkillTimes(self.name) > 0 or table.find(player.room.alive_players, function(p)
      return p.dying
    end) then return false end
    if data.card.name == "jink" then return true end
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
      local use = e.data[1]
      return use.card.name == data.card.name
    end, Player.HistoryTurn)
    return #events > 1 and events[2].id == player.room.logic:getCurrentEvent().id
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    for _, n in ipairs({"duel", "slash"}) do
      local card = Fk:cloneCard(n)
      if not player:prohibitUse(card) and not player:isProhibited(target, card) and (n == "duel" or player:inMyAttackRange(target)) then
        table.insert(choices, "tg__fenwei_" .. n .. "_::" .. target.id) --摆
      end
    end
    if #choices == 0 then return false end
    table.insert(choices, "Cancel")
    local choice = player.room:askForChoice(player, choices, self.name, "#tg__fenwei::" .. target.id)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    local choice = self.cost_data:split("_")[4]
    player.room:useVirtualCard(choice, nil, player, target, self.name, true)
  end,
}

local tg__yanfa = fk.CreateTriggerSkill{
  name = "tg__yanfa",
  events = {fk.Damage},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to:getMark("_tg__yanfa_" .. player.id .. "-turn") == 0 and data.to ~= player
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#tg__yanfa::" .. data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
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
}
local tg__yanfa_discard = fk.CreateTriggerSkill{
  name = "#tg__yanfa_discard",
  events = {fk.TargetConfirmed},
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
    local choice = player.room:askForChoice(player, choices, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data
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
}
tg__yanfa:addRelatedSkill(tg__yanfa_discard)

tg__xuzhi:addSkill(tg__fenwei)
tg__xuzhi:addSkill(tg__yanfa)

Fk:loadTranslationTable{
  ["tg__xuzhi"] = "徐质", --TG002 覆天穷斗 插画绘制：Aimer彩三 技能设计：竹沐雨 称号设计：雪侯
  ["tg__fenwei"] = "奋围",
  [":tg__fenwei"] = "每回合限一次，其他角色使用【闪】或本回合第二张同名牌结算结束后，若没有角色处于濒死状态，你可以翻面，视为对其使用一张【决斗】或【杀】（有距离限制）。",
  ["tg__yanfa"] = "掩伐",
  [":tg__yanfa"] = "每回合对每名角色限一次，当你对其他角色造成伤害后，你可以视为对其使用一张【杀】，当其成为此【杀】的目标后，其可以弃置所有手牌或所有装备区里的牌，令此【杀】无效，你获得其中点数最大的牌并翻面。",

  ["#tg__fenwei"] = "奋围：你可翻面，视为对 %dest 使用一张【决斗】或【杀】",
  ["tg__fenwei_duel_"] = "翻面，视为对%dest使用【决斗】",
  ["tg__fenwei_slash_"] = "翻面，视为对%dest使用【杀】",
  ["#tg__yanfa"] = "掩伐：你可视为对 %dest 使用一张【杀】",
  ["#tg__yanfa_discard"] = "掩伐[弃牌]",
  ["tg__yanfa_hand"] = "弃置所有手牌，令此【杀】无效，%src获得其中点数最大的牌并翻面",
  ["tg__yanfa_equip"] = "弃置所有装备区里的牌，令此【杀】无效，%src获得其中点数最大的牌并翻面",
}

local tg__dailing = General(extension, "tg__dailing", "wei", 4)

local tg__zhoubing = fk.CreateTriggerSkill{
  name = "tg__zhoubing",
  anim_type = "offensive",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.to == Player.NotActive and target ~= player and target.skipped_phases and not player:prohibitUse(Fk:cloneCard("slash"))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, phase in ipairs({Player.Start, Player.Judge, Player.Draw, Player.Play, Player.Discard, Player.Finish}) do
      if target.skipped_phases[phase] then
        n = n + 1
      end
    end
    local card = Fk:cloneCard("slash")
    local availableTargets = table.map(table.filter(room.alive_players, function(p) return p ~= player and not player:isProhibited(p, card) end), function(p) return p.id end)
    if #availableTargets == 0 then return false end
    local targets = room:askForChoosePlayers(player, availableTargets, n, n, "#tg__zhoubing-choose:::" .. n, self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(self.cost_data, function(pid) return room:getPlayerById(pid) end)
    room:useVirtualCard("slash", nil, player, targets, self.name, true)
  end,
}

local tg__rangtu = fk.CreateTriggerSkill{
  name = "tg__rangtu",
  events = {fk.EventPhaseStart},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Start and player ~= target and target.hp >= player.hp and not player:isKongcheng() and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#tg__rangtu::" .. target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pd = player:pindian({target}, self.name)
    if pd.results[target.id].winner == player then
      local phase = {"phase_judge", "phase_draw", "phase_play", "phase_discard", "phase_finish"}
      target:skip(table.indexOf(phase, room:askForChoice(player, phase, self.name, "#tg__rangtu-skip:" .. player.id)) + 2)
    else
      player:showCards(player:getCardIds(Player.Hand))
      room:addPlayerMark(player, "@@tg__rangtu")
    end
  end,
}
local tg__rangtu_negative = fk.CreateTriggerSkill{
  name = "#tg__rangtu_negative",
  anim_type = "negative",
  events = {fk.PindianCardsDisplayed},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@tg__rangtu") > 0 and (data.from == player or table.contains(data.tos, player))
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tg__rangtu", 0)
    if data.from == player then
      data.fromCard.number = math.max(data.fromCard.number - 2, 1)
    else
      data.results[player.id].toCard.number = math.max(data.results[player.id].toCard.number  - 2, 1)
    end
  end,
}
tg__rangtu:addRelatedSkill(tg__rangtu_negative)

tg__dailing:addSkill(tg__zhoubing)
tg__dailing:addSkill(tg__rangtu)

Fk:loadTranslationTable{
  ["tg__dailing"] = "戴陵", --TG003 望断群峦 插画绘制：恶童 技能设计：恶童 称号设计：（众人集思广益） 
  ["tg__zhoubing"] = "骤兵",
  [":tg__zhoubing"] = "其他角色的回合结束时，你可以视为使用一张无距离限制且目标数为X的【杀】（X为其本回合跳过的阶段数）。",
  ["tg__rangtu"] = "攘途",
  [":tg__rangtu"] = "其他角色的准备阶段，若其体力值不小于你，你可以与其拼点：若你赢，你令其跳过本回合的一个阶段；若你没赢，你展示所有手牌，你下次拼点点数-2。",

  ["#tg__zhoubing-choose"] = "骤兵：你可以视为使用一张无距离限制且目标数为%arg的【杀】",
  ["#tg__rangtu"] = "攘途：你可与 %dest 拼点：若你赢，你令其跳过本回合的一个阶段；若你没赢，你展示所有手牌，你下次拼点点数-2",
  ["#tg__rangtu-skip"] = "攘途：令 %src 跳过本回合的一个阶段",
  ["@@tg__rangtu"] = "攘途 拼点-2",
  ["#tg__rangtu_negative"] = "攘途",
}

local tg__zhongyu = General(extension, "tg__zhongyu", "wei", 3)

local tg__jianlian = fk.CreateActiveSkill{
  name = "tg__jianlian",
  anim_type = "support",
  can_use = function (self, player, card)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, player)
    local card = Fk:getCardById(to_select) --?
    return card and card.color == Card.Black
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function (self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, self.name)
    local choices = {"tg__jianlian_obtain", "tg__jianlian_use::" .. target.id}
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "tg__jianlian_obtain" then
      local result = room:askForGuanxing(player, room:getNCards(3), nil, {1, 1}, "#tg__jianlian", true, {"Top", "tg__pingxiGet"})
      local top, cid = result.top, result.bottom[1]
      for i = #top, 1, -1 do
        table.insert(room.draw_pile, 1, top[i])
      end
      room:setCardMark(Fk:getCardById(cid), "@@tg__jianlian-inhand", 1)
      room:obtainCard(player, cid, false, fk.ReasonPrey)
    else
      local to = room:askForChoosePlayers(player, table.map(room.alive_players, function(p) return p.id end), 1, 1, "#tg__jianlian-target::" .. target.id, self.name, false)[1]
      local use = room:askForUseCard(target, "", ".", "#tg__jianlian-use::" .. to, false, {must_targets = {to} }) --false!
      if use then
        room:useCard(use)
      end
    end
  end,
}
local tg__jianlian_maxcards = fk.CreateMaxCardsSkill{
  name = "#tg__jianlian_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@tg__jianlian-inhand") > 0
  end,
}
tg__jianlian:addRelatedSkill(tg__jianlian_maxcards)

local tg__wanzu = fk.CreateTriggerSkill{
  name = "tg__wanzu",
  events = {fk.EventPhaseChanging},
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or data.to ~= Player.NotActive then return false end
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 999, function(e)
      for _, move in ipairs(e.data) do
        if move and move.toArea == Card.PlayerHand and move.from == player.id and move.to and player.room:getPlayerById(move.to) and move.to ~= player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end, Player.HistoryTurn)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 999, function(e)
      local move = e.data[1]
      if move.toArea == Card.PlayerHand and move.from == player.id and move.to and room:getPlayerById(move.to) and move.to ~= player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(targets, move.to)
          end
        end
      end
    end, Player.HistoryTurn)
    local target = room:askForChoosePlayers(player, targets, 1, 1, "#tg__wanzu-target", self.name, true)
    if #target > 0 then
      target = target[1]
      local choices = {"tg__wanzu_distance:" .. target, "Cancel"}
      if not room:getPlayerById(target):isAllNude() then
        table.insert(choices, 1, "tg__wanzu_move:" .. target)
      end
      local choice = room:askForChoice(player, choices, self.name)
      if choice ~= "Cancel" then
        self.cost_data = {choice, target}
        return true
      end
    end    
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice, target = self.cost_data[1], room:getPlayerById(self.cost_data[2])
    if choice:startsWith("tg__wanzu_distance") then
      room:addPlayerMark(target, "@tg__wanzu_distance")
    else
      local id = room:askForCardChosen(player, target, "hej", self.name)
      local fromArea = room:getCardArea(id)
      local move3 = {
        ids = {id},
        fromArea = fromArea,
        from = target.id,
        to = player.id,
        toArea = fromArea,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      }
      local card = Fk:getCardById(id)
      local equip = fromArea == Card.PlayerEquip and player:getEquipment(card.sub_type) ~= nil
      local judge = fromArea == Card.PlayerJudge and player:hasDelayedTrick(card.name)
      if equip or judge then
        local ids
        if equip then
          ids = {player:getEquipment(card.sub_type)}
        else
          for _, i in ipairs(player:getCardIds(Player.Judge)) do
            local c = player:getVirualEquip(i)
            if not c then c = Fk:getCardById(i) end
            if c.name == card.name then
              ids = {i}
              break
            end
          end
        end
        local move2 = {
          ids = ids,
          from = player.id,
          fromArea = fromArea,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonJustMove,
        }
        room:moveCards(move2, move3)
      else
        room:moveCards(move3)
      end
    end
  end,
}
local tg__wanzu_dis_remove = fk.CreateTriggerSkill{
  name = "#tg__wanzu_dis_remove",
  mute = true,
  events = {fk.HpChanged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@tg__wanzu_distance") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@tg__wanzu_distance", 0)
  end,
}
local tg__wanzu_dis = fk.CreateDistanceSkill{
  name = "#tg__wanzu_dis",
  correct_func = function(self, from, to)
    if to:getMark("@tg__wanzu_distance") > 0 then
      return to:getMark("@tg__wanzu_distance")
    end
  end,
}
tg__wanzu:addRelatedSkill(tg__wanzu_dis)
tg__wanzu:addRelatedSkill(tg__wanzu_dis_remove)

tg__zhongyu:addSkill(tg__jianlian)
tg__zhongyu:addSkill(tg__wanzu)

Fk:loadTranslationTable{
  ["tg__zhongyu"] = "钟毓", --TG004 温恭的瞻略者 插画绘制：琛·美弟奇 技能设计：Z.诺贝尔 称号设计：羌溪散人
  ["tg__jianlian"] = "谏练",
  [":tg__jianlian"] = "出牌阶段限一次，你可以将一张黑色牌交给一名其他角色，然后选择一项：1. 观看牌堆顶三张牌，获得其中一张，此牌不计入你的手牌上限；2. 令其对你指定的一名角色使用一张牌。<br /><font color='grey'>（注：暂时bug，无法使用AOE、装备牌等）</font>", --1. 观看图国牌堆中共计三张牌，将其中一张置入你的图国区
  ["tg__wanzu"] = "完族",
  [":tg__wanzu"] = "一名角色的回合结束时，你可以选择一名本回合获得过你的牌的角色并选择一项：1. 将其区域内的一张牌移动至你的相同区域（替换原有牌）；2. 令除其外的角色至其距离+1，直至其体力值变化。",

  ["tg__jianlian_obtain"] = "观看牌堆顶三张牌，获得其中一张，此牌不计入你的手牌上限",
  ["tg__jianlian_use"] = "令%dest对你指定的一名角色使用一张牌",
  ["#tg__jianlian"] = "谏练：观看牌堆顶三张牌，获得其中一张，此牌不计入你的手牌上限",
  ["@@tg__jianlian-inhand"] = "谏练",
  ["#tg__jianlian-target"] = "谏练：选择一名角色，令 %dest 对其使用一张牌",
  ["#tg__jianlian-use"] = "谏练：对 %dest 使用一张牌",
  ["#tg__wanzu-target"] = "你可以对一名本回合获得过你的牌的角色发动“完族”",
  ["tg__wanzu_distance"] = "令除%src外的角色至其距离+1，直至其体力值变化",
  ["tg__wanzu_move"] = "将%src区域内的一张牌移动至你的相同区域",
  ["@tg__wanzu_distance"] = "完族 至其距离+",
  ["#tg__wanzu_dis_remove"] = "完族[距离清零]",
}
local tg__liaoli = General(extension, "tg__liaoli", "shu", 3)

local tg__fenlun = fk.CreateTriggerSkill{
  name = "tg__fenlun",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.to == Player.NotActive and target ~= player and not player:isKongcheng() and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#tg__fenlun-invoke:"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = target
    while true do
      room:addPlayerMark(to, "_tg__fenlun", 1)
      local pd = player:pindian({to}, self.name)
      if pd.results[to.id].winner == player then
        local events = room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
          local use = e.data[1]
          return use.from == room.current.id and (use.card.type == Card.TypeBasic or use.card:isCommonTrick())
        end, Player.HistoryTurn)
        if #events == 0 then break end
        local cards = {}
        table.forEach(events, function(e)
          table.insertIfNeed(cards, e.data[1].card.name)
        end)
        room:setPlayerMark(player, "_tg__fenlun_cards", cards)
        local success, dat = room:askForUseViewAsSkill(player, "tg__fenlun_vs", "#tg__fenlun-vs:" .. target.id, true)
        if success then
          local card = Fk.skills["tg__fenlun_vs"]:viewAs(dat.cards)
          local use = {
            from = player.id,
            tos = table.map(dat.targets, function(e) return {e} end),
            card = card,
          }
          room:useCard(use)
        end
        room:setPlayerMark(player, "_tg__fenlun_cards", 0)
        break
      else
        if player:isKongcheng() then break end
        local availableTargets = table.map(table.filter(room.alive_players, function(p) return p ~= player and not p:isKongcheng() and p:getMark("_tg__fenlun") == 0 end), function(p) return p.id end)
        if #availableTargets == 0 then break end
        local targets = room:askForChoosePlayers(player, availableTargets, 1, 1, "#tg__fenlun-again", self.name, true)
        if #targets == 0 then break end
        to = room:getPlayerById(targets[1])
        room:doIndicate(player.id, {to.id})
        room:notifySkillInvoked(player, self.name)
      end
    end
    table.forEach(room.alive_players, function(p) room:setPlayerMark(p, "_tg__fenlun", 0) end)
  end,
}
local tg__fenlun_vs = fk.CreateViewAsSkill{
  name = "tg__fenlun_vs",
  card_filter = function(self, card) return false end,
  card_num = 0,
  interaction = function(self)
    local allCardNames = {}
    for _, name in ipairs(Self:getMark("_tg__fenlun_cards")) do
      local card = Fk:cloneCard(name)
      card.skillName = self.name
      if not Self:prohibitUse(card) and Self:canUse(card) then
        table.insertIfNeed(allCardNames, name)
      end
    end
    return UI.ComboBox { choices = allCardNames, all_choices = Self:getMark("_tg__fenlun_cards") }
  end,
  view_as = function(self, cards)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function(self, player)
    return false
  end,
  enabled_at_response = function(self, player)
    return false
  end,
}
Fk:addSkill(tg__fenlun_vs)

local tg__qihcai = fk.CreateTriggerSkill{
  name = "tg__qihcai",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove, fk.PindianResultConfirmed},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:usedSkillTimes(self.name, Player.HistoryRound) > 0 then return false end
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from and move.from == player.id then
          if player:isKongcheng() and not player.dead and table.find(move.moveInfo, function (info)
              return info.fromArea == Card.PlayerHand end) then
            return true
          end
        end
      end
    else
      return (data.from == player or table.contains(data.tos, player)) and data.winner ~= player
    end
  end,
  on_cost = function(self, event, target, player, data)
    local events = player.room.logic:getEventsOfScope(GameEvent.Pindian, 998, function(e) 
      local pd = e.data[1]
      return pd.from == player or table.contains(pd.tos, player)
    end, Player.HistoryRound)
    local num = 0
    for _, e in ipairs(events) do
      local pd = e.data[1]
      for _, result in pairs(pd.results) do
        if result.winner ~= player then
          num = num + 1
        end
      end
    end
    if event == fk.AfterCardsMove then num = num - 1 end
    if player.room:askForSkillInvoke(player, self.name, data, "#tg__qihcai-ask:::"..num) then
      self.cost_data = num
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local num = self.cost_data
    local room = player.room
    player:drawCards(num, self.name)
    room:setPlayerMark(player, "@tg__qihcai", "-" .. tostring(num))
  end,

  refresh_events = {fk.EventPhaseChanging, fk.Death},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@tg__qihcai") ~= 0 and (event == fk.Death or data.from == Player.NotActive)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@tg__qihcai", 0)
  end,
}
local tg__qihcai_minus = fk.CreateTriggerSkill{
  name = "#tg__qihcai_minus",
  anim_type = "negative",
  events = {fk.PindianCardsDisplayed},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@tg__qihcai") > 0 and (data.from == player or table.contains(data.tos, player))
  end,
  on_use = function(self, event, target, player, data)
    local num = tonumber(player:getMark("@tg__qihcai"))
    if data.from == player then
      data.fromCard.number = math.max(data.fromCard.number + num, 1)
    else
      data.results[player.id].toCard.number = math.max(data.results[player.id].toCard.number + num, 1)
    end
  end,
}
tg__qihcai:addRelatedSkill(tg__qihcai_minus)

tg__liaoli:addSkill(tg__fenlun)
tg__liaoli:addSkill(tg__qihcai)

Fk:loadTranslationTable{
  ["tg__liaoli"] = "廖立", --TG006 䯄足难踏 插画绘制：周千策 技能设计：理亚&竹沐雨 称号设计：圣帝
  ["tg__fenlun"] = "忿论",
  [":tg__fenlun"] = "其他角色的回合结束时，你可以与其拼点：若你赢，你可以视为使用一张当前回合角色此回合使用过的基本或普通锦囊牌；若你没赢，你可以与此次发动技能未选择过的一名角色重复此流程。", --你可以视为使用一张该角色本回合使用过且被其他角色响应过的牌
  ["tg__qihcai"] = "弃才",
  [":tg__qihcai"] = "每轮限一次，你的回合外，当你失去最后的手牌后或拼点没赢时，你可以摸X张牌，然后直到你下回合开始，你的拼点牌的点数-X（X为你本轮拼点没赢的次数）。",

  ["#tg__fenlun-invoke"] = "忿论：你可与 %src 拼点",
  ["#tg__fenlun-again"] = "忿论：你可与一名角色拼点",
  ["tg__fenlun_vs"] = "忿论",
  ["#tg__fenlun-vs"] = "忿论：你可视为使用一张 %src 此回合使用过的基本或普通锦囊牌",
  ["#tg__qihcai-ask"] = "弃才：你可摸 %arg 张牌，直到你下回合开始，你的拼点牌的点数-X",
  ["@tg__qihcai"] = "弃才拼点",
}

local tg__luoxian = General(extension, "tg__luoxian", "shu", 4)

local tg__jiancheng = fk.CreateViewAsSkill{
  name = "tg__jiancheng",
  card_filter = function() return false end,
  card_num = 0,
  pattern = "^nullification|.|.|.|.|basic",
  interaction = function(self)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and card.type == Card.TypeBasic and not card.is_derived and ((Fk.currentResponsePattern == nil and Self:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) and not Self:prohibitUse(card) then
        table.insert(allCardNames, card.name)
      end
    end
    return UI.ComboBox { choices = allCardNames }
  end,
  view_as = function(self, cards)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = self.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:addPlayerMark(player, "@tg__jiancheng-round")
    if #room.draw_pile < 2 then
      room:shuffleDrawPile()
      if #room.draw_pile < 2 then
        room:gameOver("")
      end
    end
    local cids = {room:getNCards(1)[1], room:getNCards(1, "bottom")[1]}
    room:moveCardTo(cids, Card.Processing, nil, fk.ReasonJustMove, self.name)
    room:sendFootnote(cids, {
      type = "##ShowCard",
      from = player.id,
    }) --FIXME，展示牌堆顶牌
    room:delay(1200)
    if Fk:getCardById(cids[1]).color ~= Fk:getCardById(cids[2]).color then
      local dummy = Fk:cloneCard("jink")
      dummy:addSubcards(cids)
      room:obtainCard(player, dummy, true, fk.ReasonPrey)
      room:setPlayerMark(player, "@tg__jiancheng-round", 0)
      room:setPlayerMark(player, "@@tg__jiancheng_invalid-round", 1)
    else
      room:moveCardTo(cids[1], Card.DrawPile, nil, fk.ReasonPut, self.name, nil, false)
      room:moveCardTo(cids[1], Card.DrawPile, nil, fk.ReasonPut, self.name, nil, false)
      local move1 = {
        ids = {cids[2]},
        fromArea = Card.Processing,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = -1,
      }
      local move2 = {
        ids = {cids[1]},
        fromArea = Card.Processing,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      room:moveCards(move1, move2)
      --table.insert(room.draw_pile, cids[2])
      --table.insert(room.draw_pile, 1, cids[1])
      --room:doBroadcastNotify("UpdateDrawPile", #room.draw_pile)
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) < 2 and player:getMark("@@tg__jiancheng_invalid-round") == 0
  end,
  enabled_at_response = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) < 2 and player:getMark("@@tg__jiancheng_invalid-round") == 0
  end,
}
local tg__jiancheng_distance = fk.CreateDistanceSkill{
  name = "#tg__jiancheng_distance",
  correct_func = function(self, from, to)
    if to:getMark("@@tg__jiancheng_invalid-round") ~= 0 and from ~= to then
      return to:getMark("@@tg__jiancheng_invalid-round")
    end
  end,
}
tg__jiancheng:addRelatedSkill(tg__jiancheng_distance)

tg__luoxian:addSkill(tg__jiancheng)

Fk:loadTranslationTable{
  ["tg__luoxian"] = "罗宪", --TG005 不坠的坚壁 插画绘制：B_LEE 技能设计：羌溪散人 称号设计：扬林
  ["tg__jiancheng"] = "坚城",
  [":tg__jiancheng"] = "每轮限两次，当你需要使用/打出一种基本牌时，你可以展示牌堆顶和牌堆底各一张牌，视为使用/打出之，若这两张牌颜色不同，你获得这两张牌，然后本轮内此技能失效且其他角色至你距离+1。",

  ["@tg__jiancheng-round"] = "坚城",
  ["@@tg__jiancheng_invalid-round"] = "坚城 距离+1",
}

local tg__liuyongliuli = General(extension, "tg__liuyongliuli", "shu", 3)

local tg__zunxiu = fk.CreateTriggerSkill{
  name = "tg__zunxiu",
  events = {fk.EventPhaseChanging, fk.CardUsing, fk.CardResponding},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return false end
    if event == fk.CardUsing or event == fk.CardResponding then
      return data.card.type == Card.TypeBasic
    elseif data.to == Player.NotActive then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryTurn)
      return #events > 0 and table.every(events, function(e)
        return e.data[1].card.type == Card.TypeBasic
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryTurn)
      player:drawCards(#events, self.name)
    else
      local room = player.room
      if not room.current.dead then
        player.room:setPlayerMark(room.current, "@tg__zunxiu-turn", data.card.name)
      end
    end
  end,
}
local tg__zunxiu_filter = fk.CreateFilterSkill{
  name = "#tg__zunxiu_filter",
  card_filter = function(self, to_select, player)
    if player:getMark("@tg__zunxiu-turn") == 0 or table.contains(player.player_cards[Player.Equip], to_select.id) or table.contains(player.player_cards[Player.Judge], to_select.id) then return false end
    return to_select.type == Card.TypeBasic
  end,
  view_as = function(self, to_select, player)
    local card = Fk:cloneCard(player:getMark("@tg__zunxiu-turn"), to_select.suit, to_select.number)
    card.skillName = self.name
    return card
  end,
}
tg__zunxiu:addRelatedSkill(tg__zunxiu_filter)

local tg__zhenfan = fk.CreateTriggerSkill{
  name = "tg__zhenfan",
  events = {fk.CardUseFinished},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and target.phase == Player.Play and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player),function(p)
      return not p:prohibitUse(Fk:cloneCard("slash"))
    end), function(p)
      return p.id
    end), 1, 1, "#tg__zhenfan-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("jijiang")
    local target = room:getPlayerById(self.cost_data)
    local use = room:askForUseCard(target, "slash", nil, "#tg__zhenfan-slash:" .. player.id, true, {bypass_times = true})
    if use then
      room:useCard(use)
      room:addPlayerMark(player, "@tg__zhenfan-turn")
    end
  end,
}
local tg__zhenfan_buff = fk.CreateTargetModSkill{
  name = "#tg__zhenfan_buff",
  residue_func = function(self, player, skill, scope)
    if player:getMark("@tg__zhenfan-turn") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@tg__zhenfan-turn")
    end
  end,
}
tg__zhenfan:addRelatedSkill(tg__zhenfan_buff)

tg__liuyongliuli:addSkill(tg__zunxiu)
tg__liuyongliuli:addSkill(tg__zhenfan)

Fk:loadTranslationTable{
  ["tg__liuyongliuli"] = "刘永刘理", --TG008 东藩远室 插画绘制：特异型安妮 技能设计：晓绝对 称号设计：圣帝
  ["tg__zunxiu"] = "遵修",
  [":tg__zunxiu"] = "锁定技，当你使用或打出基本牌时，你令当前回合角色的基本牌直到回合结束均视为此牌；回合结束时，若你本回合只使用过基本牌，你摸X张牌（X为你本回合使用的牌数）。",
  ["tg__zhenfan"] = "振藩",
  [":tg__zhenfan"] = "当你于出牌阶段使用【杀】结算后，你可以令一名其他角色选择是否使用一张【杀】，令你本回合使用【杀】的次数上限+1。",

  ["#tg__zunxiu_filter"] = "遵修",
  ["@tg__zunxiu-turn"] = "遵修",
  ["#tg__zhenfan-ask"] = "振藩：你可令一名其他角色选择是否使用一张【杀】，令你本回合使用【杀】的次数上限+1",
  ["#tg__zhenfan-slash"] = "振藩：你可使用一张【杀】，令 %src 本回合使用【杀】的次数上限+1",
  ["@tg__zhenfan-turn"] = "振藩",
}

local tg__zhuyi = General(extension, "tg__zhuyi", "wu", 4)

local tg__danding = fk.CreateTriggerSkill{
  name = "tg__danding",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) or not data.to or data.to == player then return false end
    return #player:getCardIds{Player.Hand, Player.Equip, Player.Judge} + #data.to:getCardIds{Player.Hand, Player.Equip, Player.Judge} > 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#tg__danding::" .. data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = data.to
    local result = room:askForCustomDialog(player, self.name,
      "packages/tuguo/qml/DandingBox.qml", {
        player.general, player:getCardIds(Player.Hand), player:getCardIds(Player.Equip), player:getCardIds(Player.Judge),
        target.general, target:getCardIds(Player.Hand), target:getCardIds(Player.Equip), target:getCardIds(Player.Judge),
      })
    local cards
    if result == "" then
      local ids1 = table.simpleClone(player:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      local ids2 = table.simpleClone(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      table.insertTable(ids1, ids2)
      cards = table.random(ids1, 2)
    else
      cards = json.decode(result)
    end
    local cards1 = table.filter(cards, function(id) return table.contains(player:getCardIds{Player.Hand, Player.Equip, Player.Judge}, id) end)
    local cards2 = table.filter(cards, function(id) return table.contains(target:getCardIds{Player.Hand, Player.Equip, Player.Judge}, id) end)
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = player.id,
        ids = cards1,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = player.id,
        skillName = self.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = target.id,
        ids = cards2,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = player.id,
        skillName = self.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
    if not target.dead and #cards1 == 0 then
      target:drawCards(1, self.name)
    end
  end,
}

local tg__zhemou = fk.CreateTriggerSkill{
  name = "tg__zhemou",
  events = {fk.EventPhaseChanging},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) < 1 and not (player:prohibitUse(Fk:cloneCard("slash")) and player:prohibitUse(Fk:cloneCard("snatch"))) and data.to == Player.Play and not player.skipped_phases[Player.Discard]
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#tg__zhemou")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:skip(Player.Play)
    player:skip(Player.Discard)
    for _, c in ipairs({"snatch", "slash"}) do
      local card = Fk:cloneCard(c)
      if not player:prohibitUse(card) then
        local availableTargets = table.map(table.filter(room.alive_players, function(p) return p ~= player and not player:isProhibited(p, card) and (c == "slash" or not p:isAllNude()) end), function(p) return p.id end)
        if #availableTargets == 0 then return false end
        local targets = table.map(room:askForChoosePlayers(player, availableTargets, 1, 99, "#tg__zhemou-" .. c, self.name, false), function(pid) return room:getPlayerById(pid) end)
        room:useVirtualCard(c, nil, player, targets, self.name, true)
      end
    end
    return true
  end,
}

tg__zhuyi:addSkill(tg__danding)
tg__zhuyi:addSkill(tg__zhemou)

Fk:loadTranslationTable{
  ["tg__zhuyi"] = "朱异", --TG010 锋坠镬中 插画绘制：恶童 技能设计：紫星居 称号设计：会乱武的袁绍
  ["tg__danding"] = "胆定",
  [":tg__danding"] = "当你对其他角色造成伤害后，你可以弃置你与其区域内共计两张牌，若其中没有你的牌，其摸一张牌。",
  ["tg__zhemou"] = "折谋",
  [":tg__zhemou"] = "限定技，你可以跳过出牌阶段和弃牌阶段，视为依次使用无距离和目标数限制的【顺手牵羊】和【杀】。",

  ["#tg__danding"] = "胆定：你可弃置你与 %dest 区域内共计两张牌，若其中没有你的牌，其摸一张牌",
  ["#danding-choose"] = "胆定：弃置双方共计两张牌",
  ["#tg__zhemou"] = "你可发动“折谋”，跳过出牌阶段和弃牌阶段，视为依次使用无距离和目标数限制的【顺手牵羊】和【杀】",
  ["#tg__zhemou-snatch"] = "折谋：视为使用无距离和目标数限制的【顺手牵羊】",
  ["#tg__zhemou-slash"] = "折谋：视为使用无距离和目标数限制的【杀】",
}

local tg__shiji = General(extension, "tg__shiji", "wu", 4)

local tg__danli = fk.CreateTriggerSkill{
  name = "tg__danli",
  events = {fk.EventPhaseStart},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase < Player.NotActive and player.phase > Player.RoundStart and player:usedSkillTimes(self.name) < player:getLostHp()+1
  end,
  on_cost = function(self, event, target, player, data)
    local phase_name_table = {
      [2] = "phase_start",
      [3] = "phase_judge",
      [4] = "phase_draw",
      [5] = "phase_play",
      [6] = "phase_discard",
      [7] = "phase_finish",
    }
    return player.room:askForSkillInvoke(player, self.name, data, "#tg__danli-ask:::" .. phase_name_table[player.phase])
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    local cid = player.room:askForCardChosen(player, player, "hej", self.name)
    player.room:throwCard({cid}, self.name, player, player)
  end,
}

local tg__bingji = fk.CreateTriggerSkill{
  name = "tg__bingji",
  anim_type = "offensive",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    for _, move in ipairs(data) do
      if move.from and move.from == player.id then
        if not player.dead then
          if #player:getCardIds(Player.Judge) == 0 and table.find(move.moveInfo, function (info)
              return info.fromArea == Card.PlayerJudge end) then
            return true
          end
          if #player:getCardIds(Player.Equip) == 0 and table.find(move.moveInfo, function (info)
              return info.fromArea == Card.PlayerEquip end) then
            return true
          end
          if player.phase == Player.Discard and table.find(move.moveInfo, function (info)
              return Fk:getCardById(info.cardId).type == Card.TypeBasic end) then
            return true
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local events = {}
    for _, move in ipairs(data) do
      if move.from and move.from == player.id then
        if #player:getCardIds(Player.Judge) == 0 and table.find(move.moveInfo, function (info)
            return info.fromArea == Card.PlayerJudge end) then
          table.insert(events, 1)
        end
        if #player:getCardIds(Player.Equip) == 0 and table.find(move.moveInfo, function (info)
            return info.fromArea == Card.PlayerEquip end) then
          table.insert(events, 2)
        end
        if player.phase == Player.Discard and table.find(move.moveInfo, function (info)
            return Fk:getCardById(info.cardId).type == Card.TypeBasic end) then
          table.insert(events, 3)
        end
      end
    end
    local mark = type(player:getMark("_tg__bingji")) == "table" and player:getMark("_tg__bingji") or { {}, {}, {} }
    for _, e in ipairs(events) do
      if not player:hasSkill(self) or player.dead then break end
      if table.find(room.alive_players, function(p) return not table.contains(mark[e], p.id) end) then
        if e == 3 then
          local card = Fk:cloneCard("slash")
          if player:prohibitUse(card) then return false end
          if not table.find(room.alive_players, function(p) return p ~= player and not player:isProhibited(p, card) end) then
            return false
          end
        end
        self:doCost(event, target, player, e)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = type(player:getMark("_tg__bingji")) == "table" and player:getMark("_tg__bingji") or { {}, {}, {} }
    local availableTargets = table.map(table.filter(room.alive_players, function(p) return not table.contains(mark[data], p.id) end), function(p) return p.id end)
    if #availableTargets == 0 then return false end
    if data == 3 then
      local card = Fk:cloneCard("slash")
      if player:prohibitUse(card) then return false end
      availableTargets = table.filter(availableTargets, function(pid) return pid ~= player.id and not player:isProhibited(room:getPlayerById(pid), card) end)
      if #availableTargets == 0 then return false end
    end
    local targets = room:askForChoosePlayers(player, availableTargets, 1, 1, "#tg__bingji_" .. tostring(data), self.name, true)
    if #targets > 0 then
      self.cost_data = targets[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = type(player:getMark("_tg__bingji")) == "table" and player:getMark("_tg__bingji") or { {}, {}, {} }
    local target = self.cost_data
    table.insert(mark[data], target)
    room:setPlayerMark(player, "_tg__bingji", mark)
    if data == 3 then
      local slash = Fk:cloneCard("slash")
      slash.skillName = self.name
      local use = {
        from = player.id,
        tos = { {target} },
        card = slash,
      }
      room:useCard(use)
    elseif data == 1 then
      room:damage{
        from = player,
        to = room:getPlayerById(target),
        damage = 1,
        skillName = self.name,
      }
    else
      local cids = room:getCardsFromPileByRule("slash,duel,analeptic")
      if #cids > 0 then
        room:setCardMark(Fk:getCardById(cids[1]), "@@tg__bingji-inhand", 1)
        room:obtainCard(target, cids[1], false, fk.ReasonPrey)
      end
    end
  end,
}
local tg__bingji_maxcards = fk.CreateMaxCardsSkill{
  name = "#tg__bingji_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@tg__bingji-inhand") > 0
  end,
}
tg__bingji:addRelatedSkill(tg__bingji_maxcards)

tg__shiji:addSkill(tg__danli)
tg__shiji:addSkill(tg__bingji)

Fk:loadTranslationTable{
  ["tg__shiji"] = "施绩", --TG011 戍国之垒 插画绘制：蒋斯成 技能设计：竹沐雨 称号设计：恶童
  ["tg__danli"] = "胆力",
  [":tg__danli"] = "每回合限X次（X为你已损失的体力值+1），你的每个阶段开始时，你可以摸一张牌并弃置区域内的一张牌。",
  ["tg__bingji"] = "并击",
  [":tg__bingji"] = "每项对每名角色限一次：1. 当你失去判定区内的最后一张牌后，你可以对一名角色造成1点伤害；2. 当你失去装备区内的最后一张牌后，你可以令一名角色从牌堆获得一张不计入手牌上限的【杀】、【决斗】或【酒】；3. 当你于弃牌阶段失去基本牌后，你可以视为对一名角色使用一张【杀】。",--2. ……，你可以令一名角色的所有图国牌视为【武备·临锋决敌】直到你下回合开始

  ["#tg__danli-ask"] = "胆力：此时为 %arg 开始时，你可摸一张牌并弃置区域内的一张牌",
  ["#tg__bingji_3"] = "并击：你可视为对一名角色使用一张【杀】",
  ["#tg__bingji_1"] = "并击：你可对一名角色造成1点伤害",
  ["#tg__bingji_2"] = "并击：你可令一名角色从牌堆获得一张【杀】、【决斗】或【酒】",
  ["@@tg__bingji-inhand"] = "并击",
}

local tg__sunjiao = General(extension, "tg__sunjiao", "wu", 4)

local tg__jueyu = fk.CreateTriggerSkill{
  name = "tg__jueyu",
  events = {fk.EventPhaseStart},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and table.find(player.room.alive_players, function(p) return not player:inMyAttackRange(p) and p ~= player and not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#tg__jueyu-ask")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 999
    for _, p in ipairs(room.alive_players) do
      if not player:inMyAttackRange(p) and p ~= player then
        num = num > player:distanceTo(p) and player:distanceTo(p) or num
      end
    end
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not player:inMyAttackRange(p) and p ~= player and player:distanceTo(p) == num and not p:isNude()
    end), function(p)
      return p.id
    end)
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not player.dead and not p.dead then
        local id = room:askForCardChosen(player, p, "he", self.name)
        room:obtainCard(player, id)
        room:setPlayerMark(p, "@@tg__jueyu-phase", 1)
      end
    end
  end,
}
local tg__jueyu_pay = fk.CreateTriggerSkill{
  name = "#tg__jueyu_pay",
  anim_type = "negative",
  events = {fk.EventPhaseEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player == target and player:usedSkillTimes(tg__jueyu.name, Player.HistoryPhase) > 0 and not player:isNude() then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryTurn)
      local targets = {}
      if #events > 0 then
        table.forEach(events, function(e)
          table.forEach(e.data[1].tos, function(pids)
            table.insertIfNeed(targets, pids[1])
          end)
        end)
      end
      return table.find(player.room.alive_players, function(p)
        return p:getMark("@@tg__jueyu-phase") > 0 and not table.contains(targets, p.id)
      end)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local events = room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
    local use = e.data[1]
    return use.from == player.id
    end, Player.HistoryTurn)
    local targets = {}
    if #events > 0 then
      table.forEach(events, function(e)
        table.forEach(e.data[1].tos, function(pids)
          table.insertIfNeed(targets, pids[1])
        end)
      end)
    end
    targets = table.map(table.filter(room.alive_players, function(p)
      return p:getMark("@@tg__jueyu-phase") > 0 and not table.contains(targets, p.id)
    end), function(p) 
      return p.id
    end)
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local target = room:getPlayerById(pid)
      if not player.dead and not target.dead then
        local c = room:askForCard(player, 1, 1, true, self.name, false, "", "#tg__jueyu_pay-card::" .. target.id)[1]
        room:moveCardTo(c, Player.Hand, target, fk.ReasonGive, self.name, nil, false)
      end
    end
  end
}
tg__jueyu:addRelatedSkill(tg__jueyu_pay)

local tg__shuaikai_select = fk.CreateActiveSkill{
  name = "#tg__shuaikai_select",
  can_use = function() return false end,
  target_num = 0,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local card = Fk:getCardById(to_select)
      if card.type == Card.TypeEquip then
        return not table.contains({Card.SubtypeWeapon, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide}, card.sub_type) or not Self:prohibitDiscard(card)
      end
    end
  end,
}
local tg__shuangkai = fk.CreateTriggerSkill{
  name = "tg__shuangkai",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and data.to == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    local card
    local _, ret = player.room:askForUseActiveSkill(player, "#tg__shuaikai_select", "#tg__shuangkai-select", true)
    if ret then
      card = Fk:getCardById(ret.cards[1])
    end
    if card then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = self.cost_data
    local num
    if card.sub_type == Card.SubtypeWeapon then
      num = card.attack_range
    elseif card.sub_type == Card.SubtypeDefensiveRide then
      num = 1
    elseif card.sub_type == Card.SubtypeOffensiveRide then
      num = 1
    end
    if num then
      room:throwCard(card.id, self.name, player, player)
      local targets = table.map(table.filter(room.alive_players, function(p) return player:inMyAttackRange(p) end), function (p) return p.id end)
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, targets, 1, num, "#tg__shuangkai-choose:::"..num, self.name, false)
      room:sortPlayersByAction(tos)
      for _, pid in ipairs(tos) do
        local p = room:getPlayerById(pid)
        if not p.dead then p:drawCards(1, self.name) end
      end
    else
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p) return p.id end), 1, 1, "#tg__shuangkai-give:::" .. card:toLogString(), self.name, false)[1]
      room:moveCardTo(card.id, Player.Hand, room:getPlayerById(to), fk.ReasonGive, self.name, nil, true)
    end
  end,
}
tg__shuangkai:addRelatedSkill(tg__shuaikai_select)

tg__sunjiao:addSkill(tg__jueyu)
tg__sunjiao:addSkill(tg__shuangkai)

Fk:loadTranslationTable{
  ["tg__sunjiao"] = "孙皎", -- TG012 柔远周迩 插画绘制：大佬荣&Aimer彩三 技能设计&称号设计：会乱武的袁绍
  ["tg__jueyu"] = "攫誉",
  [":tg__jueyu"] = "出牌阶段开始时，你可以获得攻击范围外距离最近的其他角色各一张牌，然后此阶段结束时，你交给其中此阶段未成为过你牌目标的角色各一张牌。",
  ["tg__shuangkai"] = "爽慨",
  [":tg__shuangkai"] = "回合结束时，你可以弃置一张装备牌并选择牌面上一个数字，令攻击范围内至多等量的角色各摸一张牌；若没有数字，则改为将此牌交给一名其他角色。<br/><font color='grey'>#\"<b>牌面上一个数字</b>\"包括（武器的）攻击范围、（坐骑的）距离，不包括点数。</font>", --以及技能描述中的数字？！（如【藤甲】“伤害+1”的“1”，【八卦阵】“一张闪”的“1”，但是规则集中就不用“一张”啊……）
  ["#tg__jueyu-ask"] = "攫誉：你可以获得攻击范围外距离最近的其他角色各一张牌，然后此阶段结束时，你交给其中此阶段未成为过你牌目标的角色各一张牌",
  ["@@tg__jueyu-phase"] = "攫誉",
  ["#tg__jueyu_pay-card"] = "攫誉：交给 %dest 一张牌",
  ["#tg__jueyu_pay"] = "攫誉",
  ["#tg__shuaikai_select"] = "爽慨",
  ["#tg__shuangkai-select"] = "爽慨：你可弃置一张装备牌并选择牌面上一个数字，令攻击范围内至多等量角色各摸一张牌；若没有数字，则改为交给一名其他角色",
  ["#tg__shuangkai-choose"] = "爽慨：选择攻击范围内至多 %arg 名角色，各摸一张牌",
  ["#tg__shuangkai-give"] = "爽慨：选择一名其他角色，将 %arg 交给其",
}

local tg__yangfenghanxian = General(extension, "tg__yangfenghanxian", "qun", 4, 5)

local tg__langbu = fk.CreateTriggerSkill{
  name = "tg__langbu",
  events = {fk.BeforeDrawCard},
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local card = Fk:cloneCard("avoiding_disadvantages")
      return not player:prohibitUse(card) and not player:isProhibited(player, card)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    room:notifySkillInvoked(player, self.name, player:getMark("@tg__langbu-round") < 3 and "drawcard" or "negative")
    room:useVirtualCard("avoiding_disadvantages", nil, player, player, self.name) --摆
    if not player.dead then room:addPlayerMark(player, "@tg__langbu-round") end
  end,
}

local tg__siye = fk.CreateTriggerSkill{
  name = "tg__siye",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    return target.role == "lord" and data.card and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    return player:getMark("@@tg__siye-round") > 0 or player.room:askForSkillInvoke(player, self.name, data, "#tg__siye:::" .. math.min(player:getMark("@tg__langbu-round"), 3) + 1)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.min(player:getMark("@tg__langbu-round"), 3) + 1, self.name)
    if not player.dead then player.room:setPlayerMark(player, "@@tg__siye-round", 1) end
  end,
}

tg__yangfenghanxian:addSkill(tg__langbu)
tg__yangfenghanxian:addSkill(tg__siye)

Fk:loadTranslationTable{
  ["tg__yangfenghanxian"] = "杨奉韩暹", --TG013 构辰鸱张 插画绘制：Aimer彩三 技能设计&称号设计：会乱武的袁绍
  ["tg__langbu"] = "狼逋",
  [":tg__langbu"] = "锁定技，当你摸牌时，你视为使用一张【违害就利】；你使用【违害就利】观看牌数-X（X为本轮〖狼逋〗已发动次数且至多为3），若已减至0，此牌的效果改为令你失去1点体力或减1点体力上限。<br/><font color='grey'>【<b>违害就利</b>】锦囊牌 你从牌堆摸牌或进行判定时，对你使用。目标角色观看牌堆顶的三张牌，然后将其中任意张牌置于弃牌堆。",
  ["tg__siye"] = "肆野",
  [":tg__siye"] = "当主公受到【杀】的伤害后，你可以摸X+1张牌（X为本轮〖狼逋〗发动过的次数且至多为3），然后本轮你必须发动此技能。",

  ["@tg__langbu-round"] = "狼逋",
  ["#tg__siye"] = "你可发动“肆野”，摸 %arg 张牌，然后本轮你必须发动此技能",
  ["@@tg__siye-round"] = "肆野 必须发动",
}

local tg__dengzhong = General(extension, "tg__dengzhong", "wei", 4)

local tg__xiannan = fk.CreateTriggerSkill{
  name = "tg__xiannan",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local num = 0
    local ret = true
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      if num >= 1 then ret = false end
      if num >= player.maxHp then
        ret = false
        return true
      end
      for _, move in ipairs(e.data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              num = num + 1
              if num >= player.maxHp then ret = true end
            end
          end
        end
      end
    end, Player.HistoryRound)
    return (num >= 1 or num >= player.maxHp) and ret
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    player.room:addPlayerMark(player, "@tg__xiannian-turn", 1)
  end,
}
local tg__xiannan_trig = fk.CreateTriggerSkill{
  name = "#tg__xiannan_trig",
  events = {fk.DamageInflicted, fk.DamageCaused},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@tg__xiannian-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "tg__xiannan", event == fk.DamageCaused and "offensive" or "negative")
    data.damage = data.damage + player:getMark("@tg__xiannian-turn")
    room:setPlayerMark(player, "@tg__xiannian-turn", 0)
  end,
}
tg__xiannan:addRelatedSkill(tg__xiannan_trig)

local tg__shuanggu = fk.CreateTriggerSkill{
  name = "tg__shuanggu",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:inMyAttackRange(target) and data.damage >= target.hp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#tg__shuanggu-ask::" .. target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not (player.dead or target.dead) then
      room:setPlayerMark(player, "@@tg__shuanggu-turn", 1)
      room:setPlayerMark(target, "@@tg__shuanggu-turn", 1)
    end
  end,
}
local tg__shuanggu_trig = fk.CreateTriggerSkill{
  name = "#tg__shuanggu_trig",
  events = {fk.DamageInflicted},
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@tg__shuanggu-turn") > 0
  end,
  on_use = Util.TrueFunc,
}
tg__shuanggu:addRelatedSkill(tg__shuanggu_trig)

tg__dengzhong:addSkill(tg__xiannan)
tg__dengzhong:addSkill(tg__shuanggu)

Fk:loadTranslationTable{
  ["tg__dengzhong"] = "邓忠", -- TG018 蹈覆奋旋 插画绘制：恶童 技能设计：紫髯的小乔 称号设计：？
  ["tg__xiannan"] = "陷难",
  [":tg__xiannan"] = "当你于一轮内失去第一张牌或第X张牌后（X为你的体力上限），你可摸一张牌，令你于此回合下一次造成或受到的伤害+1。",
  ["tg__shuanggu"] = "霜骨",
  [":tg__shuanggu"] = "当你攻击范围内的角色受到致命伤害时，你可减1点体力上限，此回合防止你与其受到的伤害。",

  ["@tg__xiannian-turn"] = "陷难 加伤",
  ["#tg__xiannan_trig"] = "陷难",
  ["#tg__shuanggu-ask"] = "霜骨：你可减1点体力上限，防止本回合你与 %dest 受到的伤害",
  ["@@tg__shuanggu-turn"] = "霜骨 防伤",
  ["#tg__shuanggu_trig"] = "霜骨",
}

local tg__shixie = General(extension, "tg__shixie", "qun", 3)

local tg__jueyuk = fk.CreateDistanceSkill{
  name = "tg__jueyuk",
  correct_func = function(self, from, to)
    if to:hasSkill(self) and from:getHandcardNum() > to:getHandcardNum() then
      return 1
    end
  end,
}

local tg__bode = fk.CreateActiveSkill{
  name = "tg__bode",
  anim_type = "drawcard",
  can_use = function (self, player, card)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = function() return false end,
  on_use = function (self, room, effect)
    local player = room:getPlayerById(effect.from)
    local num = #table.filter(room.alive_players, function(p) return not p:inMyAttackRange(player) end)
    if num == 0 then return false end
    local cids = room:getNCards(num)
    room:moveCardTo(cids, Card.Processing, nil, fk.ReasonJustMove, self.name)
    room:delay(2000)
    local targets = table.map(table.filter(room.alive_players, function(p) return not player:inMyAttackRange(p) and p ~= player end), function(p) return p.id end)
    if #targets > 0 then
      local cards = table.filter(cids, function(id) return Fk:getCardById(id).type == Card.TypeTrick end)
      if #cards > 0 then
        local target = room:askForChoosePlayers(player, targets, 1, 1, "#tg__bode-ask", self.name, false)[1]
        room:moveCardTo(cards, Player.Hand, room:getPlayerById(target), fk.ReasonGive, self.name, nil, false)
        table.forEach(cards, function(id) table.removeOne(cids, id) end)
      end
    end
    local dummy = Fk:cloneCard("jink")
    dummy:addSubcards(cids)
    room:obtainCard(player, dummy, true, fk.ReasonPrey)
  end
}

tg__shixie:addSkill(tg__jueyuk)
tg__shixie:addSkill(tg__bode)

Fk:loadTranslationTable{
  ["tg__shixie"] = "士燮", --TG019 百越归仁 插画绘制：彩三&特异型安妮 技能设计：羌溪散人 称号设计：？
  ["tg__jueyuk"] = "绝域",
  [":tg__jueyuk"] = "锁定技，手牌多于你的角色至你距离+1。",
  ["tg__bode"] = "播德",
  [":tg__bode"] = "出牌阶段限一次，你可以展示牌堆顶的X张牌（X为攻击范围内没有你的角色数），你将其中的锦囊牌交给一名攻击范围外的其他角色，获得未交出的牌。",

  ["#tg__bode-ask"] = "播德：将其中的锦囊牌交给一名攻击范围外的其他角色，你获得其余牌",
}

local tg__sihan = General(extension, "tg__sihan", "wei", 4)

local tg__tongzhen = fk.CreateTriggerSkill{
  name = "tg__tongzhen",
  anim_type = "offensive",
  events = {fk.AfterCardsMove, fk.AfterDying, fk.Death, fk.Deathed, fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name, false, true) or player:prohibitUse(Fk:cloneCard("slash")) then return false end
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
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
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("slash")
    local availableTargets = table.map(table.filter(room.alive_players, function(p) return p ~= player and not player:isProhibited(p, card) end), function(p) return p.id end)
    if #availableTargets == 0 then return false end
    local mark = type(player:getMark("@tg__tongzhen")) == "table" and player:getMark("@tg__tongzhen") or {}
    local mark_name = {[fk.AfterCardsMove] = "tg__losehandcard", [fk.AfterDying] = "tg__afterdying", [fk.Deathed] = "tg__lonearmy", [fk.Death] = "tg__die", [fk.GameStart] = "tg__lonearmy"}
    table.insertIfNeed(mark, mark_name[event])
    local targets = room:askForChoosePlayers(player, availableTargets, 1, 99, "#tg__tongzhen-choose:::" .. #mark, self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Deathed or event == fk.GameStart then
      room:setPlayerMark(player, "_tg__tongzhen_lonearmy", 1)
    end
    local mark = type(player:getMark("@tg__tongzhen")) == "table" and player:getMark("@tg__tongzhen") or {}
    local mark_name = {[fk.AfterCardsMove] = "tg__losehandcard", [fk.AfterDying] = "tg__afterdying", [fk.Deathed] = "tg__lonearmy", [fk.Death] = "tg__die", [fk.GameStart] = "tg__lonearmy"}
    table.insertIfNeed(mark, mark_name[event])
    room:setPlayerMark(player, "@tg__tongzhen", mark)
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    local use = {
      from = player.id,
      tos = table.map(self.cost_data, function(pid) return {pid} end),
      card = slash,
      additionalDamage = #mark - 1,
      extraUse = true,
    }
    room:useCard(use)
  end,
}

tg__sihan:addSkill(tg__tongzhen)

Fk:loadTranslationTable{ --tg__hanyinghanyaohanqionghanqi!
  ["tg__sihan"] = "韩伵", --TG021 厉鬣衅龙 插画绘制：恶童 技能设计：突然消失 称号设计：？
  ["tg__tongzhen"] = "恸阵",
  [":tg__tongzhen"] = "当你{失去最后的手牌/脱离濒死/所属阵营变为仅剩一人/死亡}后，你可以视为使用一张无距离、次数和目标数限制的【杀】，此【杀】的伤害值基数为你触发过的〖恸阵〗条件数。<font color='grey'>其实叫“<b>韩瑛&韩瑶&韩琼&韩琪</b>”，名字太长……“伵”xù（@韩旭）",

  ["#tg__tongzhen-choose"] = "恸阵：你可视为使用一张无距离、次数和目标数限制的【杀】，此【杀】的伤害值基数为 %arg",
  ["@tg__tongzhen"] = "恸阵",
  ["tg__losehandcard"] = "失",
  ["tg__afterdying"] = "脱",
  ["tg__lonearmy"] = "孤",
  ["tg__die"] = "死",
}

local tg__caojie = General(extension, "tg__caojie", "qun", 3, 3, General.Female)

local tg__weixi = fk.CreateTriggerSkill{
  name = "tg__weixi",
  events = {fk.Damaged},
  frequency = Skill.Limited,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) < 1 and (data.extra_data or {}).weixicheak and target ~= player and table.find(player.room.alive_players, function(p) return p.hp >= target.hp and p ~= target end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#tg__weixi::" .. target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target:drawCards(1, self.name)
    if not player.dead then
      player:drawCards(1, self.name)
      room:setPlayerMark(player, "_tg__weixi", target.id)
      room:setPlayerMark(player, "@tg__weixi", target.general)
    end
  end,

  refresh_events = {fk.BeforeHpChanged},
  can_refresh = function(self, event, target, player, data)
    if data.damageEvent and table.every(target.room.alive_players, function(p) return target.hp > p.hp or target == p end) then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageEvent.extra_data = data.damageEvent.extra_data or {}
    data.damageEvent.extra_data.weixicheak = true
  end,
}
local tg__weixi_draw = fk.CreateTriggerSkill{
  name = "#tg__weixi_draw",
  events = {fk.EventPhaseEnd},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Draw and player:getMark("_tg__weixi") ~= 0 and (target == player or player:getMark("_tg__weixi") == target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {player.id, player:getMark("_tg__weixi")}
    room:doIndicate(targets[1], {targets[2]})
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not p.dead then p:drawCards(1, self.name) end
    end
  end,
}
tg__weixi:addRelatedSkill(tg__weixi_draw)

local tg__xuanhu = fk.CreateTriggerSkill{
  name = "tg__xuanhu",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonDiscard and move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(player, table.map(room.alive_players, function(p)
        return p.id
      end), 1, 1, "#tg__xuanhu-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local p = room:getPlayerById(self.cost_data)
    local availableTargets = table.map(room.alive_players, function(p)
      return p.id
    end)
    while true do
      table.removeOne(availableTargets, p.id)
      local choices = {"tg__xuanhu_draw:" .. p.id}
      if p:isWounded() then table.insert(choices, 1, "tg__xuanhu_recover:" .. p.id) end
      local choice = room:askForChoice(player, choices, self.name)
      if choice:startsWith("tg__xuanhu_draw") then
        p:drawCards(1, self.name)
      else
        room:recover({
          who = p,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
      if p.hp ~= p:getHandcardNum() or player.dead or #availableTargets == 0 then
        break
      else
        local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#tg__xuanhu-ask", self.name, true) 
        if #target > 0 then
          p = room:getPlayerById(target[1])
        else
          break
        end
      end
    end
  end,
}

tg__caojie:addSkill(tg__weixi)
tg__caojie:addSkill(tg__xuanhu)

Fk:loadTranslationTable{
  ["tg__caojie"] = "曹节", --TG022 瑕玮终璧 插画绘制：特异型安妮 技能设计：紫髯的小乔 称号设计：？
  ["tg__weixi"] = "遗玺",
  [":tg__weixi"] = "限定技，当其他角色受到伤害后，若其因此不再是体力值唯一最大的角色，你可以与其各摸一张牌，然后本局游戏你与其摸牌阶段结束时，你与其各摸一张牌。",
  ["tg__xuanhu"] = "悬壶",
  [":tg__xuanhu"] = "当你因弃置而失去牌后，你可以令一名角色回复1点体力或摸一张牌，然后若其手牌数等于体力值，你可以对不同角色重复此流程。",

  ["#tg__weixi"] = "遗玺：你可与 %dest 各摸一张牌，然后本局游戏你与其摸牌阶段结束时，你与其各摸一张牌",
  ["@tg__weixi"] = "遗玺",
  ["#tg__weixi_draw"] = "遗玺",
  ["#tg__xuanhu-ask"] = "悬壶：你可令一名角色回复1点体力或摸一张牌，然后若其手牌数等于体力值，你可以对不同角色重复此流程",
  ["tg__xuanhu_recover"] = "令%src回复1点体力",
  ["tg__xuanhu_draw"] = "令%src摸一张牌",
}

return extension
