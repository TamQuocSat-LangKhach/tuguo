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
    room:broadcastSkillInvoke("ty__kaiji")
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
    return target == player and player:hasSkill(self.name) and data.from and data.from:getHandcardNum() > player:getHandcardNum() and #data.from:getCardIds{Player.Hand, Player.Equip} > 1
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

Fk:loadTranslationTable{
  ["tg__xuzhi"] = "徐质", --TG002 覆天穷斗 插画绘制：Aimer彩三 技能设计：竹沐雨 称号设计：雪侯
  ["tg__fenwei"] = "奋围",
	[":tg__fenwei"] = "每回合限一次，其他角色使用【闪】或本回合第二张同名牌结算后，若没有角色处于濒死状态，你可以翻面，视为对其使用一张【决斗】或【杀】（有距离限制）。",
	["tg__yanfa"] = "掩伐",
	[":tg__yanfa"] = "每回合对每名角色限一次，当你对其他角色造成伤害后，你可以视为对其使用一张【杀】。若如此做，该角色可以弃置所有装备区的牌或所有手牌，然后令此【杀】无效，你获得其中点数最大的牌并翻面。",
}

local tg__dailing = General(extension, "tg__dailing", "wei", 4)

local tg__zhoubing = fk.CreateTriggerSkill{
  name = "tg__zhoubing",
  anim_type = "offensive",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.to == Player.NotActive and target ~= player and target.skipped_phases and not player:prohibitUse(Fk:cloneCard("slash"))
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
    return player:hasSkill(self.name) and target.phase == Player.Start and player ~= target and target.hp >= player.hp and not player:isKongcheng() and not target:isKongcheng()
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

local tg__liuyongliuli = General(extension, "tg__liuyongliuli", "shu", 3)

local tg__zunxiu = fk.CreateTriggerSkill{
  name = "tg__zunxiu",
  events = {fk.EventPhaseChanging, fk.CardUsing, fk.CardResponding},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self.name) then return false end
    if event == fk.CardUsing or event == fk.CardResponding then
      return data.card.type == Card.TypeBasic
    elseif data.to == Player.NotActive then
      local filterdEvents = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryTurn)
      return #filterdEvents > 0 and table.every(filterdEvents, function(e)
        return e.data[1].card.type == Card.TypeBasic
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      local filterdEvents = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryTurn)
      player:drawCards(#filterdEvents, self.name)
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
    return player == target and player:hasSkill(self.name) and target.phase == Player.Play and data.card.trueName == "slash"
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
    room:broadcastSkillInvoke("jijiang")
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
  ["tg__liuyongliuli"] = "刘永刘理", --TG 008 东藩远室 插画绘制：特异型安妮 技能设计：晓绝对 称号设计：圣帝
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
    if target ~= player or not player:hasSkill(self.name) or not data.to or data.to == player then return false end
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
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) < 1 and not (player:prohibitUse(Fk:cloneCard("slash")) and player:prohibitUse(Fk:cloneCard("snatch"))) and data.to == Player.Play and not player.skipped_phases[Player.Discard]
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
  ["tg__zhuyi"] = "朱异", --TG 010 锋坠镬中 插画绘制：恶童 技能设计：紫星居 称号设计：会乱武的袁绍
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

local tg__sunjiao = General(extension, "tg__sunjiao", "wu", 4)

local tg__jueyu = fk.CreateTriggerSkill{
  name = "tg__jueyu",
  events = {fk.EventPhaseStart},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and table.find(player.room.alive_players, function(p) return not player:inMyAttackRange(p) and p ~= player and not p:isNude() end)
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
      local filterdEvents = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryTurn)
      local targets = {}
      if #filterdEvents > 0 then
        table.forEach(filterdEvents, function(e)
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
    local filterdEvents = room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
    local use = e.data[1]
    return use.from == player.id
    end, Player.HistoryTurn)
    local targets = {}
    if #filterdEvents > 0 then
      table.forEach(filterdEvents, function(e)
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
    return player:hasSkill(self.name) and target == player and data.to == Player.NotActive
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
    if target == player and player:hasSkill(self.name) then
      local card = Fk:cloneCard("avoiding_disadvantages")
      return not player:prohibitUse(card) and not player:isProhibited(player, card)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke(self.name)
    room:notifySkillInvoked(player, self.name, player:getMark("@tg__langbu-round") < 3 and "drawcard" or "negative")
    room:useVirtualCard("avoiding_disadvantages", nil, player, player, self.name) --摆
    if not player.dead then room:addPlayerMark(player, "@tg__langbu-round") end
  end,
}

local tg__siye = fk.CreateTriggerSkill{
  name = "tg__siye",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
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
  [":tg__langbu"] = "锁定技，当你摸牌时，你视为使用一张【违害就利】；你使用【违害就利】观看牌数-X（X为本轮〖狼逋〗已发动次数且至多为3），若已减至0，此牌的效果改为令你失去1点体力或减1点体力上限。<br/><font color='grey'>【违害就利】你从牌堆摸牌或进行判定时，对你使用。目标角色观看牌堆顶的三张牌，然后将其中任意张牌置于弃牌堆。",
  ["tg__siye"] = "肆野",
  [":tg__siye"] = "当主公受到【杀】的伤害后，你可以摸X+1张牌（X为本轮〖狼逋〗发动过的次数且至多为3），然后本轮你必须发动此技能。",

  ["@tg__langbu-round"] = "狼逋",
  ["#tg__siye"] = "你可发动“肆野”，摸 %arg 张牌，然后本轮你必须发动此技能",
  ["@@tg__siye-round"] = "肆野 必须发动",
}

local tg__caojie = General(extension, "tg__caojie", "qun", 3, 3, General.Female)

local tg__weixi = fk.CreateTriggerSkill{
  name = "tg__weixi",
  events = {fk.Damaged},
  frequency = Skill.Limited,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) < 1 and (data.extra_data or {}).weixicheak and target ~= player and table.find(player.room.alive_players, function(p) return p.hp >= target.hp and p ~= target end)
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
    return player:hasSkill(self.name) and target.phase == Player.Draw and player:getMark("_tg__weixi") ~= 0 and (target == player or player:getMark("_tg__weixi") == target.id)
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
    if not player:hasSkill(self.name) then return false end
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
  ["tg__caojie"] = "曹节", --TG 022 瑕玮终璧 插画绘制：特异型安妮 技能设计：紫髯的小乔 称号设计：？
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
