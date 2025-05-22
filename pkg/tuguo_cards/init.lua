-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("tuguo_cards", Package.CardPack)
extension.extensionName = "tuguo"

extension:loadSkillSkelsByPath("./packages/tuguo/pkg/tuguo_cards/skills")

Fk:loadTranslationTable{
  ["tuguo_cards"] = "图国篇卡牌",
}

local avoiding_disadvantages = fk.CreateCard{
  name = "&avoiding_disadvantages",
  type = Card.TypeTrick,
  skill = "avoiding_disadvantages_skill",
  is_passive = true,
}
extension:addCardSpec("avoiding_disadvantages", Card.Spade, 12)
extension:addCardSpec("avoiding_disadvantages", Card.Diamond, 1)
Fk:loadTranslationTable{
  ["avoiding_disadvantages"] = "违害就利",
  [":avoiding_disadvantages"] = "锦囊牌<br/>"..
  "<b>时机</b>：当你摸牌或进行判定时<br/>"..
  "<b>目标</b>：你<br/>"..
  "<b>效果</b>：目标角色观看牌堆顶三张牌，然后将其中任意张牌置于弃牌堆。",

  ["avoiding_disadvantages_skill"] = "违害就利",
  ["#avoiding_disadvantages_skill"] = "观看牌堆顶三张牌，将其中任意张牌置于弃牌堆",
}

local defeating_the_double = fk.CreateCard{
  name = "&defeating_the_double",
  type = Card.TypeTrick,
  skill = "defeating_the_double_skill",
  is_damage_card = true,
}
extension:addCardSpec("defeating_the_double", Card.Club, 3)
extension:addCardSpec("defeating_the_double", Card.Diamond, 9)
Fk:loadTranslationTable{
  ["defeating_the_double"] = "以半击倍",
  [":defeating_the_double"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：你<br/>"..
  "<b>效果</b>：目标角色摸一张牌，然后弃置任意张手牌并选择一名手牌数为弃置牌数两倍的角色，对其造成1点伤害。"..
  "<br/><font color='grey' size = 2>八百虎贲踏江去，十万吴兵丧胆还！",

  ["defeating_the_double_skill"] = "以半击倍",
  ["#defeating_the_double_skill"] = "摸一张牌，然后弃置任意张手牌，对一名手牌数为弃牌数两倍的角色造成伤害",
}

extension:loadCardSkels {
  avoiding_disadvantages,
  defeating_the_double,
}

return extension
